import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_palette.dart';
import '../widgets/custom_button.dart';
import 'auth/role_selector_screen.dart';

const _kSeenKey = 'onboarding_seen';

/// Three-page intro shown once, the first time the app is opened while
/// logged out. Remembers it was seen (and never blocks the app if storage
/// is unavailable).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_kSeenKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _Page(Icons.restaurant_menu_rounded, 'Discover great food',
        'Browse restaurants near you, search by cuisine and save your favourites.'),
    _Page(Icons.delivery_dining_rounded, 'Track every step',
        'Watch your order go from the kitchen to your door, live.'),
    _Page(Icons.verified_rounded, 'Order your way',
        'Pay by card or cash on delivery, and reorder your favourites in one tap.'),
  ];

  final _controller = PageController();
  int _page = 0;

  bool get _last => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSeenKey, true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const RoleSelectorScreen()),
      ),
    );
  }

  void _next() {
    if (_last) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [p.bg, p.beige1], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Visibility(
                    visible: !_last,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(onPressed: _finish, child: const Text('Skip')),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.55),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.85, end: 1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                              builder: (context, v, child) => Transform.scale(scale: v, child: child),
                              child: Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: p.heroGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: p.red.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14)),
                                  ],
                                ),
                                child: Icon(page.icon, size: 92, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Semantics(
                              header: true,
                              child: Text(page.title,
                                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                            ),
                            const SizedBox(height: 12),
                            Text(page.body,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.inkSoft, fontSize: 16, height: 1.45)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? p.red : p.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: CustomButton(label: _last ? 'Get started' : 'Next', onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
