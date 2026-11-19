import '../../core/utils/error_text.dart';
import '../../core/utils/image_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../models/menu_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/photo_picker_service.dart';
import '../../widgets/food_thumb.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fade_slide_in.dart';

/// Restaurant + menu CRUD and approval, per the spec's "Approve vendors"
/// and "restaurant + order list, basic CRUD" admin requirements.
class VendorManagementScreen extends ConsumerWidget {
  const VendorManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(allRestaurantsProvider);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add restaurant',
            onPressed: () => _editRestaurant(context, ref, null),
          ),
        ],
      ),
      body: restaurants.when(
        loading: () => const SkeletonTileList(showTrailing: true),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load vendors',
          subtitle: friendlyError(e),
          onRetry: () => ref.invalidate(allRestaurantsProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.storefront_outlined,
                title: 'No vendors yet',
                subtitle: 'Add one, or load sample data from the dashboard.',
                onRetry: () => _editRestaurant(context, ref, null),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final r = list[i];
                  return FadeSlideIn(
index: i < 8 ? i : 0,
horizontal: true,
child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.storefront_outlined, color: p.redDeep),
                    title: Text(r.name),
                    subtitle: Text('${r.category} · ${r.rating} ★'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _MenuScreen(restaurant: r)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit restaurant',
                          onPressed: () => _editRestaurant(context, ref, r),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: p.danger),
                          tooltip: 'Delete restaurant',
                          onPressed: () => _confirmDeleteRestaurant(context, ref, r),
                        ),
                        Switch(
                          value: r.isApproved,
                          onChanged: (v) => ref.read(restaurantServiceProvider).setApproved(r.id, v),
                        ),
                      ],
                    ),
                  ),
);
                },
              ),
      ),
    );
  }

  Future<void> _confirmDeleteRestaurant(BuildContext context, WidgetRef ref, Restaurant r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${r.name}"?'),
        content: const Text('This removes the restaurant and all of its menu items. Past orders are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await ref.read(restaurantServiceProvider).deleteRestaurant(r.id);
  }

  Future<void> _editRestaurant(BuildContext context, WidgetRef ref, Restaurant? existing) async {
    final name = TextEditingController(text: existing?.name);
    final category = TextEditingController(text: existing?.category);
    final photo = TextEditingController(text: existing?.imageUrl);
    final busy = ValueNotifier<bool>(false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add restaurant' : 'Edit restaurant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 12),
              _PhotoField(
                controller: photo,
                busy: busy,
                name: existing?.name ?? '',
                category: existing?.category ?? '',
                fallbackPreview: existing?.imageAsset ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ValueListenableBuilder<bool>(
            valueListenable: busy,
            builder: (context, isBusy, _) => FilledButton(
            onPressed: isBusy ? null : () {
              if (name.text.trim().isEmpty) return;
              ref.read(restaurantServiceProvider).saveRestaurant(
                    Restaurant(
                      id: existing?.id ?? '',
                      name: name.text.trim(),
                      category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
                      // No bundled default: a made-up path (the old restaurant_1.png) never existed
                      // and just produced a broken image.
                      imageAsset: existing?.imageAsset ?? '',
                      // Previously omitted, so every edit silently wiped the photo.
                      imageUrl: photo.text.trim(),
                      rating: existing?.rating ?? 4.5,
                      etaMinutes: existing?.etaMinutes ?? 30,
                      isApproved: existing?.isApproved ?? true,
                      lat: existing?.lat ?? Restaurant.defaultLat,
                      lng: existing?.lng ?? Restaurant.defaultLng,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )),
        ],
      ),
    );
  }
}

class _MenuScreen extends ConsumerWidget {
  final Restaurant restaurant;
  const _MenuScreen({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(adminMenuProvider(restaurant.id));
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
              icon: const Icon(Icons.add), tooltip: 'Add item', onPressed: () => _editItem(context, ref, null)),
        ],
      ),
      body: menu.when(
        loading: () => const SkeletonTileList(showTrailing: true),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load menu',
            subtitle: friendlyError(e)),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.no_meals_outlined,
                title: 'No items yet',
                subtitle: 'Add the first menu item.',
                onRetry: () => _editItem(context, ref, null),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text('Rs. ${item.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit item',
                          onPressed: () => _editItem(context, ref, item),
                        ),
                        Switch(
                          value: item.available,
                          onChanged: (v) => ref.read(restaurantServiceProvider).setAvailable(item.id, v),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: p.danger),
                          tooltip: 'Delete item',
                          // Deleting used to be instant and irreversible.
                          onPressed: () => _confirmDelete(context, ref, item),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MenuItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.name}"?'),
        content: const Text('This removes the item from the menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await ref.read(restaurantServiceProvider).deleteMenuItem(item.id);
  }

  Future<void> _editItem(BuildContext context, WidgetRef ref, MenuItem? existing) async {
    final name = TextEditingController(text: existing?.name);
    final description = TextEditingController(text: existing?.description);
    final price = TextEditingController(text: existing?.price.toStringAsFixed(0));
    final category = TextEditingController(text: existing?.category);
    final imageUrl = TextEditingController(text: existing?.imageUrl);
    final busy = ValueNotifier<bool>(false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (Rs.)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: category,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Category', helperText: 'e.g. Starters, Mains, Drinks'),
            ),
            const SizedBox(height: 12),
            _PhotoField(
              controller: imageUrl,
              busy: busy,
              name: existing?.name ?? '',
              category: existing?.category ?? '',
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ValueListenableBuilder<bool>(
            valueListenable: busy,
            builder: (context, isBusy, _) => FilledButton(
            onPressed: isBusy ? null : () {
              if (name.text.trim().isEmpty) return;
              ref.read(restaurantServiceProvider).saveMenuItem(
                    MenuItem(
                      id: existing?.id ?? '',
                      restaurantId: restaurant.id,
                      name: name.text.trim(),
                      description: description.text.trim(),
                      price: double.tryParse(price.text.trim()) ?? existing?.price ?? 0,
                      available: existing?.available ?? true,
                      category: category.text.trim(),
                      imageUrl: imageUrl.text.trim(),
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )),
        ],
      ),
    );
  }
}

/// Photo chooser used by both edit dialogs: a preview, an "Upload photo"
/// button (gallery -> resized -> stored in the document), and a plain URL
/// field for admins who would rather paste a link.
class _PhotoField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> busy;
  final String name;
  final String category;

  /// Shown in the preview while [controller] is empty (e.g. the bundled photo).
  final String fallbackPreview;

  const _PhotoField({
    required this.controller,
    required this.busy,
    required this.name,
    required this.category,
    this.fallbackPreview = '',
  });

  @override
  ConsumerState<_PhotoField> createState() => _PhotoFieldState();
}

class _PhotoFieldState extends ConsumerState<_PhotoField> {
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    widget.busy.value = true;
    try {
      final uri = await ref.read(photoPickerServiceProvider).pickAsDataUri();
      if (uri != null) widget.controller.text = uri;
    } on PhotoTooLargeException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = 'Could not load that photo: ${friendlyError(e)}';
    } finally {
      widget.busy.value = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = widget.controller.text.trim();
    final uploaded = isDataImage(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FoodThumb(
              imageUrl: value.isEmpty ? widget.fallbackPreview : value,
              name: widget.name,
              category: widget.category,
              size: 72,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.busy,
                    builder: (context, isBusy, _) => OutlinedButton.icon(
                      onPressed: isBusy ? null : _pick,
                      icon: isBusy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(isBusy ? 'Loading...' : 'Upload photo'),
                    ),
                  ),
                  if (value.isNotEmpty)
                    TextButton(onPressed: widget.controller.clear, child: const Text('Remove')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (uploaded)
          Text(
            'Uploaded photo - ${(value.length * 3 / 4 / 1024).round()} KB',
            style: TextStyle(fontSize: 12, color: p.redDeep),
          )
        else
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: '...or paste a photo URL', helperText: 'https image link (optional)'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: TextStyle(fontSize: 12, color: p.danger)),
          ),
      ],
    );
  }
}
