import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/app_user.dart';

/// Abstract contract for authentication operations.
///
/// Designed so the app can run on an in-memory mock or Firebase Auth seamlessly.
abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<AppUser> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  });
  Future<void> signOut();
}

/// In-memory implementation of AuthRepository.
///
/// Provides instant, offline-capable authentication with pre-seeded demo credentials.
class InMemoryAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  // Registered students store
  final Map<String, (AppUser user, String password)> _users = {
    'student@campus.edu': (
      AppUser(
        uid: 'user_001',
        email: 'student@campus.edu',
        displayName: 'Alex Rivers',
        studentId: '24CS1092',
        isVerified: true,
        createdAt: DateTime(2026, 1, 10),
      ),
      'password123',
    ),
  };

  InMemoryAuthRepository() {
    // Initial state: not signed in
    _controller.add(null);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  /// Validates that the email belongs to a recognized campus domain.
  static String? validateCampusEmail(String email) {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Email is required';
    if (!trimmed.contains('@')) return 'Enter a valid email address';
    if (!trimmed.endsWith('.edu') && !trimmed.contains('campus') && !trimmed.contains('univ')) {
      return 'Please use your official campus email (.edu)';
    }
    return null;
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate brief network latency
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    final record = _users[normalizedEmail];

    if (record == null) {
      throw Exception('No student account found with this email.');
    }
    if (record.$2 != password) {
      throw Exception('Invalid password. Please check your credentials.');
    }

    _currentUser = record.$1;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      throw Exception('An account with this campus email already exists.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final newUser = AppUser(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: fullName.trim(),
      studentId: studentId.trim().toUpperCase(),
      isVerified: false,
      createdAt: DateTime.now(),
    );

    _users[normalizedEmail] = (newUser, password);
    _currentUser = newUser;
    _controller.add(_currentUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }
}

/// Global provider exposing the active AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return InMemoryAuthRepository();
});

/// Reactive stream of the currently authenticated user.
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Synchronous access to the current authenticated student.
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value;
});
