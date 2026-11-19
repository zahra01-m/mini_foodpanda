import '../../core/utils/cuisine_icon.dart';
import '../../core/utils/error_text.dart';
import '../../core/utils/pricing.dart';
import '../../core/utils/reorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/order_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/restaurant_image.dart';
import '../../widgets/tap_bounce.dart';
import '../../widgets/skeleton_list.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'profile_screen.dart';
import 'restaurant_detail_screen.dart';

/// Home screen for customers: search, category filter, favorites filter,
/// pull-to-refresh, and entry points to orders, cart and profile.
enum _Sort { recommended, rating, fastest }

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category; // null = All
  _Sort _sort = _Sort.recommended;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static bool _isActive(FoodOrder o) =>
      o.status == OrderStatus.pending ||
      o.status == OrderStatus.preparing ||
      o.status == OrderStatus.outForDelivery;

  List<Restaurant> _apply(List<Restaurant> all, Set<String> favoriteIds, bool favoritesOnly) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (favoritesOnly && !favoriteIds.contains(r.id)) return false;
      if (_category != null && r.category != _category) return false;
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) || r.category.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        switch (_sort) {
          case _Sort.rating:
            return b.rating.compareTo(a.rating);
          case _Sort.fastest:
            return a.etaMinutes.compareTo(b.etaMinutes);
          case _Sort.recommended:
            return 0; // keep the server order
        }
      });
  }

  Future<void> _refresh() async {
    ref.invalidate(restaurantListProvider);
    try {
      await ref.read(restaurantListProvider.future);
    } catch (_) {
      // The error state is rendered by the screen itself.
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantListProvider);
    final cartCount = ref.watch(cartProvider.select((c) => c.fold<int>(0, (n, i) => n + i.quantity)));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final favoritesOnly = ref.watch(favoritesFilterProvider);
    final user = ref.watch(authProvider).user;
    final customerId = user?.id;
    final p = context.palette;

    // Orders still in flight — surfaced as a shortcut on this screen so a
    // customer can get back to live tracking without digging through history.
    final myOrders = customerId == null
        ? const <FoodOrder>[]
        : (ref.watch(customerOrdersProvider(customerId)).valueOrNull ?? const <FoodOrder>[]);
    final activeOrders = myOrders.where(_isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    FoodOrder? lastDelivered;
    for (final o in myOrders) {
      if (o.status == OrderStatus.delivered &&
          (lastDelivered == null || o.createdAt.isAfter(lastDelivered.createdAt))) {
        lastDelivered = o;
      }
    }
    final lastOrder = lastDelivered;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Order history',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded),
                tooltip: cartCount == 0 ? 'Cart' : 'Cart, $cartCount items',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cartCount > 0)
                PositionedDirectional(
                  end: 4,
                  top: 4,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(cartCount),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: p.red, borderRadius: BorderRadius.circular(99)),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(cartCount > 99 ? '99+' : '$cartCount',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: p.onRed, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Profile was previously unreachable: theme, language,
          // notifications and log out all live on this screen.
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: restaurants.when(
        loading: () => const SkeletonRestaurantList(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(restaurantListProvider),
        ),
        data: (all) {
          final categories = (all.map((r) => r.category).where((c) => c.trim().isNotEmpty).toSet().toList()..sort());
          final list = _apply(all, favoriteIds, favoritesOnly);
          void open(Restaurant r) =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)));

          // Shown only on the unfiltered home view, as the first scrolling items.
          final showTop = _query.isEmpty && _category == null && !favoritesOnly && all.length >= 4;
          final top = ([...all]..sort((a, b) => b.rating.compareTo(a.rating))).take(5).toList();
          final headers = <Widget>[
            FadeSlideIn(child: _HeroBanner(name: firstName)),
            if (showTop && lastOrder != null)
              FadeSlideIn(
                index: 1,
                child: _OrderAgainCard(order: lastOrder, onTap: () => reorder(context, ref, lastOrder)),
              ),
            if (showTop) FadeSlideIn(index: 1, child: _TopRatedStrip(restaurants: top, onOpen: open)),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                showTop ? 'All restaurants' : '${list.length} restaurant${list.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ];

          return Column(
            children: [
              if (activeOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _ActiveOrderBanner(order: activeOrders.first, otherCount: activeOrders.length - 1),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants or cuisines',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                        PopupMenuButton<_Sort>(
                          tooltip: 'Sort restaurants',
                          initialValue: _sort,
                          onSelected: (v) => setState(() => _sort = v),
                          icon: Icon(Icons.sort_rounded,
                              color: _sort == _Sort.recommended ? p.inkSoft : p.red),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: _Sort.recommended, child: Text('Recommended')),
                            PopupMenuItem(value: _Sort.rating, child: Text('Top rated')),
                            PopupMenuItem(value: _Sort.fastest, child: Text('Fastest delivery')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    // First chip is the favorites filter (it used to be an
                    // unlabeled heart icon crowding the app bar).
                    if (i == 0) {
                      return ChoiceChip(
                        avatar: Icon(
                          favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: favoritesOnly ? p.red : p.inkSoft,
                        ),
                        label: const Text('Favorites'),
                        selected: favoritesOnly,
                        onSelected: (_) => ref.read(favoritesFilterProvider.notifier).state = !favoritesOnly,
                      );
                    }
                    final label = i == 1 ? 'All' : categories[i - 2];
                    final selected = i == 1 ? _category == null : _category == label;
                    return ChoiceChip(
                      avatar: Icon(i == 1 ? Icons.apps_rounded : cuisineIcon(label)),
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = i == 1 ? null : label),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: list.isEmpty
                    ? _emptyFor(all, favoritesOnly)
                    : RefreshIndicator(
                        color: p.red,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: headers.length + list.length,
                          itemBuilder: (context, i) {
                            if (i < headers.length) return headers[i];
                            final r = list[i - headers.length];
                            return FadeSlideIn(
                              key: ValueKey(r.id),
                              index: (i - headers.length) < 8 ? (i - headers.length) : 0,
                              baseDelay: const Duration(milliseconds: 55),
                              child: RestaurantCard(
                                restaurant: r,
                                isFavorite: favoriteIds.contains(r.id),
                                onToggleFavorite: customerId == null
                                    ? null
                                    : () => ref.read(favoritesServiceProvider).toggleFavorite(
                                          customerId,
                                          r.id,
                                          currentlyFavorite: favoriteIds.contains(r.id),
                                        ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: r)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyFor(List<Restaurant> all, bool favoritesOnly) {
    if (all.isEmpty) {
      return const EmptyState(icon: Icons.storefront_outlined, title: 'No restaurants yet', subtitle: 'Check back soon');
    }
    if (_query.isNotEmpty || _category != null) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        subtitle: 'Try a different search or category',
        retryLabel: 'Clear filters',
        onRetry: () {
          _searchController.clear();
          setState(() {
            _query = '';
            _category = null;
          });
        },
      );
    }
    if (favoritesOnly) {
      return const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        subtitle: 'Tap the heart on a restaurant to save it here',
      );
    }
    return const EmptyState(icon: Icons.storefront_outlined, title: 'No restaurants yet', subtitle: 'Check back soon');
  }
}

/// "Your order is on the way" shortcut shown above the restaurant list
/// while the customer has an order in flight.
class _ActiveOrderBanner extends StatelessWidget {
  final FoodOrder order;
  final int otherCount;
  const _ActiveOrderBanner({required this.order, required this.otherCount});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subtitle = otherCount > 0
        ? '${order.status.label} · +$otherCount more active'
        : '${order.status.label} · tap to track';
    return Semantics(
      button: true,
      child: Material(
        color: p.redTint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.red, shape: BoxShape.circle),
                  child: Icon(Icons.delivery_dining_rounded, color: p.onRed, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.redDeep),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient welcome card at the top of the home list.
class _HeroBanner extends StatelessWidget {
  final String name;
  const _HeroBanner({required this.name});

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
    return name.isEmpty ? part : '$part, $name';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: p.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: p.red.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('What are you craving today?',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white, fontSize: 22, height: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delivery_dining_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Free delivery over Rs. ${Pricing.freeDeliveryOver.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.ramen_dining_rounded, size: 72, color: Colors.white.withValues(alpha: 0.35)),
        ],
      ),
    );
  }
}

/// Horizontal "Top rated" carousel of photo cards.
class _TopRatedStrip extends StatelessWidget {
  final List<Restaurant> restaurants;
  final void Function(Restaurant) onOpen;
  const _TopRatedStrip({required this.restaurants, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, size: 22, color: p.red),
                const SizedBox(width: 6),
                Text('Top rated', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = restaurants[i];
                return TapBounce(
                  onTap: () => onOpen(r),
                  child: Semantics(
                    button: true,
                    label: '${r.name}, rated ${r.rating.toStringAsFixed(1)}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RestaurantImage(restaurant: r),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xB3000000)],
                                  stops: [0.4, 1],
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              top: 10,
                              start: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(99)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: p.gold),
                                    const SizedBox(width: 3),
                                    Text(r.rating.toStringAsFixed(1),
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: p.ink)),
                                  ],
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              start: 12,
                              end: 12,
                              bottom: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(r.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('${r.category} · ${r.etaMinutes} min',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap "order again" for the customer's most recent delivered order.
class _OrderAgainCard extends StatelessWidget {
  final FoodOrder order;
  final VoidCallback onTap;
  const _OrderAgainCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final summary = order.items.take(2).map((l) => '${l.quantity}× ${l.menuItem.name}').join(', ') +
        (order.items.length > 2 ? ' +${order.items.length - 2} more' : '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Semantics(
        button: true,
        child: Material(
          color: p.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: p.line),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: p.redTint, shape: BoxShape.circle),
                    child: Icon(Icons.replay_rounded, color: p.redDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order again from ${order.restaurantName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
