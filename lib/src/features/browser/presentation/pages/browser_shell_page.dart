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
              onAddTab: () =>
                  ref.read(browserTabsProvider.notifier).addTab(),
              onCloseTab: (id) =>
                  ref.read(browserTabsProvider.notifier).closeTab(id),
            ),
            Expanded(
              child: currentActiveId == null
                  ? const Center(
                      child: Text('No open tabs. Tap + to create one.'),
                    )
                  : InAppBrowserView(
                      tabId: currentActiveId,
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
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Open Tabs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final t in tabs)
              ListTile(
                title: Text(t.title ?? t.url),
                subtitle: Text(t.url),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref
                      .read(browserTabsProvider.notifier)
                      .closeTab(t.id),
                ),
                onTap: () {
                  setState(() {
                    _selected = BottomNavItem.home;
                  });
                  ref.read(activeTabIdProvider.notifier).state = t.id;
                },
              ),
          ],
        );
        break;
      case BottomNavItem.settings:
        body = const SettingsPage();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MagTapp AI Browser'),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected.index,
        onTap: (i) => setState(() {
          _selected = BottomNavItem.values[i];
        }),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tab),
            label: 'Tabs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selected == BottomNavItem.home
          ? const _SummarizeFab()
          : null,
    );
  }
}

class _SummarizeFab extends ConsumerWidget {
  const _SummarizeFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        // The SummaryPanel listens to this provider and will trigger extraction.
        ref
            .read(summaryActionTriggerProvider.notifier)
            .triggerFromActiveContext();
      },
      icon: const Icon(Icons.summarize_outlined),
      label: const Text('Summarize'),
    );
  }
}

