import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/role_pill.dart';
import '../../l10n/l10n_extensions.dart';
import '../customer/restaurant_list_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../rider/rider_home_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const SignupScreen({super.key, required this.role});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  /// "0300 123-4567" -> "03001234567" so spaces/dashes don't fail validation.
  String _cleanPhone(String v) => v.replaceAll(RegExp(r'[\s\-()]'), '');

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
          _cleanPhone(_phone.text),
          widget.role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
      appBar: AppBar(title: Text(context.l10n.signupTitle)),
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
                  RolePill(role: widget.role),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _name,
                    label: context.l10n.fullNameLabel,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !auth.loading,
                    validator: (v) => Validators.isNotEmpty(v ?? '') ? null : 'Enter your full name',
                  ),
                  CustomTextField(
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
                  CustomTextField(
                    controller: _phone,
                    label: context.l10n.phoneLabel,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    enabled: !auth.loading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                      if (!Validators.isValidPhone(_cleanPhone(v))) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _password,
                    label: context.l10n.passwordLabel,
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !auth.loading,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || v.length < 6) ? 'Use at least 6 characters' : null,
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
                  const SizedBox(height: 8),
                  CustomButton(label: context.l10n.signUp, loading: auth.loading, onPressed: _submit),
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
