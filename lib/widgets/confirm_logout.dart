import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/role_selector_screen.dart';

/// Asks "Log out?" and, on confirmation, signs out and returns to the role
/// selector. Shared by the rider and admin screens (the admin dashboard
/// previously had no way to log out at all, and the rider's logout button
/// fired instantly with no confirmation).
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to log in again to continue.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const RoleSelectorScreen()),
    (route) => false,
  );
}
