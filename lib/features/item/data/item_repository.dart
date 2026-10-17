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
}

/// In-memory implementation pre-loaded with realistic campus data and backed by SharedPreferences persistence.
class InMemoryItemRepository implements ItemRepository {
  static const String _persistedItemsKey = 'finders_keepers_persisted_items';
  final _controller = StreamController<List<Item>>.broadcast();

  final List<Item> _items = [
    Item(
      id: 'item_101',
      title: 'Sony Noise-Cancelling Headphones',
      description: 'Black over-ear headphones found on a study desk on 3rd floor.',
      type: ItemType.found,
      status: ItemStatus.open,
      category: ItemCategory.electronics,
      approximateLocation: 'Main Library • 3rd Floor Quiet Zone',
      latitude: 12.9692,
      longitude: 79.1559,
      reporterId: 'user_001',
      reporterName: 'Alex Rivers',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      verificationQuestions: [
        'What color or brand is the carrying pouch?',
        'Is there any sticker or serial number on the headband?',
      ],
    ),
    Item(
      id: 'item_102',
      title: 'Leather Wallet with Student Card',
      description: 'Brown bifold leather wallet lost near the food court.',
      type: ItemType.lost,
      status: ItemStatus.open,
      category: ItemCategory.wallets,
      approximateLocation: 'Student Union Building • Food Court',
      latitude: 12.9680,
      longitude: 79.1580,
      reporterId: 'user_002',
      reporterName: 'Taylor Morgan',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      verificationQuestions: [
        'What is the bank name on the debit card inside?',
        'Describe the initials or brand logo stamped on the leather.',
      ],
    ),
    Item(
      id: 'item_103',
      title: 'Campus Dorm Keyring (3 keys)',
      description: 'Keys with a blue spiral wristband and dorm tag.',
      type: ItemType.found,
      status: ItemStatus.open,
      category: ItemCategory.keys,
      approximateLocation: 'Engineering Hall • Lab 204',
      latitude: 12.9710,
      longitude: 79.1594,
      reporterId: 'user_003',
      reporterName: 'Samira Chen',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      verificationQuestions: [
        'What room number or code is stamped on the brass key?',
      ],
    ),
    Item(
      id: 'item_104',
      title: 'Calculus & Linear Algebra Textbook',
      description: 'Hardcover textbook left on the bench outside lecture hall.',
      type: ItemType.found,
      status: ItemStatus.reunited,
      category: ItemCategory.bagsBooks,
      approximateLocation: 'Science Center • Lecture Hall B',
      latitude: 12.9722,
      longitude: 79.1638,
      reporterId: 'user_001',
      reporterName: 'Alex Rivers',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      verificationQuestions: [
        'What name or note is written on the first page?',
      ],
    ),
    Item(
      id: 'item_105',
      title: 'Apple AirPods Pro in Matte Black Case',
      description: 'AirPods slipped out of jacket pocket during evening lecture.',
      type: ItemType.lost,
      status: ItemStatus.claimPending,
      category: ItemCategory.electronics,
      approximateLocation: 'Business Complex • Auditorium A',
      latitude: 12.9705,
      longitude: 79.1610,
      reporterId: 'user_004',
      reporterName: 'Jordan Vance',
      createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      verificationQuestions: [
        'What engraving or custom text appears on the case lid?',
      ],
    ),
  ];

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

        for (final item in loadedItems.reversed) {
          final existingIdx = _items.indexWhere((i) => i.id == item.id);
          if (existingIdx != -1) {
            _items[existingIdx] = item;
          } else {
            _items.insert(0, item);
          }
        }
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
