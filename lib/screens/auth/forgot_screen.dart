import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_mapper.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/ui_kit.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      await AuthService().sendReset(_email.text);
      setState(() => _msg = 'Reset link sent. Check your email.');
    } catch (e) {
      setState(() => _msg = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: ContentWidth(
        maxWidth: 640,
        child: Padding(
          padding: EdgeInsets.all(context.pagePadding),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_msg != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_msg!)),
                      ],
                    ),
                  ),
                AppTextField(controller: _email, label: 'Email', validator: validateEmail, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Send reset link', loading: _loading, onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
