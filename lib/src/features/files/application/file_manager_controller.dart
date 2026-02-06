import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../data/file_opener_service.dart';
import '../domain/entities/file_source.dart';
import '../domain/entities/local_file_entry.dart';

const _filesBoxName = 'downloaded_files_box';
const _filesKey = 'files';

final fileManagerProvider =
    StateNotifierProvider<FileManagerController, List<LocalFileEntry>>(
  (ref) => FileManagerController(ref)..loadFromCache(),
);

class FileManagerController extends StateNotifier<List<LocalFileEntry>> {
  FileManagerController(this._ref) : super(const []);

  final Ref _ref;

  Future<void> loadFromCache() async {
    final box = await Hive.openBox<String>(_filesBoxName);
    final raw = box.get(_filesKey);
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(LocalFileEntry.fromJson)
          .toList();
      state = decoded;
    } catch (_) {
      // ignore corrupt cache
    }
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<String>(_filesBoxName);
    final encoded =
        jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await box.put(_filesKey, encoded);
  }

  /// Add a file entry (called by DownloadController on completion).
  void addFileEntry(LocalFileEntry entry) {
    if (state.any((e) => e.id == entry.id)) return;
    state = [...state, entry];
    _persist();
  }

  /// Pick files from device storage.
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'pptx', 'xlsx'],
    );

    if (result == null) return;

    final newEntries = <LocalFileEntry>[];
    for (final file in result.files) {
      if (kIsWeb) {
        // On web, file.path is null. Track metadata only.
        newEntries.add(
          LocalFileEntry(
            path: '',
            name: file.name,
            sizeBytes: file.size,
            mimeType: lookupMimeType(file.name) ?? 'application/octet-stream',
            source: FileSource.picked,
          ),
        );
      } else {
        final path = file.path;
        if (path == null) continue;
        final stat = await File(path).stat();
        newEntries.add(
          LocalFileEntry(
            path: path,
            name: p.basename(path),
            sizeBytes: stat.size,
            mimeType: lookupMimeType(path) ?? 'application/octet-stream',
            source: FileSource.picked,
            createdAt: stat.changed,
          ),
        );
      }
    }

    if (newEntries.isEmpty) return;
    state = [...state, ...newEntries];
    await _persist();
  }

  /// Delete a file entry and the physical file on mobile.
  Future<void> deleteFile(String id) async {
    final entry = state.firstWhere(
      (e) => e.id == id,
      orElse: () => state.first,
    );

    if (!kIsWeb && entry.path.isNotEmpty) {
      try {
        final file = File(entry.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  /// Open a file in the system's default viewer (mobile only).
  Future<void> openFile(String id) async {
    if (kIsWeb) return;
    final entry = state.firstWhere((e) => e.id == id);
    final opener = _ref.read(fileOpenerServiceProvider);
    await opener.openFile(entry.path);
  }

  /// Share a file using the system share sheet.
  Future<void> shareFile(String id) async {
    final entry = state.firstWhere((e) => e.id == id);
    if (kIsWeb) {
      if (entry.sourceUrl != null) {
        await Share.share(entry.sourceUrl!);
      }
      return;
    }
    await Share.shareXFiles([XFile(entry.path)], text: entry.name);
  }
}
