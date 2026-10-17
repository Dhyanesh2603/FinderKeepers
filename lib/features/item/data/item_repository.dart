import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/item.dart';

/// Abstract contract for querying and reporting items.
abstract class ItemRepository {
  Stream<List<Item>> get itemsStream;
  Future<List<Item>> getItems();
  Future<Item?> getItemById(String id);
  Future<void> addItem(Item item);
  Future<void> updateItemStatus(String id, ItemStatus status);
  Future<void> clearAllItems();
}

/// In-memory implementation backed purely by SharedPreferences persistence.
/// Starts completely empty — only items reported by the user are stored and shown.
class InMemoryItemRepository implements ItemRepository {
  static const String _persistedItemsKey = 'finders_keepers_items_v3';
  final _controller = StreamController<List<Item>>.broadcast();

  final List<Item> _items = [];

  InMemoryItemRepository() {
    _emit();
    _loadFromStorage();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_items));
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistedItemsKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        final loadedItems = decoded
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();

        _items.clear();
        _items.addAll(loadedItems);
        _emit();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_persistedItemsKey, encoded);
    } catch (_) {}
  }

  @override
  Stream<List<Item>> get itemsStream => _controller.stream;

  @override
  Future<List<Item>> getItems() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<Item?> getItemById(String id) async {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addItem(Item item) async {
    _items.insert(0, item);
    _emit();
    await _saveToStorage();
  }

  @override
  Future<void> updateItemStatus(String id, ItemStatus status) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final old = _items[index];
      _items[index] = Item(
        id: old.id,
        title: old.title,
        description: old.description,
        type: old.type,
        status: status,
        category: old.category,
        approximateLocation: old.approximateLocation,
        latitude: old.latitude,
        longitude: old.longitude,
        reporterId: old.reporterId,
        reporterName: old.reporterName,
        photoUrl: old.photoUrl,
        createdAt: old.createdAt,
        verificationQuestions: old.verificationQuestions,
      );
      _emit();
      await _saveToStorage();
    }
  }

  @override
  Future<void> clearAllItems() async {
    _items.clear();
    _emit();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistedItemsKey);
    } catch (_) {}
  }
}

/// Global repository provider.
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return InMemoryItemRepository();
});

/// Reactive stream of all items from the repository.
final itemsStreamProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.itemsStream;
});

/// Specific item provider by ID.
final itemByIdProvider = Provider.family<Item?, String>((ref, id) {
  final items = ref.watch(itemsStreamProvider).value ?? [];
  try {
    return items.firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
});
