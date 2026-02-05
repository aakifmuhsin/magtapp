import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../application/summary_controller.dart';

class SummaryPanel extends ConsumerStatefulWidget {
  const SummaryPanel({super.key});

  @override
  ConsumerState<SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<SummaryPanel> {
  bool _expanded = false;
  bool _showTranslation = false;
  String _selectedLanguage = 'hi';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryControllerProvider);

    if (!_expanded && state.result == null && !state.isLoading) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('AI Summary'),
            subtitle: Text(
              state.isLoading
                  ? 'Generating...'
                  : state.result == null
                      ? 'Tap Summarize to generate from current page'
                      : 'Tap to ${_expanded ? 'collapse' : 'expand'}',
            ),
            trailing: Icon(
              _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            ),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
          ),
          if (_expanded)
            SizedBox(
              height: 240,
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(context, state),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SummaryState state) {
    final result = state.result;
    if (result == null) {
      return const Center(
        child: Text(
          'No summary yet. Use the Summarize button on the main screen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final reduction = result.originalWordCount == 0
        ? 0
        : (100 -
                (result.summaryWordCount / result.originalWordCount * 100))
            .round();

    final textToShow =
        _showTranslation && result.translatedText != null
            ? result.translatedText!
            : result.summaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(
                  'Words: ${result.summaryWordCount}/${result.originalWordCount}',
                ),
              ),
              Chip(
                label: Text('Reduction: $reduction%'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                textToShow,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: textToShow));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(textToShow);
                },
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text('Hindi'),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Text('Spanish'),
                  ),
                  DropdownMenuItem(
                    value: 'fr',
                    child: Text('French'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedLanguage = value;
                  });
                  ref
                      .read(summaryControllerProvider.notifier)
                      .translate(value);
                  setState(() {
                    _showTranslation = true;
                  });
                },
              ),
              const SizedBox(width: 8),
              Switch(
                value: _showTranslation,
                onChanged: (v) {
                  setState(() {
                    _showTranslation = v;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

