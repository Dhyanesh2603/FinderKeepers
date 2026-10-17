import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/features/auth/data/auth_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository and Campus Validation', () {
    late InMemoryAuthRepository authRepository;

    setUp(() {
      authRepository = InMemoryAuthRepository();
    });

    test('validates campus email domain correctly', () {
      expect(InMemoryAuthRepository.validateCampusEmail(''), 'Email is required');
      expect(
        InMemoryAuthRepository.validateCampusEmail('user@gmail.com'),
        'Please use your official campus email (.edu)',
      );
      expect(
        InMemoryAuthRepository.validateCampusEmail('student@university.edu'),
        isNull,
      );
    });

    test('signs in pre-seeded demo student successfully', () async {
      final user = await authRepository.signInWithEmailAndPassword(
        email: 'student@campus.edu',
        password: 'password123',
      );

      expect(user.email, 'student@campus.edu');
      expect(user.displayName, 'Alex Rivers');
      expect(user.studentId, '24CS1092');
      expect(authRepository.currentUser, isNotNull);
    });

    test('fails sign in with wrong password', () async {
      expect(
        () => authRepository.signInWithEmailAndPassword(
          email: 'student@campus.edu',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('registers a new campus student and signs them in', () async {
      final newUser = await authRepository.registerStudent(
        email: 'jordan@campus.edu',
        password: 'password456',
        fullName: 'Jordan Smith',
        studentId: '24CS2001',
      );

      expect(newUser.email, 'jordan@campus.edu');
      expect(newUser.displayName, 'Jordan Smith');
      expect(authRepository.currentUser?.uid, newUser.uid);
    });

    test('newly registered account can log back in after logout', () async {
      await authRepository.registerStudent(
        email: 'priya@campus.edu',
        password: 'securepass123',
        fullName: 'Priya Sharma',
        studentId: '24EE1045',
      );

      // Student logs out
      await authRepository.signOut();
      expect(authRepository.currentUser, isNull);

      // Student logs back in with the same registered credentials
      final loggedInUser = await authRepository.signInWithEmailAndPassword(
        email: 'priya@campus.edu',
        password: 'securepass123',
      );

      expect(loggedInUser.email, 'priya@campus.edu');
      expect(loggedInUser.displayName, 'Priya Sharma');
      expect(loggedInUser.studentId, '24EE1045');
      expect(authRepository.currentUser?.email, 'priya@campus.edu');
    });

    test('persists registered accounts across repository restarts (simulating app restart)', () async {
      await authRepository.registerStudent(
        email: 'dev@campus.edu',
        password: 'mypassword789',
        fullName: 'Dev Patel',
        studentId: '24IT5521',
      );

      // Student signs out
      await authRepository.signOut();

      // Simulate app restart by instantiating a completely new InMemoryAuthRepository
      final freshRepository = InMemoryAuthRepository();

      // Sign in from the new repository instance
      final user = await freshRepository.signInWithEmailAndPassword(
        email: 'dev@campus.edu',
        password: 'mypassword789',
      );

      expect(user.email, 'dev@campus.edu');
      expect(user.displayName, 'Dev Patel');
      expect(user.studentId, '24IT5521');
    });
  });
}
