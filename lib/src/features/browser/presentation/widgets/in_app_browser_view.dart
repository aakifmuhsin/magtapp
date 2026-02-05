import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/browser_tab_controller.dart';

class InAppBrowserView extends ConsumerStatefulWidget {
  const InAppBrowserView({
    super.key,
    required this.tabId,
  });

  final String tabId;

  @override
  ConsumerState<InAppBrowserView> createState() => _InAppBrowserViewState();
}

class _InAppBrowserViewState extends ConsumerState<InAppBrowserView>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _webViewController;
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final tab = ref
        .read(browserTabsProvider)
        .firstWhere((t) => t.id == widget.tabId);
    _urlController.text = tab.url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _normalizeInput(String input) {
    input = input.trim();
    if (input.isEmpty) return 'https://www.google.com';

    // Looks like a URL (has a dot and no spaces).
    if (input.contains('.') && !input.contains(' ')) {
      if (!input.startsWith('http')) return 'https://$input';
      return input;
    }

    // Treat as a Google search query.
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(input)}';
  }

  void _loadUrl(String input) {
    final url = _normalizeInput(input);
    _urlController.text = url;
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _webViewController?.canGoBack() ?? false;
    final canGoForward = await _webViewController?.canGoForward() ?? false;
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final tabs = ref.watch(browserTabsProvider);
    final tab = tabs.firstWhere((t) => t.id == widget.tabId);
    final colors = Theme.of(context).colorScheme;

    final initialUrl =
        tab.url.startsWith('http') ? tab.url : 'https://${tab.url}';

    return Column(
      children: [
        // ── Address bar ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          color: colors.surface,
          child: Row(
            children: [
              // Back
              IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: _canGoBack ? colors.onSurface : colors.outline,
                ),
                onPressed:
                    _canGoBack ? () => _webViewController?.goBack() : null,
              ),
              // Forward
              IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _canGoForward ? colors.onSurface : colors.outline,
                ),
                onPressed: _canGoForward
                    ? () => _webViewController?.goForward()
                    : null,
              ),
              // Refresh / stop
              IconButton(
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: tab.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: () {
                  if (tab.isLoading) {
                    _webViewController?.stopLoading();
                  } else {
                    _webViewController?.reload();
                  }
                },
              ),
              // URL text field
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: kIsWeb
                        ? IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            tooltip: 'Open in new tab',
                            onPressed: () {
                              final url = _urlController.text.trim();
                              if (url.isNotEmpty) {
                                launchUrl(Uri.parse(_normalizeInput(url)),
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          )
                        : null,
                    hintText: 'Search or enter URL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: _loadUrl,
                  textInputAction: TextInputAction.go,
                ),
              ),
            ],
          ),
        ),

        // ── Progress indicator ───────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: (_progress > 0 && _progress < 1) ? 3 : 0,
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 3,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),

        // ── WebView ──────────────────────────────────────────────────
        Expanded(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllow: 'camera; microphone',
              iframeAllowFullscreen: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              if (url != null) {
                _urlController.text = url.toString();
              }
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(
                      isLoading: true,
                      url: url?.toString() ?? t.url,
                    ),
                  );
            },
            onLoadStop: (controller, url) async {
              String? title;
              try {
                title = await controller.getTitle();
              } catch (_) {}
              await _updateNavigationState();
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(
                      isLoading: false,
                      url: url?.toString() ?? t.url,
                      title: title ?? t.title,
                      progress: 1.0,
                    ),
                  );
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(progress: progress / 100),
                  );
            },
            onUpdateVisitedHistory: (controller, url, isReload) {
              if (url != null) {
                _urlController.text = url.toString();
              }
              _updateNavigationState();
            },
            onReceivedError: (controller, request, error) {
              if (!mounted) return;
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(isLoading: false, progress: 0),
                  );
            },
          ),
        ),
      ],
    );
  }
}
