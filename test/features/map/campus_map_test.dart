import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';
import 'package:finders_keepers/features/item/presentation/widgets/campus_map_explorer.dart';

void main() {
  group('Campus Landmarks and Map Matcher', () {
    test('contains all expected campus landmarks', () {
      expect(kCampusLandmarks.isNotEmpty, isTrue);
      expect(kCampusLandmarks.any((l) => l.id == 'library'), isTrue);
      expect(kCampusLandmarks.any((l) => l.id == 'food_court'), isTrue);
      expect(kCampusLandmarks.any((l) => l.id == 'engineering'), isTrue);
      expect(kCampusLandmarks.any((l) => l.id == 'science'), isTrue);
      expect(kCampusLandmarks.any((l) => l.id == 'gym'), isTrue);
    });

    test('correctly matches item location strings to campus landmarks', () {
      final libraryItem = Item(
        id: 'test_1',
        title: 'Notebook',
        description: 'Spiral notebook',
        type: ItemType.lost,
        status: ItemStatus.open,
        category: ItemCategory.bagsBooks,
        approximateLocation: 'Main Library • 2nd Floor',
        reporterId: 'user_1',
        reporterName: 'Student',
        createdAt: DateTime.now(),
        verificationQuestions: [],
      );

      final foodCourtItem = Item(
        id: 'test_2',
        title: 'Water Bottle',
        description: 'Metal flask',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.other,
        approximateLocation: 'Student Union Building • Food Court',
        reporterId: 'user_2',
        reporterName: 'Student',
        createdAt: DateTime.now(),
        verificationQuestions: [],
      );

      // Verify keyword matchers
      final libMatch = kCampusLandmarks.firstWhere((lm) =>
          lm.keywords.any((kw) => libraryItem.approximateLocation.toLowerCase().contains(kw)));
      expect(libMatch.id, equals('library'));

      final fcMatch = kCampusLandmarks.firstWhere((lm) =>
          lm.keywords.any((kw) => foodCourtItem.approximateLocation.toLowerCase().contains(kw)));
      expect(fcMatch.id, equals('food_court'));
    });
  });
}
