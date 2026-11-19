import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/role_pill.dart';
import '../../l10n/l10n_extensions.dart';
import '../customer/restaurant_list_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../rider/rider_home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (!Validators.isValidEmail(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your email above first, then tap "Forgot password?".')),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      messenger.showSnackBar(SnackBar(content: Text('Password reset link sent to $email.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AuthService.messageFor(e))));
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).login(_email.text.trim(), _password.text, widget.role);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final p = context.palette;

    ref.listen(authProvider, (prev, next) {
      if (next.user != null && prev?.user == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => _homeFor(next.user!.role)),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(child: RolePill(role: widget.role)),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    child: Semantics(
                      header: true,
                      child: Text(context.l10n.welcomeBack, style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeSlideIn(
                    index: 1,
                    child: Text(context.l10n.loginSubtitle, style: TextStyle(color: p.inkSoft)),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    index: 2,
                    child: CustomTextField(
                      controller: _email,
                      label: context.l10n.emailLabel,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !auth.loading,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your email';
                        if (!Validators.isValidEmail(v)) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                  ),
                  FadeSlideIn(
                    index: 3,
                    child: CustomTextField(
                      controller: _password,
                      label: context.l10n.passwordLabel,
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !auth.loading,
                      onSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: auth.loading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: auth.error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ErrorBanner(message: auth.error!),
                          ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    index: 4,
                    child: CustomButton(
                      label: context.l10n.logIn,
                      loading: auth.loading,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 5,
                    child: CustomButton(
                      label: context.l10n.createAnAccount,
                      outlined: true,
                      onPressed: auth.loading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SignupScreen(role: widget.role)),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
