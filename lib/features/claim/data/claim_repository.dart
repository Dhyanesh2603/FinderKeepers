import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/claim.dart';

/// Abstract contract for ownership claims management.
abstract class ClaimRepository {
  Stream<List<Claim>> get claimsStream;
  Future<List<Claim>> getClaimsForItem(String itemId);
  Future<List<Claim>> getClaimsForStudent(String studentId);
  Future<void> submitClaim(Claim claim);
  Future<void> updateClaimStatus(String claimId, ClaimStatus status);
  Future<void> clearAllClaims();
}

/// In-memory implementation of ClaimRepository backed purely by SharedPreferences persistence.
/// Starts completely empty — only claims submitted by the user are saved and tracked.
class InMemoryClaimRepository implements ClaimRepository {
  static const String _persistedClaimsKey = 'finders_keepers_claims_v3';
  final _controller = StreamController<List<Claim>>.broadcast();

  final List<Claim> _claims = [];

  InMemoryClaimRepository() {
    _emit();
    _loadFromStorage();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_claims));
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistedClaimsKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        final loadedClaims = decoded
            .map((e) => Claim.fromJson(e as Map<String, dynamic>))
            .toList();

        _claims.clear();
        _claims.addAll(loadedClaims);
        _emit();
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_claims.map((c) => c.toJson()).toList());
      await prefs.setString(_persistedClaimsKey, encoded);
    } catch (_) {}
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
    await _saveToStorage();
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
      await _saveToStorage();
    }
  }

  @override
  Future<void> clearAllClaims() async {
    _claims.clear();
    _emit();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistedClaimsKey);
    } catch (_) {}
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
