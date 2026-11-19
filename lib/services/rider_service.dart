import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../models/order_model.dart';
import 'order_service.dart';

/// Order-queue and delivery actions for the rider app, backed by the
/// same `orders` collection the customer and admin read — accepting an
/// order here shows up on both instantly through Firestore listeners.
class RiderService {
  RiderService({FirebaseFirestore? firestore, OrderService? orders})
      : _db = firestore ?? FirebaseFirestore.instance,
        _orders = orders ?? OrderService();

  final FirebaseFirestore _db;
  final OrderService _orders;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(Col.orders);

  List<FoodOrder> _parse(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => FoodOrder.fromFirestore(d.id, d.data())).toList();

  /// Orders a restaurant has started preparing but no rider has claimed.
  Stream<List<FoodOrder>> watchIncomingRequests() =>
      _col.where('status', isEqualTo: OrderStatus.preparing.name).snapshots().map((snap) {
        final list = _parse(snap).where((o) => o.riderId == null).toList();
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      });

  /// This rider's current in-progress delivery, if any.
  Stream<FoodOrder?> watchActiveDelivery(String riderId) =>
      _col.where('riderId', isEqualTo: riderId).snapshots().map((snap) {
        for (final o in _parse(snap)) {
          if (o.status == OrderStatus.preparing || o.status == OrderStatus.outForDelivery) {
            return o;
          }
        }
        return null;
      });

  Stream<List<FoodOrder>> watchHistory(String riderId) =>
      _col.where('riderId', isEqualTo: riderId).snapshots().map((snap) {
        final list = _parse(snap).where((o) => o.status == OrderStatus.delivered).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  /// Simple flat-commission earnings model.
  static double earningsOf(List<FoodOrder> history, {double commissionRate = 0.12}) =>
      history.fold<double>(0, (sum, o) => sum + o.total * commissionRate);

  /// Claims an order in a transaction so two riders can't both accept it.
  /// Returns false if someone else got there first.
  Future<bool> acceptOrder({required String orderId, required String riderId}) {
    final ref = _col.doc(orderId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) return false;
      final order = FoodOrder.fromFirestore(snap.id, data);
      if (order.riderId != null || order.status != OrderStatus.preparing) return false;
      tx.update(ref, {'riderId': riderId, 'updatedAt': FieldValue.serverTimestamp()});
      return true;
    });
  }

  Future<void> markPickedUp(String orderId) =>
      _orders.updateStatus(orderId, OrderStatus.outForDelivery);

  Future<void> markDelivered(String orderId) =>
      _orders.updateStatus(orderId, OrderStatus.delivered);
}
