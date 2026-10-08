import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
              itemCount: docs.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  leading: const Icon(Icons.category_rounded),
                  title: Text('${docs[i].data()['name']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('categories')
                        .doc(docs[i].id)
                        .delete(),
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
