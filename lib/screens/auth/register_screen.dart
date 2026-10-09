import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 640,
          child: Padding(
            padding: EdgeInsets.all(context.pagePadding),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  AppTextField(controller: _name, label: 'Name', validator: (v) => validateRequired(v, 'your name')),
                  const SizedBox(height: 12),
                  AppTextField(controller: _email, label: 'Email', validator: validateEmail, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  AppTextField(controller: _pw, label: 'Password', validator: validatePassword, obscure: true, textInputAction: TextInputAction.done),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
