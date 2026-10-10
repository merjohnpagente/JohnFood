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
                      onPressed: () => FirebaseFirestore
                          .instance
                          .collection('categories')
                          .doc(docs[i].id)
                          .delete(),
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
          final name = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Add category'),
              content: AppTextField(controller: c, label: 'Name'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Save')),
              ],
            ),
          );
          if (name != null && name.isNotEmpty) {
            await FirebaseFirestore.instance.collection('categories').add({
              'name': name,
              'icon': 'fastfood',
              'order': DateTime.now().millisecondsSinceEpoch,
            });
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
