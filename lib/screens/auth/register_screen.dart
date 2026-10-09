import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/error_mapper.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/ui_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().register(_name.text, _email.text, _pw.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, vp) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: vp.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: EdgeInsets.all(context.pagePadding),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                      ),
                    ),
                    const Center(child: Entrance(child: BrandLogo(size: 72, iconSize: 38))),
                    const SizedBox(height: 16),
                    const Entrance(
                      delay: Duration(milliseconds: 60),
                      child: Text('Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3)),
                    ),
                    const SizedBox(height: 4),
                    const Entrance(
                      delay: Duration(milliseconds: 120),
                      child: Text('Join John Foods and enjoy great meals!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: AppColors.muted)),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      ),
                    Entrance(
                      delay: const Duration(milliseconds: 160),
                      child: AppTextField(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Full name',
                        prefix: const Icon(Icons.person_outline_rounded,
                            color: AppColors.muted, size: 20),
                        validator: (v) =>
                            validateRequired(v, 'your name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Entrance(
                      delay: const Duration(milliseconds: 200),
                      child: AppTextField(
                        controller: _email,
                        label: 'Email address',
                        hint: 'Email address',
                        prefix: const Icon(Icons.mail_outline_rounded,
                            color: AppColors.muted, size: 20),
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Entrance(
                      delay: const Duration(milliseconds: 240),
                      child: AppTextField(
                        controller: _pw,
                        label: 'Password',
                        hint: 'Password',
                        prefix: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.muted, size: 20),
                        validator: validatePassword,
                        obscure: _obscure,
                        textInputAction: TextInputAction.done,
                        suffix: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                        label: 'Sign Up',
                        loading: _loading,
                        onPressed: _submit),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(color: AppColors.muted)),
                        TextButton(
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Log in',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    ),
  );
  }
}
