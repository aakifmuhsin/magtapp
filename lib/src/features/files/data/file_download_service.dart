import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ProgressCallback = void Function(int receivedBytes, int totalBytes);

final fileDownloadServiceProvider = Provider<FileDownloadService>(
  (ref) => FileDownloadService(),
);

class FileDownloadService {
  /// Downloads a file on mobile platforms.
  /// Returns the saved file path.
  /// Callers MUST check kIsWeb before calling — this uses dart:io.
  Future<String> downloadFile({
    required String url,
    required String fileName,
    ProgressCallback? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'magtapp_downloads'));
    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }

    final targetPath = p.join(downloadDir.path, fileName);
    final resolvedPath = _resolveUniquePath(targetPath);

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? -1;
      int receivedBytes = 0;

      final file = File(resolvedPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress?.call(receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();

      return resolvedPath;
    } finally {
      client.close();
    }
  }

  /// On web, open URL in browser for native download handling.
  Future<void> launchDownloadInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _resolveUniquePath(String originalPath) {
    var file = File(originalPath);
    if (!file.existsSync()) return originalPath;

    final dir = p.dirname(originalPath);
    final baseName = p.basenameWithoutExtension(originalPath);
    final ext = p.extension(originalPath);
    int counter = 1;

    while (file.existsSync()) {
      file = File(p.join(dir, '$baseName ($counter)$ext'));
      counter++;
    }

    return file.path;
  }
}
