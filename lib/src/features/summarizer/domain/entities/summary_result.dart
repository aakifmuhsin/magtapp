class SummaryResult {
  SummaryResult({
    required this.originalWordCount,
    required this.summaryWordCount,
    required this.summaryText,
    this.translatedText,
    this.targetLanguageCode,
  });

  final int originalWordCount;
  final int summaryWordCount;
  final String summaryText;
  final String? translatedText;
  final String? targetLanguageCode;

  SummaryResult copyWith({
    int? originalWordCount,
    int? summaryWordCount,
    String? summaryText,
    String? translatedText,
    String? targetLanguageCode,
  }) {
    return SummaryResult(
      originalWordCount: originalWordCount ?? this.originalWordCount,
      summaryWordCount: summaryWordCount ?? this.summaryWordCount,
      summaryText: summaryText ?? this.summaryText,
      translatedText: translatedText ?? this.translatedText,
      targetLanguageCode: targetLanguageCode ?? this.targetLanguageCode,
    );
  }
}

