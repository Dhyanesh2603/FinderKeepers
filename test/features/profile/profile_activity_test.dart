import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';
import 'package:finders_keepers/features/item/data/item_repository.dart';
import 'package:finders_keepers/features/claim/domain/models/claim.dart';
import 'package:finders_keepers/features/claim/data/claim_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile Activity & Data Persistence', () {
    test('ItemRepository saves and separates lost vs found items for profile', () async {
      final repo = InMemoryItemRepository();

      final lostItem = Item(
        id: 'test_lost_999',
        title: 'Lost Silver Watch',
        description: 'Lost during sports practice',
        type: ItemType.lost,
        status: ItemStatus.open,
        category: ItemCategory.other,
        approximateLocation: 'Sports Complex • Track',
        reporterId: 'user_001',
        reporterName: 'Alex Rivers',
        createdAt: DateTime.now(),
      );

      final foundItem = Item(
        id: 'test_found_888',
        title: 'Found Blue Umbrella',
        description: 'Left by the bench',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.other,
        approximateLocation: 'Main Library • Lobby',
        reporterId: 'user_001',
        reporterName: 'Alex Rivers',
        createdAt: DateTime.now(),
      );

      await repo.addItem(lostItem);
      await repo.addItem(foundItem);

      final items = await repo.getItems();
      final myLost = items.where((i) => i.reporterId == 'user_001' && i.type == ItemType.lost).toList();
      final myFound = items.where((i) => i.reporterId == 'user_001' && i.type == ItemType.found).toList();

      expect(myLost.any((i) => i.id == 'test_lost_999'), isTrue);
      expect(myFound.any((i) => i.id == 'test_found_888'), isTrue);
    });

    test('ClaimRepository correctly submits and persists ownership claims', () async {
      final repo = InMemoryClaimRepository();

      final claim = Claim(
        id: 'claim_test_777',
        itemId: 'item_101',
        itemTitle: 'Sony Headphones',
        claimantId: 'user_001',
        claimantName: 'Alex Rivers',
        claimantEmail: 'student@campus.edu',
        answers: {'Color?': 'Black'},
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      );

      await repo.submitClaim(claim);

      final studentClaims = await repo.getClaimsForStudent('user_001');
      expect(studentClaims.any((c) => c.id == 'claim_test_777'), isTrue);
    });
  });
}
