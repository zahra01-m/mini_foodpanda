import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'auth/role_selector_screen.dart';
import 'onboarding_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'rider/rider_home_screen.dart';
import 'customer/restaurant_list_screen.dart';

/// A short branded splash: logo scales/fades in, then the app fades
/// through into the role selector — or, if Firebase Auth already has a
/// persisted session (see AuthNotifier._restoreSession), straight into
/// that user's home screen so they don't have to log in every launch.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _scale =
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      // First launch while logged out -> short intro before the role selector.
      final showIntro = user == null && await OnboardingScreen.shouldShow();
      if (!mounted) return;
      final Widget next = user != null
          ? _homeFor(user.role)
          : (showIntro ? const OnboardingScreen() : const RoleSelectorScreen());
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: next),
        ),
      );
    });
  }

  Widget _homeFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.rider:
        return const RiderHomeScreen();
      case UserRole.customer:
        return const RestaurantListScreen();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Mini FoodPanda',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white, fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Good food, delivered fast',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
