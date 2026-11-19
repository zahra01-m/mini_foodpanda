import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/user_model.dart';
import 'package:mini_foodpanda/services/auth_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late AuthService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
    service = AuthService(auth: auth, firestore: firestore);
  });

  group('signUp', () {
    test('creates a customer profile that is approved by default', () async {
      final user = await service.signUp(
        name: 'Alia',
        email: 'alia@example.com',
        password: 'password123',
        phone: '0300-0000000',
        role: UserRole.customer,
      );
      expect(user.isApproved, true);
      final doc = await firestore.collection('users').doc(user.id).get();
      expect(doc.data()!['role'], 'customer');
    });

    test('creates a rider profile that starts unapproved', () async {
      final user = await service.signUp(
        name: 'Rider Bob',
        email: 'bob@example.com',
        password: 'password123',
        phone: '0300-1111111',
        role: UserRole.rider,
      );
      expect(user.isApproved, false);
      final doc = await firestore.collection('users').doc(user.id).get();
      expect(doc.data()!['isApproved'], false);
    });
  });

  group('login', () {
    test('returns the profile when the role matches', () async {
      await service.signUp(
        name: 'Admin',
        email: 'admin@example.com',
        password: 'password123',
        phone: '0300-2222222',
        role: UserRole.admin,
      );
      final user = await service.login(email: 'admin@example.com', password: 'password123', role: UserRole.admin);
      expect(user.name, 'Admin');
    });

    test('throws wrong-role when logging in under a different role than signed up', () async {
      await service.signUp(
        name: 'Customer One',
        email: 'cust@example.com',
        password: 'password123',
        phone: '0300-3333333',
        role: UserRole.customer,
      );
      expect(
        () => service.login(email: 'cust@example.com', password: 'password123', role: UserRole.rider),
        throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'wrong-role')),
      );
    });
  });

  group('currentUser', () {
    test('returns null when nobody is signed in', () async {
      expect(await service.currentUser(), isNull);
    });

    test('returns the profile for whoever is currently signed in', () async {
      final signedUp = await service.signUp(
        name: 'Signed In',
        email: 'signedin@example.com',
        password: 'password123',
        phone: '0300-4444444',
        role: UserRole.customer,
      );
      final current = await service.currentUser();
      expect(current, isNotNull);
      expect(current!.id, signedUp.id);
    });
  });

  group('messageFor', () {
    test('maps known FirebaseAuthException codes to friendly messages', () {
      expect(
        AuthService.messageFor(FirebaseAuthException(code: 'email-already-in-use')),
        contains('already registered'),
      );
      expect(
        AuthService.messageFor(FirebaseAuthException(code: 'weak-password')),
        contains('6 characters'),
      );
      expect(
        AuthService.messageFor(FirebaseAuthException(code: 'wrong-password')),
        contains('Incorrect email or password'),
      );
    });

    test('falls back to toString for a non-auth error', () {
      expect(AuthService.messageFor('boom'), 'boom');
    });
  });
}
