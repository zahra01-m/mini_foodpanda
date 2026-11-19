import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/error_text.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/l10n_extensions.dart';
import '../../widgets/custom_button.dart';
import '../auth/role_selector_screen.dart';
import 'notifications_screen.dart';
import 'saved_addresses_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logOut),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.logOut)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // The cart is saved on the device, so don't leave it for the next person.
    ref.read(cartProvider.notifier).clear();
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
      (route) => false,
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, AppUser user) async {
    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => Validators.isNotEmpty(v ?? '') ? null : 'Enter your name',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (v) => Validators.isValidPhone(v ?? '') ? null : 'Enter a valid phone number',
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
    );
    if (saved != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    try {
      await ref.read(authProvider.notifier).updateProfile(name.text.trim(), phone.text.trim());
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
    final unread = notifications.where((n) => !n.read).length;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: user == null
          ? Center(child: Text(context.l10n.notLoggedIn))
          // Scrollable: the old fixed Column overflowed on small screens
          // and in landscape.
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: p.redTint,
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 28, color: p.redDeep)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(user.email, style: TextStyle(color: p.inkSoft), textAlign: TextAlign.center),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.phone, style: TextStyle(color: p.inkSoft), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, color: p.redDeep),
                    title: const Text('Edit profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editProfile(context, ref, user),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.notifications_outlined, color: p.redDeep),
                    title: Text(context.l10n.notifications),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 10,
                            backgroundColor: p.red,
                            child: Text('$unread', style: TextStyle(fontSize: 11, color: p.onRed)),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.place_outlined, color: p.redDeep),
                    title: const Text('Saved addresses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.dark_mode_outlined, color: p.redDeep),
                          const SizedBox(width: 12),
                          Expanded(child: Text(context.l10n.appearance)),
                        ]),
                        const SizedBox(height: 10),
                        SegmentedButton<ThemeMode>(
                          expandedInsets: EdgeInsets.zero,
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined, size: 16),
                                tooltip: 'Light'),
                            ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_outlined, size: 16),
                                tooltip: 'System'),
                            ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined, size: 16),
                                tooltip: 'Dark'),
                          ],
                          selected: {ref.watch(themeModeProvider)},
                          onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).state = s.first,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.language_outlined, color: p.redDeep),
                          const SizedBox(width: 12),
                          Expanded(child: Text(context.l10n.language)),
                        ]),
                        const SizedBox(height: 10),
                        SegmentedButton<Locale?>(
                          expandedInsets: EdgeInsets.zero,
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: null, label: Text(context.l10n.languageAuto)),
                            const ButtonSegment(value: Locale('en'), label: Text('EN')),
                            const ButtonSegment(value: Locale('ur'), label: Text('اردو')),
                          ],
                          selected: {ref.watch(localeProvider)},
                          onSelectionChanged: (s) => ref.read(localeProvider.notifier).state = s.first,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: context.l10n.logOut,
                  outlined: true,
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ],
            ),
    );
  }
}
