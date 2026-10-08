import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/error_mapper.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/ui_kit.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: ContentWidth(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').limit(30).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (docs.isEmpty) {
              return const EmptyState(icon: Icons.people_outline_rounded, message: 'No users yet.');
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                final role = (m['role'] ?? 'customer') as String;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      role == 'admin'
                          ? Icons.admin_panel_settings_rounded
                          : role == 'rider'
                              ? Icons.delivery_dining_rounded
                              : Icons.person_outline_rounded,
                    ),
                    title: Text('${m['name']}'),
                    subtitle: Text('${m['email']} • $role'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => FirebaseFirestore.instance
                          .collection('users')
                          .doc(docs[i].id)
                          .update({'role': v}),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'customer', child: Text('Make customer')),
                        PopupMenuItem(value: 'rider', child: Text('Make rider')),
                        PopupMenuItem(value: 'admin', child: Text('Make admin')),
                      ],
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
          builder: (_) => const _RiderForm(),
        ),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add rider'),
      ),
    );
  }
}

class _RiderForm extends StatefulWidget {
  const _RiderForm();
  @override
  State<_RiderForm> createState() => _RiderFormState();
}

class _RiderFormState extends State<_RiderForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _phone = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await AuthService().createRiderAccount(
        name: _name.text,
        email: _email.text,
        password: _pw.text,
        phone: _phone.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rider ${_email.text.trim()} created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
            const Text('Add rider', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Creates a rider login. The admin stays signed in.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            AppTextField(controller: _name, label: 'Name',
                validator: (v) => validateRequired(v, 'rider name')),
            const SizedBox(height: 8),
            AppTextField(controller: _email, label: 'Email',
                validator: validateEmail,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            AppTextField(controller: _pw, label: 'Password',
                validator: validatePassword, obscure: true),
            const SizedBox(height: 8),
            AppTextField(controller: _phone, label: 'Phone (optional)',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Create rider', loading: _sending, onPressed: _submit),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
