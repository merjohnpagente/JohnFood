import 'package:flutter/material.dart';

import '../../models/merchant_settings.dart';
import '../../services/menu_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/error_mapper.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/ui_kit.dart';

/// Merchant details the customers need: which GCash/Maya number to pay,
/// plus one-tap sample menu import for a fresh database.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      maxWidth: 640,
      child: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          const Text('Merchant details',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Shown at checkout so customers know where to send the payment.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          StreamBuilder<MerchantSettings>(
            stream: PaymentService().watchSettings(),
            builder: (context, snap) {
              final s = snap.data ?? const MerchantSettings();
              return Entrance(child: _MerchantForm(initial: s));
            },
          ),
          const SizedBox(height: 24),
          const Text('Menu',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_rounded,
                  color: AppColors.primary),
              title: const Text('Import sample menu'),
              subtitle: const Text(
                'Adds starter categories and foods. Existing items stay.',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                try {
                  await MenuService().importSampleMenu();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample menu imported')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyError(e))),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantForm extends StatefulWidget {
  final MerchantSettings initial;
  const _MerchantForm({required this.initial});
  @override
  State<_MerchantForm> createState() => _MerchantFormState();
}

class _MerchantFormState extends State<_MerchantForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _gcash =
      TextEditingController(text: widget.initial.gcashNumber);
  late final _maya = TextEditingController(text: widget.initial.mayaNumber);
  late final _address =
      TextEditingController(text: widget.initial.address);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _gcash.dispose();
    _maya.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PaymentService().save(MerchantSettings(
        name: _name.text,
        gcashNumber: _gcash.text,
        mayaNumber: _maya.text,
        address: _address.text,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _name,
                label: 'Business name',
                validator: (v) => validateRequired(v, 'business name'),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _gcash,
                label: 'GCash number',
                hint: '09xx xxx xxxx',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _maya,
                label: 'Maya number',
                hint: '09xx xxx xxxx',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _address,
                label: 'Pickup address (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save details',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}