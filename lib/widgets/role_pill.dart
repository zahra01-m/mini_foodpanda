import 'package:flutter/material.dart';
import '../core/theme/app_palette.dart';
import '../l10n/l10n_extensions.dart';
import '../models/user_model.dart';

/// Small "Customer / Rider / Admin" pill for the login and signup screens,
/// so people can see which kind of account they are signing in to (the
/// role was chosen one screen earlier and then never shown again).
class RolePill extends StatelessWidget {
  final UserRole role;
  const RolePill({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final IconData icon;
    final String label;
    switch (role) {
      case UserRole.customer:
        icon = Icons.person_rounded;
        label = context.l10n.roleCustomer;
      case UserRole.rider:
        icon = Icons.two_wheeler_rounded;
        label = context.l10n.roleRider;
      case UserRole.admin:
        icon = Icons.admin_panel_settings_rounded;
        label = context.l10n.roleAdmin;
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: p.redDeep),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: p.redDeep, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
