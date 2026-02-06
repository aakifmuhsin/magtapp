import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/file_source.dart';
import '../../domain/entities/local_file_entry.dart';

class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.entry,
    this.onOpen,
    this.onShare,
    this.onDelete,
  });

  final LocalFileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final fileColor = FileUtils.colorForMime(entry.mimeType);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: fileColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            FileUtils.iconForMime(entry.mimeType),
            color: fileColor,
          ),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              FileUtils.formatFileSize(entry.sizeBytes),
              style: TextStyle(fontSize: 12, color: colors.outline),
            ),
            const SizedBox(width: 8),
            Text(
              dateFormat.format(entry.createdAt),
              style: TextStyle(fontSize: 12, color: colors.outline),
            ),
            if (entry.source == FileSource.downloaded) ...[
              const SizedBox(width: 8),
              Icon(Icons.download_done, size: 14, color: colors.primary),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpen?.call();
              case 'share':
                onShare?.call();
              case 'delete':
                onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            if (!kIsWeb)
              const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${entry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
