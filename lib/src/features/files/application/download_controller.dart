import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/file_download_service.dart';
import '../domain/entities/download_task.dart';
import '../domain/entities/file_source.dart';
import '../domain/entities/local_file_entry.dart';
import 'file_manager_controller.dart';

const _downloadBoxName = 'download_tasks_box';
const _downloadKey = 'download_history';

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, List<DownloadTask>>(
  (ref) => DownloadController(ref)..loadFromCache(),
);

class DownloadController extends StateNotifier<List<DownloadTask>> {
  DownloadController(this._ref) : super(const []);

  final Ref _ref;

  Future<void> loadFromCache() async {
    final box = await Hive.openBox<String>(_downloadBoxName);
    final raw = box.get(_downloadKey);
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(DownloadTask.fromJson)
          .toList();
      state = decoded;
    } catch (_) {}
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<String>(_downloadBoxName);
    final encoded =
        jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await box.put(_downloadKey, encoded);
  }

  /// Start a new download.
  /// On web: delegates to browser's native download.
  /// On mobile: streaming download with progress tracking.
  Future<void> startDownload({
    required String url,
    required String suggestedFileName,
    required String mimeType,
    int contentLength = -1,
  }) async {
    if (kIsWeb) {
      final service = _ref.read(fileDownloadServiceProvider);
      await service.launchDownloadInBrowser(url);
      return;
    }

    final taskId = const Uuid().v4();
    final task = DownloadTask(
      id: taskId,
      url: url,
      fileName: suggestedFileName,
      mimeType: mimeType,
      totalBytes: contentLength,
      status: DownloadStatus.downloading,
    );

    state = [...state, task];
    _persist();

    try {
      final service = _ref.read(fileDownloadServiceProvider);
      final savedPath = await service.downloadFile(
        url: url,
        fileName: suggestedFileName,
        onProgress: (received, total) {
          _updateTask(
            taskId,
            (t) => t.copyWith(
              receivedBytes: received,
              totalBytes: total > 0 ? total : t.totalBytes,
              status: DownloadStatus.downloading,
            ),
          );
        },
      );

      // Mark as completed.
      final completedTask = state.firstWhere((t) => t.id == taskId);
      _updateTask(
        taskId,
        (t) => t.copyWith(
          status: DownloadStatus.completed,
          savedPath: savedPath,
          receivedBytes:
              t.totalBytes > 0 ? t.totalBytes : completedTask.receivedBytes,
        ),
      );

      // Register with file manager.
      final fileEntry = LocalFileEntry(
        id: taskId,
        path: savedPath,
        name: suggestedFileName,
        sizeBytes: completedTask.receivedBytes,
        mimeType: mimeType,
        source: FileSource.downloaded,
        sourceUrl: url,
      );
      _ref.read(fileManagerProvider.notifier).addFileEntry(fileEntry);
    } catch (e) {
      _updateTask(
        taskId,
        (t) => t.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }

    await _persist();
  }

  void cancelDownload(String taskId) {
    _updateTask(
      taskId,
      (t) => t.copyWith(status: DownloadStatus.cancelled),
    );
    _persist();
  }

  Future<void> retryDownload(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    removeTask(taskId);
    await startDownload(
      url: task.url,
      suggestedFileName: task.fileName,
      mimeType: task.mimeType,
      contentLength: task.totalBytes,
    );
  }

  void removeTask(String taskId) {
    state = state.where((t) => t.id != taskId).toList();
    _persist();
  }

  void clearHistory() {
    state = state.where((t) => t.isActive).toList();
    _persist();
  }

  void _updateTask(String taskId, DownloadTask Function(DownloadTask) updater) {
    state = [
      for (final t in state)
        if (t.id == taskId) updater(t) else t,
    ];
  }
}
