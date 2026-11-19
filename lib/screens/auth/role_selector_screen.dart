import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../models/user_model.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/tap_bounce.dart';
import '../../l10n/l10n_extensions.dart';
import 'login_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [p.bg, p.beige1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // Scrollable so the three role cards never overflow on short
          // screens, in landscape, or with large accessibility text.
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      FadeSlideIn(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: p.heroGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: p.red.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        index: 1,
                        child: Semantics(
                          header: true,
                          child: Text(context.l10n.appTitle, style: Theme.of(context).textTheme.headlineLarge),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        index: 2,
                        child: Text(context.l10n.roleTagline, style: TextStyle(color: p.inkSoft, fontSize: 16)),
                      ),
                      const SizedBox(height: 30),
                      FadeSlideIn(
                        index: 3,
                        child: _RoleTile(
                          icon: Icons.person_rounded,
                          label: context.l10n.roleCustomer,
                          subtitle: context.l10n.roleCustomerSubtitle,
                          onTap: () => _go(context, UserRole.customer),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 4,
                        child: _RoleTile(
                          icon: Icons.two_wheeler_rounded,
                          label: context.l10n.roleRider,
                          subtitle: context.l10n.roleRiderSubtitle,
                          onTap: () => _go(context, UserRole.rider),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 5,
                        child: _RoleTile(
                          icon: Icons.admin_panel_settings_rounded,
                          label: context.l10n.roleAdmin,
                          subtitle: context.l10n.roleAdminSubtitle,
                          onTap: () => _go(context, UserRole.admin),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, UserRole role) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(role: role)));
  }
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: TapBounce(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: p.redTint, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: p.redDeep, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: p.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
