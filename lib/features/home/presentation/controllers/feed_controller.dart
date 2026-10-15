import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finders_keepers/features/item/data/item_repository.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';

/// Manages active filter for item listing type (All, Lost, or Found).
class SelectedTypeNotifier extends Notifier<ItemType?> {
  @override
  ItemType? build() => null;

  void select(ItemType? type) => state = type;
}

final selectedTypeFilterProvider =
    NotifierProvider<SelectedTypeNotifier, ItemType?>(SelectedTypeNotifier.new);

/// Manages active filter for item category (All, Electronics, etc.).
class SelectedCategoryNotifier extends Notifier<ItemCategory> {
  @override
  ItemCategory build() => ItemCategory.all;

  void select(ItemCategory category) => state = category;
}

final selectedCategoryFilterProvider =
    NotifierProvider<SelectedCategoryNotifier, ItemCategory>(SelectedCategoryNotifier.new);

/// Manages real-time search query string.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Computed provider returning items matching all active filter criteria.
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final itemsAsync = ref.watch(itemsStreamProvider);
  final items = itemsAsync.value ?? [];

  final selectedType = ref.watch(selectedTypeFilterProvider);
  final selectedCategory = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  return items.where((item) {
    // 1. Type Filter (null means Show All)
    if (selectedType != null && item.type != selectedType) {
      return false;
    }

    // 2. Category Filter
    if (selectedCategory != ItemCategory.all && item.category != selectedCategory) {
      return false;
    }

    // 3. Search Query Filter
    if (searchQuery.isNotEmpty) {
      final inTitle = item.title.toLowerCase().contains(searchQuery);
      final inDesc = item.description.toLowerCase().contains(searchQuery);
      final inLocation = item.approximateLocation.toLowerCase().contains(searchQuery);
      if (!inTitle && !inDesc && !inLocation) {
        return false;
      }
    }

    return true;
  }).toList();
});
