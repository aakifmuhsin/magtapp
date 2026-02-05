import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/file_manager_controller.dart';

class FileManagerPage extends ConsumerWidget {
  const FileManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Pick from device',
            onPressed: () =>
                ref.read(fileManagerProvider.notifier).pickFiles(),
          ),
        ],
      ),
      body: files.isEmpty
          ? const Center(
              child: Text('No files yet. Use the upload button to add some.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: files.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final f = files[index];
                return ListTile(
                  leading: Icon(
                    _iconForMime(f.mimeType),
                  ),
                  title: Text(f.name),
                  subtitle: Text(
                    '${(f.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                  ),
                  onTap: () {
                    // For assignment: simply open with OS handler.
                    // In a production app you might use dedicated viewers.
                    if (Platform.isAndroid || Platform.isIOS) {
                      // TODO: integrate open_filex or similar.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Opening with system viewer is not implemented in this demo.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  IconData _iconForMime(String mime) {
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('presentation')) return Icons.slideshow;
    if (mime.contains('spreadsheet')) return Icons.grid_on;
    return Icons.description;
  }
}

