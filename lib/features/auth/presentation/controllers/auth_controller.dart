import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

/// Manages authentication action states (idle, loading, error).
class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is idle
    return null;
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmailAndPassword(email: email, password: password);
    });
    return !state.hasError;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        studentId: studentId,
      );
    });
    return !state.hasError;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
    });
  }
}

/// Provider managing auth button loading and error states.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
