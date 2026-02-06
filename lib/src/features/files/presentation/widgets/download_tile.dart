import 'package:flutter/material.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/download_task.dart';

class DownloadTile extends StatelessWidget {
  const DownloadTile({
    super.key,
    required this.task,
    this.onCancel,
    this.onRetry,
    this.onRemove,
  });

  final DownloadTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: _buildStatusIcon(colors),
      title: Text(
        task.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: task.progress >= 0 ? task.progress : null,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              task.totalBytes > 0
                  ? '${FileUtils.formatFileSize(task.receivedBytes)} / ${FileUtils.formatFileSize(task.totalBytes)}'
                  : '${FileUtils.formatFileSize(task.receivedBytes)} downloaded',
              style: TextStyle(fontSize: 11, color: colors.outline),
            ),
          ],
          if (task.status == DownloadStatus.completed)
            Text(
              'Completed',
              style: TextStyle(fontSize: 12, color: colors.primary),
            ),
          if (task.status == DownloadStatus.failed)
            Text(
              task.errorMessage ?? 'Download failed',
              style: TextStyle(fontSize: 12, color: colors.error),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (task.status == DownloadStatus.cancelled)
            Text(
              'Cancelled',
              style: TextStyle(fontSize: 12, color: colors.outline),
            ),
        ],
      ),
      trailing: _buildTrailingAction(),
    );
  }

  Widget _buildStatusIcon(ColorScheme colors) {
    return switch (task.status) {
      DownloadStatus.pending || DownloadStatus.downloading => SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: task.progress >= 0 ? task.progress : null,
          ),
        ),
      DownloadStatus.completed =>
        Icon(Icons.check_circle, color: colors.primary),
      DownloadStatus.failed => Icon(Icons.error, color: colors.error),
      DownloadStatus.cancelled => Icon(Icons.cancel, color: colors.outline),
    };
  }

  Widget? _buildTrailingAction() {
    return switch (task.status) {
      DownloadStatus.downloading || DownloadStatus.pending => IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: onCancel,
        ),
      DownloadStatus.failed => IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Retry',
          onPressed: onRetry,
        ),
      DownloadStatus.completed || DownloadStatus.cancelled => IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remove',
          onPressed: onRemove,
        ),
    };
  }
}
