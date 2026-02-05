import 'package:flutter/material.dart';

import '../../domain/entities/browser_tab.dart';

class BrowserTabBar extends StatelessWidget {
  const BrowserTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
    required this.onAddTab,
    required this.onCloseTab,
  });

  final List<BrowserTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onTabSelected;
  final VoidCallback onAddTab;
  final ValueChanged<String> onCloseTab;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isActive = tab.id == activeTabId;
                  return GestureDetector(
                    onTap: () => onTabSelected(tab.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 16,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: Text(
                              tab.title ?? tab.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onCloseTab(tab.id),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemCount: tabs.length,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New tab',
              onPressed: onAddTab,
            ),
          ],
        ),
      ),
    );
  }
}

