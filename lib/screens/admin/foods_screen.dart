import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/menu_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

class FoodsScreen extends StatelessWidget {
  const FoodsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Import sample menu',
            onPressed: () async {
              await MenuService().importSampleMenu();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample menu imported')),
                );
              }
            },
          ),
        ],
      ),
      body: ContentWidth(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('foods').limit(30).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (docs.isEmpty) {
              return const EmptyState(icon: Icons.fastfood_outlined, message: 'No foods. Import sample menu.');
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                final avail = (m['available'] ?? true) as bool;
                return Card(
                  child: SwitchListTile(
                    title: Text('${m['name']}'),
                    subtitle: Text('${m['price']}'),
                    value: avail,
                    onChanged: (v) => FirebaseFirestore.instance
                        .collection('foods')
                        .doc(docs[i].id)
                        .update({'available': v}),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => FirebaseFirestore.instance
                          .collection('foods')
                          .doc(docs[i].id)
                          .delete(),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _FoodForm(),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FoodForm extends StatefulWidget {
  const _FoodForm();
  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final _cat = TextEditingController(text: 'burgers');

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    _cat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add food', style: TextStyle(fontWeight: FontWeight.w700)),
            AppTextField(controller: _name, label: 'Name', validator: (v) => v!.isEmpty ? 'Enter name' : null),
            const SizedBox(height: 8),
            AppTextField(controller: _price, label: 'Price', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Enter price' : null),
            const SizedBox(height: 8),
            AppTextField(controller: _cat, label: 'Category id', validator: (v) => v!.isEmpty ? 'Enter category' : null),
            const SizedBox(height: 8),
            AppTextField(controller: _desc, label: 'Description', maxLines: 2),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                await FirebaseFirestore.instance.collection('foods').add({
                  'name': _name.text.trim(),
                  'description': _desc.text.trim(),
                  'price': double.tryParse(_price.text) ?? 0,
                  'rating': 4.5,
                  'ratingCount': 0,
                  'image': 'assets/images/b1.jpg',
                  'category': _cat.text.trim(),
                  'deliveryTime': '20 min',
                  'available': true,
                  'options': <String>[],
                });
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
