import '../../core/utils/error_text.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/pricing.dart';
import '../../widgets/dish_sheet.dart';
import '../../widgets/skeleton_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_palette.dart';
import '../../models/menu_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/menu_item_tile.dart';
import '../../widgets/restaurant_image.dart';
import 'cart_screen.dart';

class _Section {
  final String title;
  final List<MenuItem> items;
  const _Section(this.title, this.items);
}

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  static const double _chipBarHeight = 52;
  static const _typicalOrder = [
    'popular', 'starters', 'appetizers', 'mains', 'main course', 'pizza',
    'breads', 'sides', 'desserts', 'drinks', 'beverages',
  ];

  Restaurant get restaurant => widget.restaurant;

  final _scroll = ScrollController();
  final _menuSearch = TextEditingController();
  String _menuQuery = '';
  final _active = ValueNotifier<int>(0);
  final Map<String, GlobalKey> _keys = {};
  List<String> _titles = const [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _menuSearch.dispose();
    _active.dispose();
    super.dispose();
  }

  List<_Section> _group(List<MenuItem> items) {
    final map = <String, List<MenuItem>>{};
    for (final i in items) {
      map.putIfAbsent(i.category.trim(), () => []).add(i);
    }
    final names = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1; // uncategorised last
        if (b.isEmpty) return -1;
        int rank(String s) {
          final i = _typicalOrder.indexOf(s.toLowerCase());
          return i == -1 ? 999 : i;
        }

        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [
      for (final n in names) _Section(n.isEmpty ? (map.length == 1 ? 'Menu' : 'Other') : n, map[n]!),
    ];
  }

  double get _pinnedTop => MediaQuery.of(context).padding.top + kToolbarHeight + _chipBarHeight;

  /// Highlights the chip of the section currently under the pinned header.
  void _onScroll() {
    if (_titles.length < 2 || !_scroll.hasClients) return;
    var idx = 0;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 2) {
      idx = _titles.length - 1;
    } else {
      for (var i = 0; i < _titles.length; i++) {
        final box = _keys[_titles[i]]?.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) continue;
        if (box.localToGlobal(Offset.zero).dy <= _pinnedTop + 4) idx = i;
      }
    }
    if (_active.value != idx) _active.value = idx;
  }

  void _jumpTo(int i) {
    final box = _keys[_titles[i]]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scroll.hasClients) return;
    final target = (_scroll.offset + box.localToGlobal(Offset.zero).dy - _pinnedTop)
        .clamp(0.0, _scroll.position.maxScrollExtent)
        .toDouble();
    _active.value = i;
    _scroll.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  /// Checkout supports one restaurant per order. If the cart already
  /// holds items from somewhere else, ask before throwing them away
  /// instead of silently mixing restaurants.
  Future<void> _addToCart(MenuItem item) async {
    final cart = ref.read(cartProvider.notifier);
    if (!cart.conflictsWith(item)) {
      HapticFeedback.selectionClick();
      cart.add(item);
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new cart?'),
        content: Text(
          'Your cart has items from another restaurant. Adding "${item.name}" '
          'from ${restaurant.name} will clear it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep current cart')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start new cart')),
        ],
      ),
    );
    if (replace == true) cart.replaceWith(item);
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuProvider(restaurant.id));
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurant.id));
    final avgRating = ref.watch(restaurantRatingProvider(restaurant.id));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final isFavorite = favoriteIds.contains(restaurant.id);
    final customerId = ref.watch(authProvider).user?.id;
    final p = context.palette;
    final cartCount = cart.fold<int>(0, (n, c) => n + c.quantity);

    return Scaffold(
      body: menu.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(restaurant.name)),
          body: const SkeletonTileList(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(restaurant.name)),
          body: EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load menu',
            subtitle: friendlyError(e),
            onRetry: () => ref.invalidate(menuProvider(restaurant.id)),
          ),
        ),
        data: (items) {
          final q = _menuQuery.trim().toLowerCase();
          final visible = q.isEmpty
              ? items
              : items
                  .where((m) => m.name.toLowerCase().contains(q) || m.description.toLowerCase().contains(q))
                  .toList();
          final sections = _group(visible);
          _titles = [for (final s in sections) s.title];
          for (final t in _titles) {
            _keys.putIfAbsent(t, () => GlobalKey());
          }
          final showSections = sections.length > 1;

          return CustomScrollView(
            controller: _scroll,
            // Build every section so jump-to-section always has a target.
            cacheExtent: 4000,
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: p.red,
                foregroundColor: Colors.white,
                actions: [
                  if (customerId != null)
                    IconButton(
                      icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      onPressed: () => ref.read(favoritesServiceProvider).toggleFavorite(
                            customerId,
                            restaurant.id,
                            currentlyFavorite: isFavorite,
                          ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
                  title: Text(restaurant.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: 'restaurant-${restaurant.id}', child: RestaurantImage(restaurant: restaurant)),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66000000), Color(0x00000000), Color(0x99000000)],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (restaurant.category.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(restaurant.category, style: TextStyle(color: p.inkSoft, fontSize: 14)),
                        ),
                      Semantics(
                        button: true,
                        label: 'See reviews',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showReviews(context, reviewsAsync.valueOrNull ?? const []),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                // Wrap (not a fixed Row) so the stats flow onto a
                                // second line on narrow screens / large text
                                // instead of overflowing.
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 14,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded, size: 18, color: p.gold),
                                          const SizedBox(width: 4),
                                          Text(
                                            avgRating > 0
                                                ? avgRating.toStringAsFixed(1)
                                                : restaurant.rating.toStringAsFixed(1),
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(width: 6),
                                          reviewsAsync.when(
                                            data: (list) => Text(
                                                '(${list.length} review${list.length == 1 ? '' : 's'})',
                                                style: TextStyle(color: p.inkSoft)),
                                            loading: () => const SizedBox(),
                                            error: (_, __) => const SizedBox(),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.schedule_rounded, size: 16, color: p.inkSoft),
                                          const SizedBox(width: 4),
                                          Text('${restaurant.etaMinutes} min', style: TextStyle(color: p.inkSoft)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('See reviews',
                                    style: TextStyle(color: p.redDeep, fontSize: 13, fontWeight: FontWeight.w600)),
                                Icon(Icons.chevron_right_rounded, size: 18, color: p.redDeep),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                          icon: Icons.delivery_dining_rounded,
                          text: 'Delivery Rs. ${Pricing.deliveryFee.toStringAsFixed(0)}'),
                      _InfoPill(
                          icon: Icons.shopping_bag_outlined,
                          text: 'Min order Rs. ${Pricing.minimumOrder.toStringAsFixed(0)}'),
                      _InfoPill(
                          icon: Icons.local_offer_outlined,
                          text: 'Free delivery over Rs. ${Pricing.freeDeliveryOver.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
              // Search only earns its space on longer menus.
              if (items.length >= 8)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: TextField(
                      controller: _menuSearch,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _menuQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search this menu',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _menuQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _menuSearch.clear();
                                  setState(() => _menuQuery = '');
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                      icon: Icons.no_meals_outlined, title: 'No items yet', subtitle: 'This restaurant has nothing listed'),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No dishes found',
                      subtitle: 'Try a different word or clear the search'),
                )
              else ...[
                if (showSections)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ChipBarDelegate(
                      height: _chipBarHeight,
                      titles: _titles,
                      active: _active,
                      onTap: _jumpTo,
                      background: p.bg,
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: Divider(height: 17)),
                for (final s in sections)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        key: _keys[s.title],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showSections)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
                              child: Row(
                                children: [
                                  Text(s.title, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(width: 8),
                                  Text('${s.items.length}', style: TextStyle(color: p.inkSoft)),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 8),
                          for (var i = 0; i < s.items.length; i++)
                            FadeSlideIn(
                              key: ValueKey(s.items[i].id),
                              index: i < 6 ? i : 0,
                              baseDelay: const Duration(milliseconds: 45),
                              child: MenuItemTile(
                                item: s.items[i],
                                quantityInCart: cart
                                    .where((c) => c.menuItem.id == s.items[i].id)
                                    .fold<int>(0, (n, c) => n + c.quantity),
                                onAdd: () => _addToCart(s.items[i]),
                                onRemove: () => cartNotifier.decrement(s.items[i]),
                                onTap: () => showDishSheet(
                                  context,
                                  item: s.items[i],
                                  onAdd: () => _addToCart(s.items[i]),
                                  onRemove: () => cartNotifier.decrement(s.items[i]),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
          child: child,
        ),
        child: cart.isEmpty
            ? const SizedBox.shrink()
            : SafeArea(
                key: const ValueKey('bar'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      child: Semantics(
                        label: 'View cart, $cartCount item${cartCount == 1 ? '' : 's'}, '
                            'Rs. ${cartNotifier.total.toStringAsFixed(0)}',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            // Re-keyed on the count so it "pops" every time an item is added.
                            TweenAnimationBuilder<double>(
                              key: ValueKey(cartCount),
                              tween: Tween(begin: 1.4, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              builder: (context, v, child) => Transform.scale(scale: v, child: child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.onRed.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text('$cartCount', style: const TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('View cart')),
                            Text('Rs. ${cartNotifier.total.toStringAsFixed(0)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showReviews(BuildContext context, List<Review> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) {
          final p = context.palette;
          return reviews.isEmpty
              ? const EmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews yet',
                  subtitle: 'Be the first to rate this restaurant after your order arrives.',
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final r = reviews[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: '${r.rating} out of 5 stars',
                            child: ExcludeSemantics(
                              child: Row(
                                children: List.generate(
                                  5,
                                  (star) => Icon(
                                    star < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 16,
                                    color: p.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (r.comment.isNotEmpty) Text(r.comment),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM d, yyyy').format(r.createdAt),
                              style: TextStyle(color: p.inkSoft, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}

/// Pinned row of category chips; tapping one scrolls to that section and
/// the highlighted chip follows the scroll position.
class _ChipBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final List<String> titles;
  final ValueNotifier<int> active;
  final ValueChanged<int> onTap;
  final Color background;

  _ChipBarDelegate({
    required this.height,
    required this.titles,
    required this.active,
    required this.onTap,
    required this.background,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: background,
      elevation: overlapsContent ? 2 : 0,
      child: _ChipBar(titles: titles, active: active, onTap: onTap),
    );
  }

  @override
  bool shouldRebuild(covariant _ChipBarDelegate old) =>
      !listEquals(old.titles, titles) || old.background != background;
}

/// Horizontal section chips. As the page scrolls and the active section
/// changes, the bar scrolls itself so the highlighted chip stays in view
/// (with long menus the active chip used to slide off-screen).
class _ChipBar extends StatefulWidget {
  final List<String> titles;
  final ValueNotifier<int> active;
  final ValueChanged<int> onTap;

  const _ChipBar({required this.titles, required this.active, required this.onTap});

  @override
  State<_ChipBar> createState() => _ChipBarState();
}

class _ChipBarState extends State<_ChipBar> {
  final _controller = ScrollController();
  late List<GlobalKey> _keys = _makeKeys();

  List<GlobalKey> _makeKeys() => List.generate(widget.titles.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    widget.active.addListener(_follow);
  }

  @override
  void didUpdateWidget(covariant _ChipBar old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      old.active.removeListener(_follow);
      widget.active.addListener(_follow);
    }
    if (old.titles.length != widget.titles.length) _keys = _makeKeys();
  }

  @override
  void dispose() {
    widget.active.removeListener(_follow);
    _controller.dispose();
    super.dispose();
  }

  void _follow() {
    final i = widget.active.value;
    if (i < 0 || i >= _keys.length || !_controller.hasClients) return;
    final object = _keys[i].currentContext?.findRenderObject();
    if (object == null) return; // chip isn't built yet (far off-screen)
    // Scrolls only this bar — Scrollable.ensureVisible would also try to
    // scroll the page's vertical scroll view.
    _controller.position.ensureVisible(
      object,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.active,
      builder: (context, current, _) => ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.titles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => KeyedSubtree(
          key: _keys[i],
          child: ChoiceChip(
            label: Text(widget.titles[i]),
            selected: i == current,
            onSelected: (_) => widget.onTap(i),
          ),
        ),
      ),
    );
  }
}

/// Small outlined fact chip (delivery fee, minimum order…).
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.redDeep),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.ink)),
        ],
      ),
    );
  }
}
