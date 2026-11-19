import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../models/order_model.dart';

/// An in-app notification stored in `notifications/{id}`.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> d) {
    return AppNotification(
      id: id,
      userId: (d['userId'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      createdAt: readDate(d['createdAt']),
      read: (d['read'] as bool?) ?? false,
    );
  }
}

/// Order updates are written to the customer's `notifications` inbox in
/// Firestore, so they arrive in real time on the customer's device and
/// survive app restarts. This is the free alternative to FCM push:
/// real OS-level push to a closed app needs a server (Cloud Functions),
/// which is only on Firebase's paid plan.
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.notifications);

  Stream<List<AppNotification>> watchFor(String userId) =>
      _col.where('userId', isEqualTo: userId).snapshots().map((snap) {
        final list = snap.docs.map((d) => AppNotification.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> notifyUser({required String userId, required String title, required String body}) {
    return _col.add({
      'userId': userId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Called from [OrderService.updateStatus] — every status change (admin
  /// panel, rider pickup/delivery) routes through that one method.
  Future<void> notifyOrderStatus(FoodOrder order) async {
    final String title;
    final String body;
    switch (order.status) {
      case OrderStatus.preparing:
        title = 'Order confirmed';
        body = '${order.restaurantName} started preparing your order.';
      case OrderStatus.outForDelivery:
        title = 'On the way';
        body = 'Your order from ${order.restaurantName} is out for delivery.';
      case OrderStatus.delivered:
        title = 'Delivered';
        body = 'Your order from ${order.restaurantName} has arrived. Enjoy!';
      case OrderStatus.cancelled:
        title = 'Order cancelled';
        body = 'Your order from ${order.restaurantName} was cancelled.';
      case OrderStatus.pending:
        return;
    }
    await notifyUser(userId: order.customerId, title: title, body: body);
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
