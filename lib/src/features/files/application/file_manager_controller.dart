import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../domain/entities/local_file_entry.dart';

const _filesBoxName = 'downloaded_files_box';
const _filesKey = 'files';

final fileManagerProvider =
    StateNotifierProvider<FileManagerController, List<LocalFileEntry>>(
  (ref) => FileManagerController()..loadFromCache(),
);

class FileManagerController extends StateNotifier<List<LocalFileEntry>> {
  FileManagerController() : super(const []);

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
      // ignore
    }
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<String>(_filesBoxName);
    final encoded =
        jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await box.put(_filesKey, encoded);
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'pptx', 'xlsx'],
    );

    if (result == null) return;

    final newEntries = <LocalFileEntry>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;
      final stat = await File(path).stat();
      final mime = lookupMimeType(path) ?? 'application/octet-stream';
      newEntries.add(
        LocalFileEntry(
          path: path,
          name: p.basename(path),
          sizeBytes: stat.size,
          mimeType: mime,
          createdAt: stat.changed,
        ),
      );
    }

    if (newEntries.isEmpty) return;

    state = [...state, ...newEntries];
    await _persist();
  }
}

