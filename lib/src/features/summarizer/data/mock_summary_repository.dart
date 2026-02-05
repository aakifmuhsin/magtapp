import 'dart:math';

import '../domain/entities/summary_result.dart';
import '../domain/repositories/summary_repository.dart';

/// Simple offline mock implementation:
/// - Summary: returns the first ~30% of the text (by words).
/// - Translation: prefixes text with a language label to simulate translation.
class MockSummaryRepository implements SummaryRepository {
  @override
  Future<SummaryResult> summarize(String text) async {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return SummaryResult(
        originalWordCount: 0,
        summaryWordCount: 0,
        summaryText: '',
      );
    }
    final targetCount = max(1, (words.length * 0.3).floor());
    final summaryWords = words.take(targetCount).toList();
    final summaryText = summaryWords.join(' ');
    return SummaryResult(
      originalWordCount: words.length,
      summaryWordCount: summaryWords.length,
      summaryText: summaryText,
    );
  }

  @override
  Future<SummaryResult> translateSummary(
    SummaryResult summary,
    String targetLanguageCode,
  ) async {
    final label = switch (targetLanguageCode) {
      'hi' => '[Hindi]',
      'es' => '[Spanish]',
      'fr' => '[French]',
      _ => '[Translated]',
    };
    return summary.copyWith(
      translatedText: '$label ${summary.summaryText}',
      targetLanguageCode: targetLanguageCode,
    );
  }
}

