enum UserRole { customer, rider, admin }

extension UserRoleX on UserRole {
  String get id => name; // customer / rider / admin — matches Firestore `role` field

  static UserRole fromId(String id) => UserRole.values.firstWhere(
        (r) => r.name == id,
        orElse: () => UserRole.customer,
      );
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Riders start unapproved and need an admin to approve them before
  /// they can take orders. A missing field counts as approved so accounts
  /// created before this feature keep working.
  final bool isApproved;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isApproved = true,
  });

  AppUser copyWith({String? name, String? email, String? phone, UserRole? role, bool? isApproved}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  /// Matches the `users/{uid}` Firestore document shape from the project spec:
  /// uid, role, name, phone, createdAt (createdAt is set with a server
  /// timestamp on write and isn't needed back on the client model).
  Map<String, dynamic> toFirestore() => {
        'uid': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.id,
        'isApproved': isApproved,
      };

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      id: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      role: UserRoleX.fromId((data['role'] as String?) ?? 'customer'),
      isApproved: (data['isApproved'] as bool?) ?? true,
    );
  }
}
