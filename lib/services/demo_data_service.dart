import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_utils.dart';
import '../core/utils/pricing.dart';
import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/restaurant_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

/// One dummy order, described compactly. [items] maps a sample menu item id
/// to a quantity; everything else (fees, coordinates, restaurant name) is
/// derived when the order is built.
class _OrderSpec {
  final String id;
  final int customer; // index into DemoDataService.customers
  final String restaurantId;
  final Map<String, int> items;
  final OrderStatus status;
  final int? rider; // index into DemoDataService.riders, null = unassigned
  final Duration age; // how long ago the order was placed
  final PaymentMethod method;
  final PaymentStatus payment;
  final int? reviewStars;
  final String reviewComment;
  final DisputeStatus dispute;
  final String? disputeReason;

  const _OrderSpec(
    this.id,
    this.customer,
    this.restaurantId,
    this.items,
    this.status, {
    this.rider,
    required this.age,
    this.method = PaymentMethod.cashOnDelivery,
    this.payment = PaymentStatus.pending,
    this.reviewStars,
    this.reviewComment = '',
    this.dispute = DisputeStatus.none,
    this.disputeReason,
  });
}

/// Dummy customers, riders, orders, reviews, notifications and rider GPS
/// positions, so every admin / rider / customer screen has something to show.
///
/// Notes
///  * Every document uses a fixed `sample-...` id, so running the seed twice
///    overwrites instead of duplicating.
///  * These users exist only as Firestore profiles — they are NOT Firebase
///    Auth accounts, so you can't log in as them. They show up in the admin
///    rider list, order lists, reviews and analytics. To log in as a
///    customer / rider, just sign up normally in the app.
///  * Writing other people's documents needs the updated firestore.rules
///    (admin may write `sample-` ids) — deploy them first.
class DemoDataService {
  DemoDataService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  // ---------------------------------------------------------------- people

  static const List<AppUser> customers = [
    AppUser(id: 'sample-customer-1', name: 'Ayesha Khan', email: 'ayesha.khan@example.com', phone: '0300-1234501', role: UserRole.customer),
    AppUser(id: 'sample-customer-2', name: 'Bilal Ahmed', email: 'bilal.ahmed@example.com', phone: '0301-2345602', role: UserRole.customer),
    AppUser(id: 'sample-customer-3', name: 'Fatima Noor', email: 'fatima.noor@example.com', phone: '0302-3456703', role: UserRole.customer),
    AppUser(id: 'sample-customer-4', name: 'Hamza Malik', email: 'hamza.malik@example.com', phone: '0303-4567804', role: UserRole.customer),
    AppUser(id: 'sample-customer-5', name: 'Sana Iqbal', email: 'sana.iqbal@example.com', phone: '0304-5678905', role: UserRole.customer),
    AppUser(id: 'sample-customer-6', name: 'Usman Tariq', email: 'usman.tariq@example.com', phone: '0305-6789006', role: UserRole.customer),
    AppUser(id: 'sample-customer-7', name: 'Mariam Zahid', email: 'mariam.zahid@example.com', phone: '0306-7890107', role: UserRole.customer),
    AppUser(id: 'sample-customer-8', name: 'Ali Raza', email: 'ali.raza@example.com', phone: '0307-8901208', role: UserRole.customer),
  ];

  static const List<AppUser> riders = [
    AppUser(id: 'sample-rider-1', name: 'Kamran Butt', email: 'kamran.rider@example.com', phone: '0311-1100011', role: UserRole.rider),
    AppUser(id: 'sample-rider-2', name: 'Imran Shah', email: 'imran.rider@example.com', phone: '0312-2200022', role: UserRole.rider),
    AppUser(id: 'sample-rider-3', name: 'Zeeshan Ali', email: 'zeeshan.rider@example.com', phone: '0313-3300033', role: UserRole.rider),
    AppUser(id: 'sample-rider-4', name: 'Adnan Siddiqui', email: 'adnan.rider@example.com', phone: '0314-4400044', role: UserRole.rider),
    // Waiting for admin approval — try the switch in Admin > Riders.
    AppUser(id: 'sample-rider-5', name: 'Rashid Mehmood', email: 'rashid.rider@example.com', phone: '0315-5500055', role: UserRole.rider, isApproved: false),
    AppUser(id: 'sample-rider-6', name: 'Noman Javed', email: 'noman.rider@example.com', phone: '0316-6600066', role: UserRole.rider, isApproved: false),
  ];

  // ---------------------------------------------------------------- orders

  static const List<String> _addresses = [
    'House 14, Street 3, Model Town, Vehari',
    'Flat 5, Al-Noor Plaza, Multan Road, Vehari',
    'House 221, Block B, Satellite Town, Vehari',
    'Shop 9, Main Bazaar, Vehari',
    'House 48, Gulshan Colony, Vehari',
    'Near Govt. College, Club Road, Vehari',
    'House 7, Street 12, Iqbal Town, Vehari',
    'Office 3, City Tower, Burewala Road, Vehari',
  ];

  static const List<String> _notes = [
    '',
    'Please ring the bell twice.',
    'Call me when you reach the gate.',
    '',
    'Extra napkins and ketchup please.',
    '',
    'Leave with the guard if I do not pick up.',
    '',
  ];

  static const List<_OrderSpec> _orders = [
    // --- Delivered (history, analytics, reviews) ---
    _OrderSpec('sample-order-001', 0, 'sample-midcity', {'sample-midcity-1': 1, 'sample-midcity-3': 1}, OrderStatus.delivered,
        rider: 0, age: Duration(days: 27, hours: 3), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        reviewStars: 5, reviewComment: 'Karahi was excellent and still hot on arrival. Highly recommend!'),
    _OrderSpec('sample-order-002', 1, 'sample-fifth-avenue', {'sample-fifth-3': 2, 'sample-fifth-2': 1}, OrderStatus.delivered,
        rider: 1, age: Duration(days: 25, hours: 6), reviewStars: 4, reviewComment: 'Burgers were crispy. Delivery took a little longer than estimated.'),
    _OrderSpec('sample-order-003', 2, 'sample-sweet-creme', {'sample-sweet-2': 2, 'sample-sweet-4': 1}, OrderStatus.delivered,
        rider: 2, age: Duration(days: 23, hours: 1), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        reviewStars: 5, reviewComment: 'Best brownies in town. Ice cream rolls were perfect.'),
    _OrderSpec('sample-order-007', 6, 'sample-brew-bean', {'sample-brew-1': 2, 'sample-brew-5': 2}, OrderStatus.delivered,
        rider: 2, age: Duration(days: 15, hours: 2), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        reviewStars: 5, reviewComment: 'Coffee arrived hot and the muffins were fresh.'),
    _OrderSpec('sample-order-011', 2, 'sample-midcity', {'sample-midcity-2': 2}, OrderStatus.delivered,
        rider: 2, age: Duration(days: 9, hours: 4), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        reviewStars: 5, reviewComment: 'Malai boti melts in the mouth.'),
    _OrderSpec('sample-order-012', 3, 'sample-fifth-avenue', {'sample-fifth-1': 1, 'sample-fifth-4': 2}, OrderStatus.delivered,
        rider: 3, age: Duration(days: 8, hours: 2), reviewStars: 4, reviewComment: 'Good value. Wraps were tasty.'),
    _OrderSpec('sample-order-013', 4, 'sample-sweet-creme', {'sample-sweet-1': 2, 'sample-sweet-3': 1}, OrderStatus.delivered,
        rider: 0, age: Duration(days: 7, hours: 5), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        reviewStars: 5, reviewComment: 'Blizzard was thick and creamy.'),
    _OrderSpec('sample-order-016', 7, 'sample-brew-bean', {'sample-brew-2': 1, 'sample-brew-4': 1}, OrderStatus.delivered,
        rider: 3, age: Duration(days: 4, hours: 4), reviewStars: 5, reviewComment: 'Great lunch spot, even for delivery.'),
    _OrderSpec('sample-order-020', 3, 'sample-midcity', {'sample-midcity-3': 2}, OrderStatus.delivered,
        rider: 3, age: Duration(days: 1, hours: 2), method: PaymentMethod.card, payment: PaymentStatus.succeeded,
        dispute: DisputeStatus.open, disputeReason: 'Karahi was missing from the bag; only received naan.'),

    // --- Refunded delivered order (dispute resolved) ---
    _OrderSpec('sample-order-021', 4, 'sample-fifth-avenue', {'sample-fifth-5': 2}, OrderStatus.delivered,
        rider: 0, age: Duration(days: 11, hours: 1), method: PaymentMethod.card, payment: PaymentStatus.refunded,
        dispute: DisputeStatus.resolved, disputeReason: 'Order arrived cold and a wrap was missing.'),

    // --- Cancelled ---
    _OrderSpec('sample-order-023', 6, 'sample-sweet-creme', {'sample-sweet-4': 1}, OrderStatus.cancelled,
        age: Duration(days: 2, hours: 9)),

    // --- Live orders (admin map, rider queue, customer tracking) ---
    _OrderSpec('sample-order-031', 6, 'sample-brew-bean', {'sample-brew-3': 1, 'sample-brew-6': 2}, OrderStatus.pending,
        age: Duration(minutes: 4)),
    _OrderSpec('sample-order-032', 7, 'sample-sweet-creme', {'sample-sweet-4': 2}, OrderStatus.pending,
        age: Duration(minutes: 9), method: PaymentMethod.card, payment: PaymentStatus.succeeded),
    // Preparing, no rider yet -> appears in every approved rider's request queue.
    _OrderSpec('sample-order-027', 2, 'sample-midcity', {'sample-midcity-1': 1, 'sample-midcity-2': 1}, OrderStatus.preparing,
        age: Duration(minutes: 18), method: PaymentMethod.card, payment: PaymentStatus.succeeded),
    _OrderSpec('sample-order-033', 1, 'sample-brew-bean', {'sample-brew-4': 1, 'sample-brew-1': 1}, OrderStatus.preparing,
        age: Duration(minutes: 11)),
    // Out for delivery with a live rider position.
    _OrderSpec('sample-order-029', 4, 'sample-fifth-avenue', {'sample-fifth-1': 1, 'sample-fifth-3': 2}, OrderStatus.outForDelivery,
        rider: 1, age: Duration(minutes: 31), method: PaymentMethod.card, payment: PaymentStatus.succeeded),
    _OrderSpec('sample-order-030', 5, 'sample-sweet-creme', {'sample-sweet-2': 2, 'sample-sweet-1': 1}, OrderStatus.outForDelivery,
        rider: 2, age: Duration(minutes: 24)),
  ];

  /// Order ids from earlier versions of the seed (restaurants that no longer
  /// exist). Re-running the seed deletes their order, review and notification.
  static const List<String> retiredOrderIds = [
    'sample-order-004',
    'sample-order-005',
    'sample-order-006',
    'sample-order-008',
    'sample-order-009',
    'sample-order-010',
    'sample-order-014',
    'sample-order-015',
    'sample-order-017',
    'sample-order-018',
    'sample-order-019',
    'sample-order-022',
    'sample-order-024',
    'sample-order-025',
    'sample-order-026',
    'sample-order-028',
  ];

  // ----------------------------------------------------------------- build

  static final Map<String, Restaurant> _restaurantById = {
    for (final r in MockDataService.restaurants) r.id: r,
  };
  static final Map<String, MenuItem> _menuById = {
    for (final m in MockDataService.menuItems) m.id: m,
  };

  /// Builds the sample orders relative to [now] (injectable for tests).
  static List<FoodOrder> buildOrders({DateTime? now}) {
    final base = now ?? DateTime.now();
    final out = <FoodOrder>[];
    for (var n = 0; n < _orders.length; n++) {
      final s = _orders[n];
      final r = _restaurantById[s.restaurantId]!;
      final items = <CartItem>[
        for (final e in s.items.entries) CartItem(menuItem: _menuById[e.key]!, quantity: e.value),
      ];
      final price = Pricing.of(items.fold<double>(0, (sum, i) => sum + i.subtotal));
      final customerIdx = s.customer % customers.length;
      // Spread delivery points ~0.5-2 km around the restaurant, deterministically.
      final dLat = 0.004 + (n % 5) * 0.003;
      final dLng = (n.isEven ? 1 : -1) * (0.004 + (n % 4) * 0.003);
      out.add(FoodOrder(
        id: s.id,
        customerId: customers[customerIdx].id,
        restaurantId: r.id,
        restaurantName: r.name,
        riderId: s.rider == null ? null : riders[s.rider!].id,
        items: items,
        total: price.total,
        subtotal: price.subtotal,
        deliveryFee: price.deliveryFee,
        serviceFee: price.serviceFee,
        deliveryAddress: _addresses[customerIdx % _addresses.length],
        deliveryNote: _notes[n % _notes.length],
        status: s.status,
        paymentMethod: s.method,
        paymentStatus: s.payment,
        createdAt: base.subtract(s.age),
        restaurantLat: r.lat,
        restaurantLng: r.lng,
        deliveryLat: r.lat + dLat,
        deliveryLng: r.lng + dLng,
        disputeStatus: s.dispute,
        disputeReason: s.disputeReason,
        disputeNote: s.dispute == DisputeStatus.resolved ? 'Refund issued after review.' : null,
      ));
    }
    return out;
  }

  static List<Review> buildReviews({DateTime? now}) {
    final base = now ?? DateTime.now();
    final orders = {for (final o in buildOrders(now: base)) o.id: o};
    final out = <Review>[];
    for (final s in _orders) {
      if (s.reviewStars == null) continue;
      final o = orders[s.id]!;
      out.add(Review(
        id: o.id,
        orderId: o.id,
        restaurantId: o.restaurantId,
        customerId: o.customerId,
        rating: s.reviewStars!,
        comment: s.reviewComment,
        createdAt: o.createdAt.add(const Duration(hours: 2)),
      ));
    }
    return out;
  }

  // ------------------------------------------------------------------ seed

  /// Writes everything. Safe to run repeatedly (fixed ids).
  Future<DemoSeedResult> seedAll({DateTime? now}) async {
    final base = now ?? DateTime.now();
    final orders = buildOrders(now: base);
    final reviews = buildReviews(now: base);

    // Firestore batches hold at most 500 writes; we use several small ones.
    var batch = _db.batch();
    var pending = 0;
    Future<void> flush() async {
      if (pending == 0) return;
      await batch.commit();
      batch = _db.batch();
      pending = 0;
    }

    Future<void> set(DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data) async {
      batch.set(ref, data);
      if (++pending >= 400) await flush();
    }

    // People.
    for (final u in [...customers, ...riders]) {
      await set(_db.collection(Col.users).doc(u.id), {
        ...u.toFirestore(),
        'createdAt': Timestamp.fromDate(base.subtract(const Duration(days: 40))),
        'isSample': true,
      });
    }

    // Orders.
    for (final o in orders) {
      await set(_db.collection(Col.orders).doc(o.id), {
        ...o.toFirestore(),
        'updatedAt': Timestamp.fromDate(o.createdAt.add(const Duration(minutes: 20))),
        'isSample': true,
      });
    }

    // Reviews (doc id == order id, like the real app).
    for (final r in reviews) {
      await set(_db.collection(Col.reviews).doc(r.id), r.toFirestore());
    }

    // Live rider positions for riders who are out delivering: put them
    // part-way between the restaurant and the customer.
    var locations = 0;
    for (final o in orders) {
      final riderId = o.riderId;
      if (o.status != OrderStatus.outForDelivery || riderId == null) continue;
      await set(_db.collection(Col.riderLocations).doc(riderId), {
        'riderId': riderId,
        'orderId': o.id,
        'lat': o.restaurantLat + (o.deliveryLat - o.restaurantLat) * 0.55,
        'lng': o.restaurantLng + (o.deliveryLng - o.restaurantLng) * 0.55,
        'updatedAt': Timestamp.fromDate(base),
      });
      locations++;
    }

    // Notification inbox entries for each customer's latest sample order.
    var notifications = 0;
    for (final o in orders) {
      final title = switch (o.status) {
        OrderStatus.preparing => 'Order confirmed',
        OrderStatus.outForDelivery => 'On the way',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Order cancelled',
        OrderStatus.pending => null,
      };
      if (title == null) continue;
      final body = switch (o.status) {
        OrderStatus.preparing => '${o.restaurantName} started preparing your order.',
        OrderStatus.outForDelivery => 'Your order from ${o.restaurantName} is out for delivery.',
        OrderStatus.delivered => 'Your order from ${o.restaurantName} has arrived. Enjoy!',
        _ => 'Your order from ${o.restaurantName} was cancelled.',
      };
      await set(_db.collection(Col.notifications).doc('sample-notif-${o.id}'), {
        'userId': o.customerId,
        'title': title,
        'body': body,
        'read': o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled,
        'createdAt': Timestamp.fromDate(o.createdAt.add(const Duration(minutes: 25))),
      });
      notifications++;
    }

    // Remove sample documents that belonged to restaurants we no longer ship.
    // Fixed ids, so no reads are needed (deleting a missing doc is a no-op).
    for (final id in retiredOrderIds) {
      batch.delete(_db.collection(Col.orders).doc(id));
      batch.delete(_db.collection(Col.reviews).doc(id));
      batch.delete(_db.collection(Col.notifications).doc('sample-notif-$id'));
      pending += 3;
      if (pending >= 400) await flush();
    }

    await flush();
    return DemoSeedResult(
      customers: customers.length,
      riders: riders.length,
      orders: orders.length,
      reviews: reviews.length,
      riderLocations: locations,
      notifications: notifications,
    );
  }
}

class DemoSeedResult {
  final int customers;
  final int riders;
  final int orders;
  final int reviews;
  final int riderLocations;
  final int notifications;

  const DemoSeedResult({
    required this.customers,
    required this.riders,
    required this.orders,
    required this.reviews,
    required this.riderLocations,
    required this.notifications,
  });

  @override
  String toString() =>
      '$customers customers, $riders riders, $orders orders, $reviews reviews';
}
