import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/features/chat/data/chat_repository.dart';
import 'package:finders_keepers/features/chat/domain/models/chat_message.dart';
import 'package:finders_keepers/features/claim/data/claim_repository.dart';
import 'package:finders_keepers/features/claim/domain/models/claim.dart';

void main() {
  group('ClaimRepository & Ownership Verification', () {
    late InMemoryClaimRepository claimRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      claimRepo = InMemoryClaimRepository();
    });

    test('initializes empty by default awaiting user claims', () async {
      final claims = await claimRepo.getClaimsForItem('item_105');
      expect(claims.isEmpty, true);
    });

    test('submits new ownership claim and retrieves it by item id', () async {
      final claim = Claim(
        id: 'claim_test_1',
        itemId: 'item_101',
        itemTitle: 'Sony WH-1000XM4',
        claimantId: 'user_test',
        claimantName: 'Taylor Morgan',
        claimantEmail: 'taylor@campus.edu',
        answers: {
          'What color is the pouch?': 'Matte black with bronze zipper',
        },
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      );

      await claimRepo.submitClaim(claim);
      final itemClaims = await claimRepo.getClaimsForItem('item_101');
      expect(itemClaims.any((c) => c.id == 'claim_test_1'), true);
    });

    test('updates claim status upon verification (approve/reject)', () async {
      final claim = Claim(
        id: 'claim_test_2',
        itemId: 'item_102',
        itemTitle: 'Leather Wallet',
        claimantId: 'user_002',
        claimantName: 'Riley CS',
        claimantEmail: 'riley@campus.edu',
        answers: {'Bank name?': 'Chase'},
        status: ClaimStatus.pending,
        createdAt: DateTime.now(),
      );

      await claimRepo.submitClaim(claim);
      await claimRepo.updateClaimStatus('claim_test_2', ClaimStatus.approved);

      final claimsAfterApprove = await claimRepo.getClaimsForItem('item_102');
      final target = claimsAfterApprove.firstWhere((c) => c.id == 'claim_test_2');
      expect(target.status, ClaimStatus.approved);
    });
  });

  group('ChatRepository & Secure In-App Handover', () {
    late InMemoryChatRepository chatRepo;

    setUp(() {
      chatRepo = InMemoryChatRepository();
    });

    test('sends message in post-verification channel', () async {
      final newMsg = ChatMessage(
        id: 'msg_test_01',
        claimId: 'claim_501',
        senderId: 'user_001',
        senderName: 'Alex Rivers',
        text: 'See you at the student desk!',
        timestamp: DateTime.now(),
      );

      final stream = chatRepo.getMessagesStream('claim_501');
      final expectation = expectLater(
        stream,
        emits(predicate<List<ChatMessage>>((list) =>
            list.any((m) => m.id == 'msg_test_01'))),
      );

      await chatRepo.sendMessage(newMsg);
      await expectation;
    });
  });
}
