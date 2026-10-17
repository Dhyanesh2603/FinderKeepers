import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';
import 'package:finders_keepers/features/notifications/data/match_engine.dart';

void main() {
  group('MatchEngine & Similarity Scoring', () {
    test('computes high confidence match for same category, location, and keywords', () {
      final now = DateTime.now();

      final lostItem = Item(
        id: 'lost_01',
        title: 'Lost Apple AirPods Pro in black case',
        description: 'Lost my black AirPods in the main library quiet zone',
        type: ItemType.lost,
        status: ItemStatus.open,
        category: ItemCategory.electronics,
        approximateLocation: 'Main Library • 3rd Floor Quiet Zone',
        reporterId: 'user_1',
        reporterName: 'Alex',
        createdAt: now,
      );

      final foundItem = Item(
        id: 'found_01',
        title: 'Found Apple AirPods in matte black case',
        description: 'Found headphones on desk in library 3rd floor',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.electronics,
        approximateLocation: 'Main Library • 3rd Floor Quiet Zone',
        reporterId: 'user_2',
        reporterName: 'Jordan',
        createdAt: now.add(const Duration(hours: 2)),
      );

      final matches = MatchEngine.computeMatches([lostItem, foundItem]);

      expect(matches.isNotEmpty, true);
      final topMatch = matches.first;
      expect(topMatch.confidenceScore >= 70, true);
      expect(topMatch.rationale.contains('Same category'), true);
      expect(topMatch.rationale.contains('Exact landmark match'), true);
    });

    test('ignores items that have different categories and locations', () {
      final now = DateTime.now();

      final lostBook = Item(
        id: 'lost_02',
        title: 'Chemistry Textbook',
        description: 'Hardcover chemistry book',
        type: ItemType.lost,
        status: ItemStatus.open,
        category: ItemCategory.bagsBooks,
        approximateLocation: 'Science Center • Lecture Hall B',
        reporterId: 'user_1',
        reporterName: 'Alex',
        createdAt: now,
      );

      final foundKeys = Item(
        id: 'found_02',
        title: 'Dorm Keys on lanyard',
        description: 'Three brass keys found on treadmill',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.keys,
        approximateLocation: 'Campus Recreation Center • Gym',
        reporterId: 'user_2',
        reporterName: 'Jordan',
        createdAt: now,
      );

      final matches = MatchEngine.computeMatches([lostBook, foundKeys]);
      expect(matches.isEmpty, true);
    });
  });
}
