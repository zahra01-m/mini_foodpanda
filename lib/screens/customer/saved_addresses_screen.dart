import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_palette.dart';
import '../../models/saved_address.dart';
import '../../providers/address_book_provider.dart';
import '../../widgets/empty_state.dart';

/// Manage the delivery addresses saved on this device. Until now they
/// could only be created (and deleted) in the middle of checkout.
class SavedAddressesScreen extends ConsumerWidget {
  const SavedAddressesScreen({super.key});

  static const _labels = ['Home', 'Work', 'Other'];

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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SavedAddress a) async {
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
    if (ok == true) ref.read(addressBookProvider.notifier).remove(a.id);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, SavedAddress? existing) async {
    final controller = TextEditingController(text: existing?.address);
    final formKey = GlobalKey<FormState>();
    var label = existing?.label ?? 'Home';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add address' : 'Edit address'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final l in _labels)
                        ChoiceChip(
                          avatar: Icon(_iconFor(l), size: 16),
                          label: Text(l),
                          selected: label == l,
                          onSelected: (_) => setLocal(() => label = l),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.streetAddress,
                    decoration: const InputDecoration(labelText: 'Street, house no., area'),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Enter your full address (street, house no., area)'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    ref.read(addressBookProvider.notifier).upsert(SavedAddress(
          id: existing?.id ?? const Uuid().v4(),
          label: label,
          address: controller.text.trim(),
          lat: existing?.lat,
          lng: existing?.lng,
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressBookProvider);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        backgroundColor: p.red,
        foregroundColor: p.onRed,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add address'),
      ),
      body: addresses.isEmpty
          ? const EmptyState(
              icon: Icons.place_outlined,
              title: 'No saved addresses',
              subtitle: 'Save your home or work address to check out faster.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = addresses[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p.redTint,
                      child: Icon(_iconFor(a.label), color: p.redDeep, size: 20),
                    ),
                    title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(a.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _edit(context, ref, a),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: p.danger),
                      tooltip: 'Delete ${a.label}',
                      onPressed: () => _confirmDelete(context, ref, a),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
