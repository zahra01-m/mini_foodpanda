import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import 'cart_item_model.dart';
import 'payment_model.dart';
import 'restaurant_model.dart';

enum OrderStatus { pending, preparing, outForDelivery, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A customer-raised problem with an order, handled by an admin.
enum DisputeStatus { none, open, resolved, rejected }

extension DisputeStatusLabel on DisputeStatus {
  String get label {
    switch (this) {
      case DisputeStatus.none:
        return 'No dispute';
      case DisputeStatus.open:
        return 'Dispute open';
      case DisputeStatus.resolved:
        return 'Dispute resolved';
      case DisputeStatus.rejected:
        return 'Dispute rejected';
    }
  }
}

T _enumByName<T extends Enum>(List<T> values, dynamic name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

class FoodOrder {
  final String id;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String? riderId;
  final List<CartItem> items;
  final double total;

  /// Food-only amount, delivery fee and service fee; `total` is their sum.
  /// Orders placed before fees existed have subtotal 0 — use [itemsTotal].
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;

  /// Promo discount already taken off [total] (0 when no code was used).
  final double discount;
  final String promoCode;

  /// Typed address and optional note for the rider.
  final String deliveryAddress;
  final String deliveryNote;

  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  /// Where the food is coming from / going to — copied onto the order so
  /// the tracking map doesn't need extra reads.
  final double restaurantLat;
  final double restaurantLng;
  final double deliveryLat;
  final double deliveryLng;

  final DisputeStatus disputeStatus;
  final String? disputeReason;
  final String? disputeNote;

  const FoodOrder({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    this.riderId,
    required this.items,
    required this.total,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.serviceFee = 0,
    this.discount = 0,
    this.promoCode = '',
    this.deliveryAddress = '',
    this.deliveryNote = '',
    required this.status,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.restaurantLat = Restaurant.defaultLat,
    this.restaurantLng = Restaurant.defaultLng,
    this.deliveryLat = Restaurant.defaultLat + 0.01,
    this.deliveryLng = Restaurant.defaultLng + 0.01,
    this.disputeStatus = DisputeStatus.none,
    this.disputeReason,
    this.disputeNote,
  });

  /// Kept for anything still checking a simple paid/unpaid flag —
  /// derives from [paymentStatus] rather than storing its own bit.
  /// What the restaurant earned from food (excludes our fees).
  double get itemsTotal => subtotal > 0 ? subtotal : total;

  bool get isPaid => paymentStatus == PaymentStatus.succeeded;

  /// Cancelled or refunded orders don't count towards revenue.
  bool get countsAsRevenue =>
      status != OrderStatus.cancelled && paymentStatus != PaymentStatus.refunded;

  FoodOrder copyWith({
    OrderStatus? status,
    String? riderId,
    PaymentStatus? paymentStatus,
  }) {
    return FoodOrder(
      id: id,
      customerId: customerId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      riderId: riderId ?? this.riderId,
      items: items,
      total: total,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      promoCode: promoCode,
      deliveryAddress: deliveryAddress,
      deliveryNote: deliveryNote,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      restaurantLat: restaurantLat,
      restaurantLng: restaurantLng,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      disputeStatus: disputeStatus,
      disputeReason: disputeReason,
      disputeNote: disputeNote,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'customerId': customerId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'riderId': riderId,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'discount': discount,
        'promoCode': promoCode,
        'deliveryAddress': deliveryAddress,
        'deliveryNote': deliveryNote,
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'restaurantLat': restaurantLat,
        'restaurantLng': restaurantLng,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'disputeStatus': disputeStatus.name,
        'disputeReason': disputeReason,
        'disputeNote': disputeNote,
      };

  factory FoodOrder.fromFirestore(String id, Map<String, dynamic> d) {
    final rawItems = (d['items'] as List?) ?? const [];
    return FoodOrder(
      id: id,
      customerId: (d['customerId'] as String?) ?? '',
      restaurantId: (d['restaurantId'] as String?) ?? '',
      restaurantName: (d['restaurantName'] as String?) ?? '',
      riderId: d['riderId'] as String?,
      items: rawItems
          .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: readDouble(d['total']),
      subtotal: readDouble(d['subtotal']),
      deliveryFee: readDouble(d['deliveryFee']),
      serviceFee: readDouble(d['serviceFee']),
      discount: readDouble(d['discount']),
      promoCode: (d['promoCode'] as String?) ?? '',
      deliveryAddress: (d['deliveryAddress'] as String?) ?? '',
      deliveryNote: (d['deliveryNote'] as String?) ?? '',
      status: _enumByName(OrderStatus.values, d['status'], OrderStatus.pending),
      paymentMethod:
          _enumByName(PaymentMethod.values, d['paymentMethod'], PaymentMethod.cashOnDelivery),
      paymentStatus:
          _enumByName(PaymentStatus.values, d['paymentStatus'], PaymentStatus.pending),
      createdAt: readDate(d['createdAt']),
      restaurantLat: readDouble(d['restaurantLat'], Restaurant.defaultLat),
      restaurantLng: readDouble(d['restaurantLng'], Restaurant.defaultLng),
      deliveryLat: readDouble(d['deliveryLat'], Restaurant.defaultLat + 0.01),
      deliveryLng: readDouble(d['deliveryLng'], Restaurant.defaultLng + 0.01),
      disputeStatus: _enumByName(DisputeStatus.values, d['disputeStatus'], DisputeStatus.none),
      disputeReason: d['disputeReason'] as String?,
      disputeNote: d['disputeNote'] as String?,
    );
  }
}
