import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/user_model.dart';
import 'package:mini_foodpanda/services/auth_service.dart';

void main() {
  test('updateProfile changes name and phone but never the role', () async {
    final firestore = FakeFirebaseFirestore();
    final service = AuthService(auth: MockFirebaseAuth(), firestore: firestore);
    final user = await service.signUp(
      name: 'Alia',
      email: 'alia@example.com',
      password: 'password123',
      phone: '0300-0000000',
      role: UserRole.customer,
    );

    await service.updateProfile(uid: user.id, name: 'Alia Khan', phone: '0311-1111111');

    final doc = await firestore.collection('users').doc(user.id).get();
    expect(doc.data()!['name'], 'Alia Khan');
    expect(doc.data()!['phone'], '0311-1111111');
    expect(doc.data()!['role'], 'customer');
  });
}
