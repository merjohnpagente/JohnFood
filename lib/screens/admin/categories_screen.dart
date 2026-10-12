import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/motion.dart';
import '../../utils/responsive.dart';
import '../../widgets/ui_kit.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ContentWidth(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (docs.isEmpty) {
              return const EmptyState(icon: Icons.category_outlined, message: 'No categories. Import sample menu.');
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) => Entrance(
                delay:
                    Duration(milliseconds: (i * 40).clamp(0, 320)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.tint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.category_rounded,
                          color: AppColors.primary),
                    ),
                    title: Text('${docs[i].data()['name']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    trailing: IconButton(
                      icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete category?'),
                            content: Text(
                                '"${docs[i].data()['name']}" will be removed. Foods in it stay but lose their filter.'),
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
                          await FirebaseFirestore.instance
                              .collection('categories')
                              .doc(docs[i].id)
                              .delete();
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final c = TextEditingController();
          String icon = 'fastfood';
          const icons = {
            'fastfood': Icons.fastfood_rounded,
            'drinks': Icons.local_drink_rounded,
            'dessert': Icons.cake_rounded,
            'pizza': Icons.local_pizza_rounded,
            'healthy': Icons.eco_rounded,
            'breakfast': Icons.breakfast_dining_rounded,
          };
          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (_) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Add category'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(controller: c, label: 'Name'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: icon,
                      decoration:
                          const InputDecoration(labelText: 'Icon'),
                      items: [
                        for (final e in icons.entries)
                          DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(e.value,
                                    size: 18,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(e.key),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => icon = v ?? icon),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(
                          context, {'name': c.text.trim(), 'icon': icon}),
                      child: const Text('Save')),
                ],
              ),
            ),
          );
          c.dispose();
          final name = result?['name'] ?? '';
          if (name.isNotEmpty) {
            await FirebaseFirestore.instance.collection('categories').add({
              'name': name,
              'icon': result!['icon'],
              'order': DateTime.now().millisecondsSinceEpoch,
            });
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
