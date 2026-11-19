import '../../core/utils/error_text.dart';
import '../../core/utils/promo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/pricing.dart';
import '../../models/payment_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/saved_address.dart';
import '../../providers/address_book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/order_placed_dialog.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/food_loader.dart';
import '../../widgets/price_breakdown.dart';
import 'order_tracking_screen.dart';
import 'payment_sheet_screen.dart';

/// Checkout: typed delivery address (saved addresses one tap away), an
/// optional note for the rider, payment method and a full price breakdown.
/// A card payment runs through [PaymentSheetScreen] first — the order is
/// only placed once that charge succeeds.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _labels = ['Home', 'Work', 'Other'];

  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _note = TextEditingController();

  bool _placing = false;
  String? _error;
  PaymentMethod _method = PaymentMethod.card;

  double? _gpsLat;
  double? _gpsLng;
  bool _locating = false;

  String? _selectedId; // id of the saved address currently applied
  bool _saveAddress = false;
  String _saveLabel = 'Home';
  bool _prefilled = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  final _promoCtrl = TextEditingController();
  PromoCode? _promo;
  String? _promoError;

  void _applyPromo([String? raw]) {
    final code = PromoCodes.lookup(raw ?? _promoCtrl.text);
    if (code == null) {
      setState(() => _promoError = 'That code is not valid.');
      return;
    }
    final reason = code.ineligibleReason(ref.read(cartProvider.notifier).breakdown);
    if (reason != null) {
      setState(() => _promoError = reason);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _promo = code;
      _promoError = null;
      _promoCtrl.clear();
    });
  }

  void _pick(SavedAddress a) {
    setState(() {
      _selectedId = a.id;
      _address.text = a.address;
      _gpsLat = a.lat;
      _gpsLng = a.lng;
      _saveAddress = false;
    });
  }

  Future<void> _confirmDelete(SavedAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${a.label}"?'),
        content: Text(a.address),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(addressBookProvider.notifier).remove(a.id);
    if (_selectedId == a.id) setState(() => _selectedId = null);
  }

  static IconData _iconFor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final user = ref.watch(authProvider).user;
    final restaurants = ref.watch(restaurantListProvider).valueOrNull ?? [];
    final saved = ref.watch(addressBookProvider);
    final p = context.palette;
    final price = Pricing.of(cartNotifier.total);
    // Recomputed on every build, so if the cart changes after a code was applied
    // the discount (or its ineligibility) stays correct.
    final promoNow = _promo;
    final discount = promoNow?.discountFor(price) ?? 0.0;
    final payable = price.total - discount;
    final promoWarning = promoNow?.ineligibleReason(price);

    Restaurant? restaurant;
    for (final r in restaurants) {
      if (cart.isNotEmpty && r.id == cart.first.menuItem.restaurantId) {
        restaurant = r;
        break;
      }
    }

    // Pre-fill with the most recently saved address (once, and only if the
    // customer hasn't started typing).
    if (!_prefilled && saved.isNotEmpty) {
      _prefilled = true;
      if (_address.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pick(saved.first);
        });
      }
    }

    final scaffold = Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (restaurant != null) ...[
                      Text('Order from', style: TextStyle(color: p.inkSoft, fontSize: 12)),
                      Text(restaurant.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                    ],
                    _SectionCard(
                      title: 'Order summary',
                      child: Column(
                        children: [
                          for (final line in cart)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text('${line.quantity}×', style: TextStyle(color: p.inkSoft)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(line.menuItem.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Text('Rs. ${line.subtotal.toStringAsFixed(0)}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Delivery address',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (saved.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final a in saved)
                                  InputChip(
                                    avatar: Icon(_iconFor(a.label), size: 18),
                                    label: Text(a.label),
                                    selected: _selectedId == a.id,
                                    onSelected: _placing ? null : (_) => _pick(a),
                                    onDeleted: _placing ? null : () => _confirmDelete(a),
                                    deleteButtonTooltipMessage: 'Delete ${a.label}',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _address,
                            enabled: !_placing,
                            minLines: 2,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.streetAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_selectedId != null) setState(() => _selectedId = null);
                            },
                            validator: (v) => (v == null || v.trim().length < 6)
                                ? 'Enter your full address (street, house no., area)'
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Street, house no., area',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(_gpsLat != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                                  size: 18, color: _gpsLat != null ? p.success : p.inkSoft),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _gpsLat != null ? 'Location pinned' : 'Add a GPS pin to help your rider find you',
                                  style: TextStyle(color: p.inkSoft, fontSize: 13),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: (_locating || _placing) ? null : _useCurrentLocation,
                                icon: _locating
                                    ? const SizedBox(
                                        width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.my_location, size: 16),
                                label: Text(_gpsLat != null ? 'Refresh' : 'Use GPS'),
                              ),
                            ],
                          ),
                          if (_selectedId == null) ...[
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              value: _saveAddress,
                              onChanged: _placing ? null : (v) => setState(() => _saveAddress = v ?? false),
                              title: const Text('Save this address for next time'),
                            ),
                            if (_saveAddress)
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final l in _labels)
                                    ChoiceChip(
                                      avatar: Icon(_iconFor(l), size: 16),
                                      label: Text(l),
                                      selected: _saveLabel == l,
                                      onSelected: (_) => setState(() => _saveLabel = l),
                                    ),
                                ],
                              ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _note,
                            enabled: !_placing,
                            maxLength: 140,
                            maxLines: 2,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Note for the rider (optional)',
                              hintText: 'e.g. Ring the bell twice, blue gate',
                              prefixIcon: Icon(Icons.sticky_note_2_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Payment method',
                      child: Column(
                        children: [
                          _PaymentMethodTile(
                            icon: Icons.credit_card,
                            label: 'Card (Stripe test mode)',
                            selected: _method == PaymentMethod.card,
                            onTap: _placing ? null : () => setState(() => _method = PaymentMethod.card),
                          ),
                          const SizedBox(height: 8),
                          _PaymentMethodTile(
                            icon: Icons.payments_outlined,
                            label: 'Cash on delivery',
                            selected: _method == PaymentMethod.cashOnDelivery,
                            onTap: _placing ? null : () => setState(() => _method = PaymentMethod.cashOnDelivery),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Promo code',
                      child: promoNow != null
                          ? Row(
                              children: [
                                Icon(promoWarning == null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    color: promoWarning == null ? p.success : p.warning),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(promoNow.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text(promoWarning ?? promoNow.title,
                                          style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove code',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() => _promo = null),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _promoCtrl,
                                        textCapitalization: TextCapitalization.characters,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _applyPromo(),
                                        decoration: InputDecoration(
                                          hintText: 'Enter code',
                                          prefixIcon: const Icon(Icons.local_offer_outlined),
                                          errorText: _promoError,
                                          errorMaxLines: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton(onPressed: _applyPromo, child: const Text('Apply')),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final c in PromoCodes.all)
                                      ActionChip(label: Text(c.code), onPressed: () => _applyPromo(c.code)),
                                  ],
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Price details',
                      child: PriceBreakdownView.from(price, discount: discount, promoCode: promoNow?.code ?? ''),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: p.card,
                boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Errors (payment declined, GPS, network…) appear right above
                  // the action button so they are never off-screen.
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ErrorBanner(message: _error!),
                    ),
                  if (!price.meetsMinimum)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Minimum order is Rs. ${Pricing.minimumOrder.toStringAsFixed(0)}',
                        style: TextStyle(color: p.danger, fontSize: 13),
                      ),
                    ),
                  CustomButton(
                    label: _method == PaymentMethod.card
                        ? 'Continue to payment · Rs. ${payable.toStringAsFixed(0)}'
                        : 'Place order · Rs. ${payable.toStringAsFixed(0)}',
                    loading: _placing,
                    onPressed: (user == null || restaurant == null || cart.isEmpty || !price.meetsMinimum)
                        ? null
                        : () => _checkout(user.id, restaurant!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // While the order is being sent: block back-navigation and show the
    // food-themed progress screen instead of just a spinning button.
    return PopScope(
      canPop: !_placing,
      child: Stack(
        children: [
          scaffold,
          if (_placing)
            Positioned.fill(
              child: Material(
                color: p.bg.withValues(alpha: 0.95),
                child: const FoodLoader(messages: FoodLoader.orderMessages, size: 72),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkout(String customerId, Restaurant restaurant) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _placing = true;
      _error = null;
    });

    final cart = ref.read(cartProvider);
    final price = ref.read(cartProvider.notifier).breakdown;
    final amountDue = price.total - (_promo?.discountFor(price) ?? 0.0);
    var paymentStatus = PaymentStatus.pending;

    if (_method == PaymentMethod.card) {
      final result = await Navigator.push<PaymentResult>(
        context,
        MaterialPageRoute(builder: (_) => PaymentSheetScreen(amount: amountDue)),
      );
      if (!mounted) return;
      if (result == null || !result.success) {
        setState(() {
          _placing = false;
          _error = result?.errorMessage == 'Cancelled' ? null : (result?.errorMessage ?? 'Payment was not completed.');
        });
        return;
      }
      paymentStatus = PaymentStatus.succeeded;
    }

    try {
      final address = _address.text.trim();
      final order = await ref.read(placeOrderProvider).placeOrder(
            customerId: customerId,
            restaurant: restaurant,
            items: cart,
            paymentMethod: _method,
            paymentStatus: paymentStatus,
            deliveryLat: _gpsLat,
            deliveryLng: _gpsLng,
            deliveryAddress: address,
            deliveryNote: _note.text.trim(),
            promoCode: _promo?.code,
          );

      if (_saveAddress && _selectedId == null) {
        ref.read(addressBookProvider.notifier).upsert(SavedAddress(
              id: const Uuid().v4(),
              label: _saveLabel,
              address: address,
              lat: _gpsLat,
              lng: _gpsLng,
            ));
      }
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      await showOrderPlacedDialog(context);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _placing = false;
        _error = paymentStatus == PaymentStatus.succeeded
            ? 'Your payment went through but we couldn\'t place the order. Please try again — you won\'t be charged twice.'
            : 'We couldn\'t place your order. ${friendlyError(e)}';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final pos = await DeviceLocation.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (pos != null) {
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
      } else {
        _error = 'Could not get your location — check location permission is granted.';
      }
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PaymentMethodTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      child: Material(
        color: selected ? p.redTint : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? p.red : p.line),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? p.redDeep : p.inkSoft),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? p.red : p.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
