import 'dart:io';

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
  late final WebViewController _controller;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _currentUrl = url;
            ref.read(browserTabsProvider.notifier).updateTab(
                  widget.tabId,
                  (t) => t.copyWith(isLoading: true, url: url),
                );
          },
          onPageFinished: (url) async {
            final title = await _controller.getTitle();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = ref
          .read(browserTabsProvider)
          .firstWhere((t) => t.id == widget.tabId, orElse: () => throw '');
      _loadUrl(tab.url);
    });
  }

  void _loadUrl(String url) {
    final normalized = url.startsWith('http') ? url : 'https://$url';
    _controller.loadRequest(Uri.parse(normalized));
  }

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
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => _controller.goBack(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Forward',
                onPressed: () => _controller.goForward(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () => _controller.reload(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
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
}

