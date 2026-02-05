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
    final colors = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      color: colors.surface,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isActive = tab.id == activeTabId;

                  return GestureDetector(
                    onTap: () => onTabSelected(tab.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: isActive
                            ? Border.all(
                                color: colors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Loading dot or icon
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: tab.isLoading
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isActive
                                          ? colors.primary
                                          : colors.outline,
                                    ),
                                  )
                                : Icon(
                                    Icons.language,
                                    key: const ValueKey('icon'),
                                    size: 16,
                                    color: isActive
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              tab.title ?? _shortenUrl(tab.url),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isActive
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onCloseTab(tab.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? colors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: isActive
                                    ? colors.primary
                                    : colors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer,
              ),
              child: IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.add, color: colors.primary),
                tooltip: 'New tab',
                onPressed: onAddTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url;
    }
  }
}
