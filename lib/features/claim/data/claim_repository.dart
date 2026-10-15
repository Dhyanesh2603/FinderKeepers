import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/claim.dart';

/// Abstract contract for ownership claims management.
abstract class ClaimRepository {
  Stream<List<Claim>> get claimsStream;
  Future<List<Claim>> getClaimsForItem(String itemId);
  Future<List<Claim>> getClaimsForStudent(String studentId);
  Future<void> submitClaim(Claim claim);
  Future<void> updateClaimStatus(String claimId, ClaimStatus status);
}

/// In-memory implementation of ClaimRepository.
class InMemoryClaimRepository implements ClaimRepository {
  final _controller = StreamController<List<Claim>>.broadcast();

  final List<Claim> _claims = [
    Claim(
      id: 'claim_501',
      itemId: 'item_105',
      itemTitle: 'Apple AirPods Pro in Matte Black Case',
      claimantId: 'user_001',
      claimantName: 'Alex Rivers',
      claimantEmail: 'student@campus.edu',
      answers: {
        'What engraving or custom text appears on the case lid?':
            'Engraved with initials "A.R." on the front lid.',
      },
      status: ClaimStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  InMemoryClaimRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_claims));
  }

  @override
  Stream<List<Claim>> get claimsStream => _controller.stream;

  @override
  Future<List<Claim>> getClaimsForItem(String itemId) async {
    return _claims.where((c) => c.itemId == itemId).toList();
  }

  @override
  Future<List<Claim>> getClaimsForStudent(String studentId) async {
    return _claims.where((c) => c.claimantId == studentId).toList();
  }

  @override
  Future<void> submitClaim(Claim claim) async {
    _claims.insert(0, claim);
    _emit();
  }

  @override
  Future<void> updateClaimStatus(String claimId, ClaimStatus status) async {
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index != -1) {
      final old = _claims[index];
      _claims[index] = Claim(
        id: old.id,
        itemId: old.itemId,
        itemTitle: old.itemTitle,
        claimantId: old.claimantId,
        claimantName: old.claimantName,
        claimantEmail: old.claimantEmail,
        answers: old.answers,
        status: status,
        createdAt: old.createdAt,
      );
      _emit();
    }
  }
}

final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  return InMemoryClaimRepository();
});

final claimsStreamProvider = StreamProvider<List<Claim>>((ref) {
  final repo = ref.watch(claimRepositoryProvider);
  return repo.claimsStream;
});

final claimsForItemProvider = Provider.family<List<Claim>, String>((ref, itemId) {
  final claims = ref.watch(claimsStreamProvider).value ?? [];
  return claims.where((c) => c.itemId == itemId).toList();
});
