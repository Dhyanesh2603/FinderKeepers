import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/item/domain/models/item.dart';

/// Service managing offline persistence, draft preservation, and queued submissions.
class OfflineService {
  static const String _draftKey = 'finders_keepers_report_draft';
  static const String _cachedItemsKey = 'finders_keepers_cached_items';
  static const String _offlineQueueKey = 'finders_keepers_offline_queue';

  /// Saves in-progress report draft to survive app crashes or interruptions.
  static Future<void> saveDraft({
    required String title,
    required String description,
    required String type,
    required String category,
    required String location,
    required List<String> questions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draftData = {
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'location': location,
      'questions': questions,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_draftKey, jsonEncode(draftData));
  }

  /// Retrieves previously saved draft, or null if no draft exists.
  static Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clears saved draft once report is successfully published.
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  /// Caches feed items locally for offline retrieval.
  static Future<void> cacheItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = items.map((i) => i.toJson()).toList();
    await prefs.setString(_cachedItemsKey, jsonEncode(listJson));
  }

  /// Loads cached items from local storage during offline mode.
  static Future<List<Item>> loadCachedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedItemsKey);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((map) => Item.fromJson(map as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Enqueues item report created while offline.
  static Future<void> enqueueOfflineReport(Item item) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_offlineQueueKey) ?? [];
    existing.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_offlineQueueKey, existing);
  }

  /// Retrieves and drains offline queue for background sync.
  static Future<List<Item>> drainOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_offlineQueueKey) ?? [];
    if (existing.isEmpty) return [];

    final List<Item> items = [];
    for (final raw in existing) {
      try {
        items.add(Item.fromJson(jsonDecode(raw)));
      } catch (_) {}
    }

    await prefs.remove(_offlineQueueKey);
    return items;
  }
}

/// Simulated / Live Offline Mode Switcher
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool isOffline) => state = isOffline;
}

final isOfflineModeProvider =
    NotifierProvider<OfflineModeNotifier, bool>(OfflineModeNotifier.new);
