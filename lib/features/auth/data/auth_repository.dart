import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// In-memory implementation of AuthRepository backed by persistent disk storage (SharedPreferences).
///
/// All registered accounts survive logouts, application restarts, and process recreation.
class InMemoryAuthRepository implements AuthRepository {
  static const String _persistedUsersKey = 'finders_keepers_accounts_db_v2';
  static const String _persistedSessionKey = 'finders_keepers_session_uid_v2';

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  final Completer<void> _loadCompleter = Completer<void>();

  // Registered students store (pre-seeded with demo account)
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
    _loadFromStorage();
  }

  Future<void> _ensureLoaded() async {
    if (!_loadCompleter.isCompleted) {
      await _loadCompleter.future;
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistedUsersKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        for (final entry in decoded.entries) {
          final accountData = Map<String, dynamic>.from(entry.value as Map);
          final userMap = Map<String, dynamic>.from(accountData['user'] as Map);
          final password = accountData['password'] as String;
          final user = AppUser.fromMap(
            userMap,
            userMap['uid'] as String? ?? entry.key,
          );
          _users[entry.key.toLowerCase()] = (user, password);
        }
      }

      // Check for active persisted session
      final activeEmail = prefs.getString(_persistedSessionKey);
      if (activeEmail != null && _users.containsKey(activeEmail.toLowerCase())) {
        _currentUser = _users[activeEmail.toLowerCase()]?.$1;
        _controller.add(_currentUser);
      } else {
        _controller.add(null);
      }
    } catch (_) {
      _controller.add(null);
    } finally {
      if (!_loadCompleter.isCompleted) {
        _loadCompleter.complete();
      }
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      for (final entry in _users.entries) {
        map[entry.key] = {
          'user': entry.value.$1.toMap(),
          'password': entry.value.$2,
        };
      }
      await prefs.setString(_persistedUsersKey, jsonEncode(map));
    } catch (_) {}
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
    await _ensureLoaded();
    // Simulate brief network latency
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    final record = _users[normalizedEmail];

    if (record == null) {
      throw Exception('No student account found with this email. Please check your credentials or register.');
    }
    if (record.$2 != password) {
      throw Exception('Invalid password. Please check your credentials.');
    }

    _currentUser = record.$1;
    _controller.add(_currentUser);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistedSessionKey, normalizedEmail);
    } catch (_) {}

    return _currentUser!;
  }

  @override
  Future<AppUser> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
  }) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 300));

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

    await _saveToStorage();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistedSessionKey, normalizedEmail);
    } catch (_) {}

    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _controller.add(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistedSessionKey);
    } catch (_) {}
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
