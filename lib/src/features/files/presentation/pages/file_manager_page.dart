import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/download_controller.dart';
import '../../application/file_manager_controller.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/file_source.dart';
import '../widgets/download_tile.dart';
import '../widgets/file_tile.dart';

class FileManagerPage extends ConsumerStatefulWidget {
  const FileManagerPage({super.key});

  @override
  ConsumerState<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends ConsumerState<FileManagerPage> {
  FileSource? _filterSource;

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(fileManagerProvider);
    final downloads = ref.watch(downloadControllerProvider);
    final activeDownloads = downloads.where((d) => d.isActive).toList();
    final historyDownloads = downloads.where((d) => !d.isActive).toList();
    final colors = Theme.of(context).colorScheme;

    final filteredFiles = _filterSource == null
        ? files
        : files.where((f) => f.source == _filterSource).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        automaticallyImplyLeading: false,
        actions: [
          if (historyDownloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Clear download history',
              onPressed: () =>
                  ref.read(downloadControllerProvider.notifier).clearHistory(),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Active downloads ──────────────────────────────────────
          if (activeDownloads.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Downloading (${activeDownloads.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: activeDownloads.length,
              itemBuilder: (context, index) {
                final task = activeDownloads[index];
                return DownloadTile(
                  task: task,
                  onCancel: () => ref
                      .read(downloadControllerProvider.notifier)
                      .cancelDownload(task.id),
                );
              },
            ),
            const SliverToBoxAdapter(child: Divider()),
          ],

          // ── Filter chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All', null, files.length),
                  _buildFilterChip(
                    'Downloaded',
                    FileSource.downloaded,
                    files.where((f) => f.source == FileSource.downloaded).length,
                  ),
                  _buildFilterChip(
                    'Picked',
                    FileSource.picked,
                    files.where((f) => f.source == FileSource.picked).length,
                  ),
                ],
              ),
            ),
          ),

          // ── File list or empty state ─────────────────────────────
          if (filteredFiles.isEmpty)
            const SliverFillRemaining(child: _EmptyFileState())
          else
            SliverList.builder(
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                final entry = filteredFiles[index];
                return FileTile(
                  entry: entry,
                  onOpen: () => ref
                      .read(fileManagerProvider.notifier)
                      .openFile(entry.id),
                  onShare: () => ref
                      .read(fileManagerProvider.notifier)
                      .shareFile(entry.id),
                  onDelete: () => ref
                      .read(fileManagerProvider.notifier)
                      .deleteFile(entry.id),
                );
              },
            ),

          // ── Download history ─────────────────────────────────────
          if (historyDownloads.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Download History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: historyDownloads.length,
              itemBuilder: (context, index) {
                final task = historyDownloads[index];
                return DownloadTile(
                  task: task,
                  onRetry: task.status == DownloadStatus.failed
                      ? () => ref
                            .read(downloadControllerProvider.notifier)
                            .retryDownload(task.id)
                      : null,
                  onRemove: () => ref
                      .read(downloadControllerProvider.notifier)
                      .removeTask(task.id),
                );
              },
            ),
          ],

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(fileManagerProvider.notifier).pickFiles(),
        tooltip: 'Pick files from device',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, FileSource? source, int count) {
    final isSelected = _filterSource == source;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterSource = source),
    );
  }
}

class _EmptyFileState extends StatelessWidget {
  const _EmptyFileState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 64, color: colors.outline),
          const SizedBox(height: 16),
          const Text(
            'No files yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Download files from the browser\nor pick from your device',
            style: TextStyle(color: colors.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
