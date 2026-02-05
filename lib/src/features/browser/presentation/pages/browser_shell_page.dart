import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magtapp/src/features/summarizer/application/summary_controller.dart';
import '../../../files/presentation/pages/file_manager_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../summarizer/presentation/widgets/summary_panel.dart';
import '../../application/browser_tab_controller.dart';
import '../widgets/browser_tab_bar.dart';
import '../widgets/in_app_browser_view.dart';

enum BottomNavItem { home, files, tabs, settings }

class BrowserShellPage extends ConsumerStatefulWidget {
  const BrowserShellPage({super.key});

  @override
  ConsumerState<BrowserShellPage> createState() => _BrowserShellPageState();
}

class _BrowserShellPageState extends ConsumerState<BrowserShellPage> {
  BottomNavItem _selected = BottomNavItem.home;

  @override
  void initState() {
    super.initState();
    // Ensure at least one tab exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabs = ref.read(browserTabsProvider);
      if (tabs.isEmpty) {
        ref.read(browserTabsProvider.notifier).addTab();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(browserTabsProvider);
    final activeTabId = ref.watch(activeTabIdProvider);

    final currentActiveId =
        activeTabId ?? (tabs.isNotEmpty ? tabs.last.id : null);

    // Determine the active tab index for IndexedStack.
    final activeIndex = currentActiveId != null
        ? tabs.indexWhere((t) => t.id == currentActiveId)
        : -1;

    Widget body;
    switch (_selected) {
      case BottomNavItem.home:
        body = Column(
          children: [
            BrowserTabBar(
              tabs: tabs,
              activeTabId: currentActiveId,
              onTabSelected: (id) =>
                  ref.read(activeTabIdProvider.notifier).state = id,
              onAddTab: () {
                ref.read(browserTabsProvider.notifier).addTab();
                // Auto-select the new tab.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final latest = ref.read(browserTabsProvider);
                  if (latest.isNotEmpty) {
                    ref.read(activeTabIdProvider.notifier).state =
                        latest.last.id;
                  }
                });
              },
              onCloseTab: (id) {
                ref.read(browserTabsProvider.notifier).closeTab(id);
                // If we closed the active tab, pick a new one.
                if (id == currentActiveId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final remaining = ref.read(browserTabsProvider);
                    ref.read(activeTabIdProvider.notifier).state =
                        remaining.isNotEmpty ? remaining.last.id : null;
                  });
                }
              },
            ),
            Expanded(
              child: tabs.isEmpty || activeIndex < 0
                  ? const Center(
                      child: Text('No open tabs. Tap + to create one.'),
                    )
                  : IndexedStack(
                      index: activeIndex,
                      children: [
                        for (final tab in tabs)
                          InAppBrowserView(
                            key: ValueKey(tab.id),
                            tabId: tab.id,
                          ),
                      ],
                    ),
            ),
            const SummaryPanel(),
          ],
        );
        break;
      case BottomNavItem.files:
        body = const FileManagerPage();
        break;
      case BottomNavItem.tabs:
        body = _buildTabsOverview(tabs, currentActiveId);
        break;
      case BottomNavItem.settings:
        body = const SettingsPage();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MagTapp AI Browser'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_selected),
          child: body,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected.index,
        onTap: (i) => setState(() {
          _selected = BottomNavItem.values[i];
        }),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tab_outlined),
            activeIcon: Icon(Icons.tab),
            label: 'Tabs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selected == BottomNavItem.home
          ? const _SummarizeFab()
          : null,
    );
  }

  Widget _buildTabsOverview(List tabs, String? currentActiveId) {
    if (tabs.isEmpty) {
      return const Center(child: Text('No open tabs.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tabs.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Open Tabs (${tabs.length})',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }

        final t = tabs[index - 1];
        final isActive = t.id == currentActiveId;

        return Card(
          elevation: isActive ? 2 : 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.language,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(
              t.title ?? t.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              t.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref
                  .read(browserTabsProvider.notifier)
                  .closeTab(t.id),
            ),
            onTap: () {
              ref.read(activeTabIdProvider.notifier).state = t.id;
              setState(() {
                _selected = BottomNavItem.home;
              });
            },
          ),
        );
      },
    );
  }
}

class _SummarizeFab extends ConsumerWidget {
  const _SummarizeFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        ref
            .read(summaryActionTriggerProvider.notifier)
            .triggerFromActiveContext();
      },
      icon: const Icon(Icons.summarize_outlined),
      label: const Text('Summarize'),
    );
  }
}
