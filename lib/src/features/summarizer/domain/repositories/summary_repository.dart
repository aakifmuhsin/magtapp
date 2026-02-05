import '../entities/summary_result.dart';

abstract class SummaryRepository {
  /// Summarizes the given [text]. In this assignment build we provide a
  /// mock, deterministic implementation so the app works fully offline.
  Future<SummaryResult> summarize(String text);

  /// Translates the given [summary] into [targetLanguageCode].
  /// Example language codes: 'hi', 'es', 'fr'.
  Future<SummaryResult> translateSummary(
    SummaryResult summary,
    String targetLanguageCode,
  );
}

