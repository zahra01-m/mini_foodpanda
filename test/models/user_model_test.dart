import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/models/user_model.dart';

void main() {
  group('AppUser', () {
    test('toFirestore/fromFirestore round-trip', () {
      const user = AppUser(
        id: 'uid-1',
        name: 'Alia',
        email: 'alia@example.com',
        phone: '0300-0000000',
        role: UserRole.rider,
        isApproved: false,
      );
      final data = user.toFirestore();
      final restored = AppUser.fromFirestore('uid-1', data);
      expect(restored.name, 'Alia');
      expect(restored.role, UserRole.rider);
      expect(restored.isApproved, false);
    });

    test('fromFirestore treats a missing isApproved as true', () {
      final restored = AppUser.fromFirestore('uid-2', {
        'name': 'Admin User',
        'email': 'admin@example.com',
        'phone': '0300-1111111',
        'role': 'admin',
      });
      expect(restored.isApproved, true);
      expect(restored.role, UserRole.admin);
    });

    test('UserRoleX.fromId falls back to customer for an unknown value', () {
      expect(UserRoleX.fromId('bogus'), UserRole.customer);
      expect(UserRoleX.fromId('rider'), UserRole.rider);
    });

    test('copyWith only changes given fields', () {
      const user = AppUser(id: 'u1', name: 'A', email: 'a@a.com', phone: '1', role: UserRole.customer);
      final updated = user.copyWith(isApproved: false);
      expect(updated.id, 'u1');
      expect(updated.name, 'A');
      expect(updated.isApproved, false);
    });
  });
}
