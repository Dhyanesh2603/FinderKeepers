import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/item/data/item_repository.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';

void main() {
  group('ItemRepository and Feed Logic', () {
    late InMemoryItemRepository itemRepository;

    setUp(() {
      itemRepository = InMemoryItemRepository();
    });

    test('initializes with seed campus items', () async {
      final items = await itemRepository.getItems();
      expect(items.isNotEmpty, true);
      expect(items.any((i) => i.type == ItemType.lost), true);
      expect(items.any((i) => i.type == ItemType.found), true);
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
      await itemRepository.updateItemStatus('item_101', ItemStatus.reunited);

      final item = await itemRepository.getItemById('item_101');
      expect(item?.status, ItemStatus.reunited);
    });
  });
}
