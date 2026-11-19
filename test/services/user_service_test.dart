import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/user_model.dart';
import 'package:mini_foodpanda/services/user_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = UserService(firestore: firestore);
  });

  group('watchUser', () {
    test('emits null for a user that does not exist', () async {
      final user = await service.watchUser('nobody').first;
      expect(user, isNull);
    });

    test('emits the user\'s profile once it exists', () async {
      await firestore.collection('users').doc('u1').set(
            const AppUser(id: 'u1', name: 'Alia', email: 'a@a.com', phone: '1', role: UserRole.customer)
                .toFirestore(),
          );
      final user = await service.watchUser('u1').first;
      expect(user!.name, 'Alia');
    });
  });

  group('watchRiders', () {
    test('only returns rider accounts, sorted by name', () async {
      await firestore.collection('users').doc('u1').set(
            const AppUser(id: 'u1', name: 'Zed Rider', email: 'z@a.com', phone: '1', role: UserRole.rider).toFirestore(),
          );
      await firestore.collection('users').doc('u2').set(
            const AppUser(id: 'u2', name: 'Amy Rider', email: 'a@a.com', phone: '2', role: UserRole.rider).toFirestore(),
          );
      await firestore.collection('users').doc('u3').set(
            const AppUser(id: 'u3', name: 'Some Customer', email: 'c@a.com', phone: '3', role: UserRole.customer)
                .toFirestore(),
          );
      final riders = await service.watchRiders().first;
      expect(riders.map((r) => r.name).toList(), ['Amy Rider', 'Zed Rider']);
    });
  });

  group('setApproved', () {
    test('flips the isApproved flag for that user only', () async {
      await firestore.collection('users').doc('u1').set(
            const AppUser(id: 'u1', name: 'Rider One', email: 'r1@a.com', phone: '1', role: UserRole.rider, isApproved: false)
                .toFirestore(),
          );
      await service.setApproved('u1', true);
      final doc = await firestore.collection('users').doc('u1').get();
      expect(doc.data()!['isApproved'], true);
    });
  });
}
