import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/auth/data/auth_repository.dart';

void main() {
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
  });
}
