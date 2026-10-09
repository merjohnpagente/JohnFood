import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/responsive.dart';
import '../utils/validators.dart';
import '../widgets/ui_kit.dart';

/// Saved delivery addresses stored on the user's Firestore document,
/// so they survive refresh, reinstall and device changes.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _saving = false;

  Future<void> _save(List<String> addresses) async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      await AuthService().updateAddresses(uid, addresses);
      if (mounted) await context.read<AuthProvider>().refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addDialog(List<String> current) async {
    final c = TextEditingController();
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add address'),
        content: Form(
          key: form,
          child: AppTextField(
            controller: c,
            label: 'Delivery address',
            hint: 'Street, barangay, city',
            validator: (v) => validateRequired(v, 'address'),
            textInputAction: TextInputAction.done,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, c.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    if (value != null && value.isNotEmpty) {
      await _save([...current, value]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final addresses = user?.addresses ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: ContentWidth(
        maxWidth: 640,
        child: addresses.isEmpty
            ? const EmptyState(
                icon: Icons.location_on_outlined,
                message: 'No saved addresses yet.',
              )
            : ListView.builder(
                padding: EdgeInsets.all(context.pagePadding),
                itemCount: addresses.length,
                itemBuilder: (_, i) => Entrance(
                  delay: Duration(milliseconds: (i * 50).clamp(0, 250)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.tint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary),
                      ),
                      title: Text(addresses[i],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: i == 0
                          ? const Text('Default address',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))
                          : null,
                      trailing: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error),
                              tooltip: 'Remove',
                              onPressed: () {
                                final next = [...addresses]
                                  ..removeAt(i);
                                _save(next);
                              },
                            ),
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: BottomActionBar(
        label: _saving ? 'Saving...' : 'Add address',
        onPressed: _saving ? null : () => _addDialog(addresses),
      ),
    );
  }
}
