import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

final fileOpenerServiceProvider = Provider<FileOpenerService>(
  (ref) => FileOpenerService(),
);

class FileOpenerService {
  /// Opens the file at [path] with the system's default viewer.
  /// Returns null on web.
  Future<OpenResult?> openFile(String path) async {
    if (kIsWeb) return null;
    return OpenFilex.open(path);
  }
}
