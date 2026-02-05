import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/browser_tab.dart';

const _tabsBoxName = 'browser_tabs_box';
const _tabsKey = 'tabs_state';

final browserTabsProvider =
    StateNotifierProvider<BrowserTabController, List<BrowserTab>>(
  (ref) => BrowserTabController()..loadFromCache(),
);

final activeTabIdProvider = StateProvider<String?>((ref) => null);

class BrowserTabController extends StateNotifier<List<BrowserTab>> {
  BrowserTabController() : super(const []);

  Future<void> loadFromCache() async {
    final box = await Hive.openBox<String>(_tabsBoxName);
    final raw = box.get(_tabsKey);
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(BrowserTab.fromJson)
          .toList();
      if (decoded.isNotEmpty) {
        state = decoded;
      }
    } catch (_) {
      // ignore corrupt cache
    }
  }

  Future<void> _persist() async {
    final box = await Hive.openBox<String>(_tabsBoxName);
    final encoded =
        jsonEncode(state.map((e) => e.toJson()).toList(growable: false));
    await box.put(_tabsKey, encoded);
  }

  void addTab({String initialUrl = 'https://www.google.com'}) {
    final newTab = BrowserTab(
      id: const Uuid().v4(),
      url: initialUrl,
      isLoading: true,
    );
    state = [...state, newTab];
    _persist();
  }

  void closeTab(String id) {
    state = state.where((t) => t.id != id).toList();
    _persist();
  }

  void updateTab(String id, BrowserTab Function(BrowserTab) updater) {
    state = [
      for (final t in state) if (t.id == id) updater(t) else t,
    ];
    _persist();
  }
}

