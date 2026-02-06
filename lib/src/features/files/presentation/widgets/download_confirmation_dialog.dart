import 'package:flutter/material.dart';

import '../../../../core/utils/file_utils.dart';

class DownloadConfirmationDialog extends StatelessWidget {
  const DownloadConfirmationDialog({
    super.key,
    required this.fileName,
    required this.url,
    this.contentLength = -1,
    this.mimeType,
  });

  final String fileName;
  final String url;
  final int contentLength;
  final String? mimeType;

  static Future<bool> show(
    BuildContext context, {
    required String fileName,
    required String url,
    int contentLength = -1,
    String? mimeType,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DownloadConfirmationDialog(
        fileName: fileName,
        url: url,
        contentLength: contentLength,
        mimeType: mimeType,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final mime = mimeType ?? 'application/octet-stream';

    return AlertDialog(
      title: const Text('Download File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FileUtils.iconForMime(mime),
                color: FileUtils.colorForMime(mime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contentLength > 0)
            Text('Size: ${FileUtils.formatFileSize(contentLength)}'),
          const SizedBox(height: 4),
          Text(
            url,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.download),
          label: const Text('Download'),
        ),
      ],
    );
  }
}
