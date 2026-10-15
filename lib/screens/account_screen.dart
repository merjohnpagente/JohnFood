import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/error_mapper.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import '../widgets/ui_kit.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            Entrance(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role ?? 'customer',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Entrance(
              delay: const Duration(milliseconds: 60),
              child: Card(
                child: Column(
                  children: [
                    MenuTile(
                      icon: Icons.badge_outlined,
                      title: 'Edit profile',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _EditProfileSheet(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    MenuTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change password',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const _ChangePasswordSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Entrance(
              delay: const Duration(milliseconds: 120),
              child: Text(
                'Deleting your account removes your profile and login. Past '
                'orders stay visible to the merchant for their records.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 8),
            Entrance(
              delay: const Duration(milliseconds: 160),
              child: Card(
                child: MenuTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete account',
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  onTap: () => _confirmDelete(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This removes your profile and signs you out everywhere on this '
            'device. It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService().deleteAccount();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name.text = u?.name ?? '';
    _phone.text = u?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    setState(() => _saving = true);
    try {
      await AuthService().updateProfile(uid,
          name: _name.text, phone: _phone.text);
      await context.read<AuthProvider>().refresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit profile',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppTextField(
              controller: _name,
              label: 'Name',
              validator: (v) => validateRequired(v, 'name'),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _phone,
              label: 'Contact number',
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? null : validatePhone(v),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Save', loading: _saving, onPressed: _save),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService().changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Change password',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppTextField(
              controller: _current,
              label: 'Current password',
              obscure: _obscure,
              validator: (v) => validateRequired(v, 'current password'),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _next,
              label: 'New password',
              obscure: _obscure,
              validator: validatePassword,
              suffix: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Update password',
                loading: _saving,
                onPressed: _save),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                try {
                  await AuthService().sendPasswordReset();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Reset link sent to your email')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(friendlyError(e))));
                  }
                }
              },
              icon: const Icon(Icons.outgoing_mail, size: 18),
              label: const Text('Email me a reset link instead'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}