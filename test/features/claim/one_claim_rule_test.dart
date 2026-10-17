import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/claim/data/claim_repository.dart';
import 'package:finders_keepers/features/claim/domain/models/claim.dart';

void main() {
  group('One Claim Per User Lifecycle Verification', () {
    late InMemoryClaimRepository repo;

    setUp(() {
      repo = InMemoryClaimRepository();
    });

    test('enforces pending claim state and allows re-application after rejection', () async {
      const claimantId = 'student_test_123';
      const itemId = 'item_101';

      // 1. Submit initial claim
      final initialClaim = Claim(
        id: 'claim_init',
        itemId: itemId,
        itemTitle: 'Sony Headphones',
        claimantId: claimantId,
        claimantName: 'Test Student',
        claimantEmail: 'test@vitstudent.ac.in',
        answers: {'Q1': 'Black'},
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      );

      await repo.submitClaim(initialClaim);
      var claims = await repo.getClaimsForItem(itemId);
      var userClaims = claims.where((c) => c.claimantId == claimantId).toList();
      expect(userClaims.length, equals(1));
      expect(userClaims.last.status, equals(ClaimStatus.pending));

      // 2. Reject the claim
      await repo.updateClaimStatus(initialClaim.id, ClaimStatus.rejected);
      claims = await repo.getClaimsForItem(itemId);
      userClaims = claims.where((c) => c.claimantId == claimantId).toList();
      expect(userClaims.last.status, equals(ClaimStatus.rejected));

      // 3. User submits a revised claim after rejection
      final revisedClaim = Claim(
        id: 'claim_revised',
        itemId: itemId,
        itemTitle: 'Sony Headphones',
        claimantId: claimantId,
        claimantName: 'Test Student',
        claimantEmail: 'test@vitstudent.ac.in',
        answers: {'Q1': 'Black carrying pouch with gold zipper'},
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      );

      await repo.submitClaim(revisedClaim);
      claims = await repo.getClaimsForItem(itemId);
      userClaims = claims.where((c) => c.claimantId == claimantId).toList();
      expect(userClaims.first.id, equals('claim_revised'));
      expect(userClaims.first.status, equals(ClaimStatus.pending));

      // 4. Finder approves revised claim
      await repo.updateClaimStatus(revisedClaim.id, ClaimStatus.approved);
      claims = await repo.getClaimsForItem(itemId);
      userClaims = claims.where((c) => c.claimantId == claimantId).toList();
      expect(userClaims.first.status, equals(ClaimStatus.approved));
    });
  });
}
