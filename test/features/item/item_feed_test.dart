import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/features/item/data/item_repository.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';

void main() {
  group('ItemRepository and Feed Logic', () {
    late InMemoryItemRepository itemRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      itemRepository = InMemoryItemRepository();
    });

    test('starts empty by default so only user reported items are stored', () async {
      final items = await itemRepository.getItems();
      expect(items.isEmpty, true);
    });

    test('adds new item and emits updated stream', () async {
      final newItem = Item(
        id: 'test_item_999',
        title: 'Blue Water Bottle',
        description: 'Stainless steel hydro flask with campus stickers.',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.other,
        approximateLocation: 'Campus Recreation Center',
        reporterId: 'user_001',
        reporterName: 'Test Student',
        createdAt: DateTime.now(),
      );

      await itemRepository.addItem(newItem);

      final items = await itemRepository.getItems();
      expect(items.first.id, 'test_item_999');
      expect(items.first.title, 'Blue Water Bottle');
    });

    test('updates item status to reunited', () async {
      final newItem = Item(
        id: 'test_item_101',
        title: 'Sony Headphones',
        description: 'Black headphones',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.electronics,
        approximateLocation: 'Library',
        reporterId: 'user_001',
        reporterName: 'Alex',
        createdAt: DateTime.now(),
      );

      await itemRepository.addItem(newItem);
      await itemRepository.updateItemStatus('test_item_101', ItemStatus.reunited);

      final item = await itemRepository.getItemById('test_item_101');
      expect(item?.status, ItemStatus.reunited);
    });
  });
}
