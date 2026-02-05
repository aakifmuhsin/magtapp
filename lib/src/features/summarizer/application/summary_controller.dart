import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../browser/application/browser_tab_controller.dart';
import '../data/mock_summary_repository.dart';
import '../domain/entities/summary_result.dart';
import '../domain/repositories/summary_repository.dart';

const _summaryBoxName = 'summary_cache_box';

final summaryRepositoryProvider = Provider<SummaryRepository>(
  (ref) => MockSummaryRepository(),
);

class SummaryState {
  const SummaryState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final bool isLoading;
  final String? errorMessage;
  final SummaryResult? result;

  SummaryState copyWith({
    bool? isLoading,
    String? errorMessage,
    SummaryResult? result,
  }) {
    return SummaryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      result: result ?? this.result,
    );
  }
}

final summaryControllerProvider =
    StateNotifierProvider<SummaryController, SummaryState>(
  (ref) => SummaryController(ref),
);

class SummaryController extends StateNotifier<SummaryState> {
  SummaryController(this._ref) : super(const SummaryState());

  final Ref _ref;

  Future<void> summarizeCurrentPage() async {
    final tabs = _ref.read(browserTabsProvider);
    final activeId = _ref.read(activeTabIdProvider);
    final activeTab =
        tabs.firstWhere((t) => t.id == activeId, orElse: () => tabs.last);

    final url = activeTab.url;
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Caching key: URL.
    final cached = await _getCachedSummary(url);
    if (cached != null) {
      state = SummaryState(isLoading: false, result: cached);
      return;
    }

    // For assignment: we do NOT parse DOM (WebView constraint),
    // but in a real app you'd inject JS to extract document.body.innerText.
    // Here we use URL as a pseudo "content" plus a static note.
    final repository = _ref.read(summaryRepositoryProvider);
    final syntheticText =
        'Content summary for $url. This is a demo mock where the actual web page text '
        'would be extracted via DOM parsing in production.';

    final result = await repository.summarize(syntheticText);
    await _cacheSummary(url, result);
    state = SummaryState(isLoading: false, result: result);
  }

  Future<void> translate(String languageCode) async {
    final current = state.result;
    if (current == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = _ref.read(summaryRepositoryProvider);
    final translated = await repository.translateSummary(
      current,
      languageCode,
    );
    state = SummaryState(isLoading: false, result: translated);
  }

  Future<void> _cacheSummary(String key, SummaryResult result) async {
    final box = await Hive.openBox<String>(_summaryBoxName);
    await box.put(
      key,
      jsonEncode(<String, dynamic>{
        'originalWordCount': result.originalWordCount,
        'summaryWordCount': result.summaryWordCount,
        'summaryText': result.summaryText,
        'translatedText': result.translatedText,
        'targetLanguageCode': result.targetLanguageCode,
      }),
    );
  }

  Future<SummaryResult?> _getCachedSummary(String key) async {
    final box = await Hive.openBox<String>(_summaryBoxName);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SummaryResult(
        originalWordCount: map['originalWordCount'] as int,
        summaryWordCount: map['summaryWordCount'] as int,
        summaryText: map['summaryText'] as String,
        translatedText: map['translatedText'] as String?,
        targetLanguageCode: map['targetLanguageCode'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Simple provider to let the FAB notify the panel to run summary.
final summaryActionTriggerProvider =
    StateNotifierProvider<SummaryActionTrigger, int>(
  (ref) => SummaryActionTrigger(ref),
);

class SummaryActionTrigger extends StateNotifier<int> {
  SummaryActionTrigger(this._ref) : super(0);

  final Ref _ref;

  Future<void> triggerFromActiveContext() async {
    state++;
    await _ref.read(summaryControllerProvider.notifier).summarizeCurrentPage();
  }
}

