import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../core/utils/pricing.dart';
import '../core/utils/promo.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/restaurant_model.dart';
import 'notification_service.dart';

/// Firestore-backed `orders` collection. Every list query filters on at
/// most one field and sorts on the client, so no composite index is needed.
class OrderService {
  OrderService({FirebaseFirestore? firestore, NotificationService? notifications})
      : _db = firestore ?? FirebaseFirestore.instance,
        _notifications = notifications ?? NotificationService();

  final FirebaseFirestore _db;
  final NotificationService _notifications;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection(Col.orders);

  List<FoodOrder> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => FoodOrder.fromFirestore(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<FoodOrder>> watchCustomerOrders(String customerId) =>
      _orders.where('customerId', isEqualTo: customerId).snapshots().map(_toSortedList);

  Stream<List<FoodOrder>> watchAllOrders() => _orders.snapshots().map(_toSortedList);

  Stream<FoodOrder?> watchOrder(String orderId) => _orders.doc(orderId).snapshots().map((snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return FoodOrder.fromFirestore(snap.id, data);
      });

  /// For a card payment, call this only after the charge has succeeded.
  Future<FoodOrder> placeOrder({
    required String customerId,
    required Restaurant restaurant,
    required List<CartItem> items,
    PaymentMethod paymentMethod = PaymentMethod.cashOnDelivery,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    double? deliveryLat,
    double? deliveryLng,
    String deliveryAddress = '',
    String deliveryNote = '',
    String? promoCode,
  }) async {
    final doc = _orders.doc();
    // Fees are computed here, from the items, so the amount stored on the
    // order always matches Pricing — the UI can't send a different total.
    final price = Pricing.of(items.fold<double>(0, (sum, i) => sum + i.subtotal));
    // The discount is recomputed from the code (never trusted from the UI);
    // an unknown or ineligible code simply gives 0.
    final discount = PromoCodes.discountFor(promoCode, price);
    final order = FoodOrder(
      id: doc.id,
      customerId: customerId,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      items: items,
      total: price.total - discount,
      subtotal: price.subtotal,
      deliveryFee: price.deliveryFee,
      serviceFee: price.serviceFee,
      discount: discount,
      promoCode: discount > 0 ? (PromoCodes.lookup(promoCode)?.code ?? '') : '',
      deliveryAddress: deliveryAddress,
      deliveryNote: deliveryNote,
      status: OrderStatus.pending,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: DateTime.now(),
      restaurantLat: restaurant.lat,
      restaurantLng: restaurant.lng,
      // Demo fallback: ~1.5 km from the restaurant when GPS isn't available.
      deliveryLat: deliveryLat ?? restaurant.lat + 0.01,
      deliveryLng: deliveryLng ?? restaurant.lng + 0.01,
    );
    await doc.set(order.toFirestore());
    return order;
  }

  /// The single place an order's status changes — admin panel and rider
  /// app both route through here, so one hook covers every notification.
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    final ref = _orders.doc(orderId);
    await ref.update({'status': status.name, 'updatedAt': FieldValue.serverTimestamp()});
    final snap = await ref.get();
    final data = snap.data();
    if (data != null) {
      await _notifications.notifyOrderStatus(FoodOrder.fromFirestore(snap.id, data));
    }
  }

  /// Customer cancels their own order while it is still `pending` (the
  /// restaurant hasn't started on it). firestore.rules enforce the same.
  /// Throws [StateError] if the order has already moved on.
  Future<void> cancelOrder(String orderId) async {
    final ref = _orders.doc(orderId);
    final snap = await ref.get();
    if (snap.data()?['status'] != OrderStatus.pending.name) {
      throw StateError('Only pending orders can be cancelled.');
    }
    await ref.update({'status': OrderStatus.cancelled.name, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Customer reports a problem; an admin handles it from order detail.
  Future<void> openDispute(String orderId, String reason) {
    return _orders.doc(orderId).update({
      'disputeStatus': DisputeStatus.open.name,
      'disputeReason': reason,
    });
  }

  /// Admin closes a dispute — refunding the customer or rejecting it.
  Future<void> resolveDispute({
    required String orderId,
    required bool refund,
    String? note,
  }) async {
    final ref = _orders.doc(orderId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final order = FoodOrder.fromFirestore(snap.id, data);
    final update = <String, dynamic>{
      'disputeStatus': (refund ? DisputeStatus.resolved : DisputeStatus.rejected).name,
      'disputeNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (refund && order.paymentStatus == PaymentStatus.succeeded) {
      update['paymentStatus'] = PaymentStatus.refunded.name;
    }
    await ref.update(update);
    await _notifications.notifyUser(
      userId: order.customerId,
      title: refund ? 'Dispute resolved' : 'Dispute update',
      body: refund
          ? 'Your report about ${order.restaurantName} was accepted.'
          : 'Your report about ${order.restaurantName} was reviewed and closed.',
    );
  }

  /// Admin refund outside of a dispute. Payments are simulated in this
  /// project, so this records the refund on the order.
  Future<void> refund(String orderId) async {
    final ref = _orders.doc(orderId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final order = FoodOrder.fromFirestore(snap.id, data);
    await ref.update({
      'paymentStatus': PaymentStatus.refunded.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifications.notifyUser(
      userId: order.customerId,
      title: 'Refund issued',
      body: 'Rs. ${order.total.toStringAsFixed(0)} for ${order.restaurantName} was refunded.',
    );
  }
}
