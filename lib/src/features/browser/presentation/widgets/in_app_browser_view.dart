import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

class _InAppBrowserViewState extends ConsumerState<InAppBrowserView> {
  // Only initialized on non-web platforms.
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(isLoading: true, url: url),
                  );
            },
            onPageFinished: (url) async {
              final title = await _controller!.getTitle();
              ref.read(browserTabsProvider.notifier).updateTab(
                    widget.tabId,
                    (t) => t.copyWith(
                      isLoading: false,
                      url: url,
                      title: title ?? t.title,
                    ),
                  );
            },
            onWebResourceError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Load error: ${error.description}')),
              );
            },
          ),
        );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = ref
          .read(browserTabsProvider)
          .firstWhere((t) => t.id == widget.tabId, orElse: () => throw '');
      _loadUrl(tab.url);
    });
  }

  void _loadUrl(String url) {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    if (kIsWeb) {
      setState(() => _webUrl = normalized);
    } else {
      _controller!.loadRequest(Uri.parse(normalized));
    }
  }

  // Tracks the current URL for the web iframe.
  String _webUrl = '';

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(browserTabsProvider);
    final tab = tabs.firstWhere((t) => t.id == widget.tabId);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: tab.url),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Enter URL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                  onSubmitted: _loadUrl,
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => _controller!.goBack(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Forward',
                  onPressed: () => _controller!.goForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => _controller!.reload(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: kIsWeb
              ? _buildWebIframe()
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (tab.isLoading)
                      const Align(
                        alignment: Alignment.topCenter,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWebIframe() {
    if (_webUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // HtmlElementView renders a platform view; on web, webview_flutter_web
    // is not reliable, so we embed a simple iframe via url_launcher or
    // show a message directing the user to open the link externally.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.public, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _webUrl,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'In-app WebView is not available on the web platform.\n'
            'Use Android or iOS for the full browser experience.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

