import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/promo.dart';
import '../../services/promo_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/error_mapper.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

/// Admin screen for promo codes. Codes live in Firestore so they can be
/// created, paused or expired without shipping a new build.
class AdminPromosScreen extends StatelessWidget {
  const AdminPromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promo Codes')),
      body: ContentWidth(
        maxWidth: 720,
        child: StreamBuilder<List<Promo>>(
          stream: PromoService().watchAll(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final promos = snap.data ?? const [];
            return promos.isEmpty
                ? const EmptyState(
                    icon: Icons.local_offer_outlined,
                    message: 'No promo codes yet.',
                    actionLabel: 'Create promo',
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(context.pagePadding),
                    itemCount: promos.length,
                    itemBuilder: (_, i) {
                      final p = promos[i];
                      return Entrance(
                        delay: Duration(milliseconds: (i * 40).clamp(0, 240)),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            p.code,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5),
                                          ),
                                          const SizedBox(width: 8),
                                          _stateChip(p),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _describe(p),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: p.active,
                                  onChanged: (v) =>
                                      _toggle(context, p.code, v),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error),
                                  tooltip: 'Delete',
                                  onPressed: () => _delete(context, p.code),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _PromoForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New promo'),
      ),
    );
  }

  static String _describe(Promo p) {
    final parts = <String>[];
    switch (p.type) {
      case 'percent':
        parts.add('${p.value.toStringAsFixed(0)}% off');
        break;
      case 'fixed':
        parts.add('${p.value.toStringAsFixed(0)} off');
        break;
      case 'freeship':
        parts.add('Free delivery');
        break;
    }
    if (p.minSubtotal > 0) {
      parts.add('min spend ${p.minSubtotal.toStringAsFixed(0)}');
    }
    if (p.expiresAt != null) {
      parts.add('ends ${p.expiresAt!.toIso8601String().substring(0, 10)}');
    }
    if (p.maxUses > 0) {
      parts.add('${p.used}/${p.maxUses} used');
    }
    return parts.isEmpty ? 'No discount configured' : parts.join('  •  ');
  }

  Widget _stateChip(Promo p) {
    final (label, color, bg) = !p.active
        ? ('Inactive', AppColors.muted, AppColors.shimmer)
        : p.isExpired
            ? ('Expired', AppColors.error, AppColors.errorBg)
            : p.isUsedUp
                ? ('Used up', AppColors.warning, AppColors.warningBg)
                : ('Live', AppColors.success, AppColors.successBg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Future<void> _toggle(
      BuildContext context, String code, bool active) async {
    try {
      await PromoService().setActive(code, active);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _delete(BuildContext context, String code) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete promo?'),
        content: Text('Code $code will stop working immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PromoService().delete(code);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

class _PromoForm extends StatefulWidget {
  const _PromoForm();
  @override
  State<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends State<_PromoForm> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _min = TextEditingController(text: '0');
  final _uses = TextEditingController(text: '0');
  String _type = 'percent';
  bool _active = true;
  DateTime? _expires;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _min.dispose();
    _uses.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PromoService().save(
        code: _code.text,
        type: _type,
        value: _type == 'freeship'
            ? 0
            : double.tryParse(_value.text) ?? 0,
        active: _active,
        minSubtotal: double.tryParse(_min.text) ?? 0,
        maxUses: int.tryParse(_uses.text) ?? 0,
        expiresAt: _expires,
      );
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New promo code',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _code,
                label: 'Code',
                hint: 'e.g. SUMMER25',
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Enter a code';
                  if (t.contains(' ')) return 'No spaces allowed';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Discount type'),
                items: const [
                  DropdownMenuItem(
                      value: 'percent', child: Text('Percentage off')),
                  DropdownMenuItem(
                      value: 'fixed', child: Text('Fixed amount off')),
                  DropdownMenuItem(
                      value: 'freeship', child: Text('Free delivery')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'percent'),
              ),
              if (_type != 'freeship') ...[
                const SizedBox(height: 8),
                AppTextField(
                  controller: _value,
                  label: _type == 'percent' ? 'Percent (1-100)' : 'Amount',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a value above 0';
                    if (_type == 'percent' && n > 100) {
                      return 'Max 100';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              AppTextField(
                controller: _min,
                label: 'Minimum spend (0 = none)',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '0');
                  if (n == null || n < 0) return 'Enter 0 or more';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _uses,
                label: 'Max uses (0 = unlimited)',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '0');
                  if (n == null || n < 0) return 'Enter 0 or more';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: DateTime(now.year + 3),
                  );
                  if (picked != null) setState(() => _expires = picked);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(_expires == null
                    ? 'No expiry'
                    : 'Expires ${_expires!.toIso8601String().substring(0, 10)}'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Inactive codes cannot be applied',
                    style: TextStyle(fontSize: 12)),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Save promo',
                loading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}