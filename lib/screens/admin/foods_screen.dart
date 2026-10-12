import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_service.dart';
import '../../services/menu_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/error_mapper.dart';
import '../../utils/formatters.dart';
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
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                final avail = (m['available'] ?? true) as bool;
                return Entrance(
                  delay:
                      Duration(milliseconds: (i * 40).clamp(0, 320)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: FoodImage(
                                  (m['image'] ?? '') as String),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('${m['name']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  formatPeso(
                                      ((m['price'] ?? 0) as num)
                                          .toDouble()),
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  avail
                                      ? 'Available'
                                      : 'Hidden',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: avail
                                          ? AppColors.success
                                          : AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: avail,
                                onChanged: (v) =>
                                    FirebaseFirestore
                                        .instance
                                        .collection('foods')
                                        .doc(docs[i].id)
                                        .update(
                                            {'available': v}),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete food?'),
                                      content: Text(
                                          '"${m['name']}" will be hidden from the menu.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await FirebaseFirestore
                                        .instance
                                        .collection('foods')
                                        .doc(docs[i].id)
                                        .delete();
                                  }
                                },
                              ),
                            ],
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
  final _time = TextEditingController(text: '20 min');
  String? _category;
  List<int>? _imageBytes;
  String _imageName = 'food.jpg';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 75,
      );
      if (x == null) return;
      final raw = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = ImageService().compressReceipt(raw.toList());
        _imageName = x.name.isEmpty ? 'food.jpg' : x.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('foods').add({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.tryParse(_price.text) ?? 0,
        'rating': 0,
        'ratingCount': 0,
        'image': 'assets/images/b1.jpg',
        'category': _category,
        'deliveryTime': _time.text.trim().isEmpty ? '20 min' : _time.text.trim(),
        'available': true,
        'options': <String>[],
      });
      if (_imageBytes != null) {
        try {
          await ImageService()
              .uploadFoodImage(ref.id, _imageBytes!, _imageName);
        } catch (_) {
          // Doc already created with fallback image; admin can retry.
        }
      }
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
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add food', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              AppTextField(controller: _name, label: 'Name', validator: (v) => v!.trim().isEmpty ? 'Enter name' : null),
              const SizedBox(height: 8),
              AppTextField(
                controller: _price,
                label: 'Price',
                keyboardType: TextInputType.number,
                validator: (v) {
                  final p = double.tryParse(v ?? '');
                  if (p == null || p <= 0) return 'Enter a price above 0';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snap) {
                  final cats = snap.data?.docs ?? [];
                  return DropdownButtonFormField<String>(
                    initialValue: cats.any((c) => c.id == _category) ? _category : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in cats)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text((c.data()['name'] ?? c.id) as String),
                        ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Pick a category' : null,
                  );
                },
              ),
              const SizedBox(height: 8),
              AppTextField(controller: _desc, label: 'Description', maxLines: 2),
              const SizedBox(height: 8),
              AppTextField(controller: _time, label: 'Delivery time (e.g. 20 min)'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(_imageBytes == null ? 'Add photo (optional)' : 'Photo attached'),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save',
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
