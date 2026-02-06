import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

class FileUtils {
  FileUtils._();

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static IconData iconForMime(String mime) {
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('presentation') || mime.contains('pptx') || mime.contains('ppt')) {
      return Icons.slideshow;
    }
    if (mime.contains('spreadsheet') || mime.contains('xlsx') || mime.contains('xls')) {
      return Icons.grid_on;
    }
    if (mime.contains('word') || mime.contains('docx') || mime.contains('doc')) {
      return Icons.article;
    }
    if (mime.contains('image')) return Icons.image;
    if (mime.contains('video')) return Icons.video_file;
    if (mime.contains('audio')) return Icons.audio_file;
    if (mime.contains('text')) return Icons.text_snippet;
    return Icons.description;
  }

  static Color colorForMime(String mime) {
    if (mime.contains('pdf')) return Colors.red;
    if (mime.contains('presentation') || mime.contains('pptx') || mime.contains('ppt')) {
      return Colors.orange;
    }
    if (mime.contains('spreadsheet') || mime.contains('xlsx') || mime.contains('xls')) {
      return Colors.green;
    }
    if (mime.contains('word') || mime.contains('docx') || mime.contains('doc')) {
      return Colors.blue;
    }
    if (mime.contains('image')) return Colors.purple;
    return Colors.grey;
  }

  static String inferMimeType(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }
}
