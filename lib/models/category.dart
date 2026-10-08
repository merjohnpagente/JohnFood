import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final int order;

  const Category({required this.id, required this.name, required this.icon, required this.order});

  factory Category.fromMap(String id, Map<String, dynamic> m) => Category(
        id: id,
        name: (m['name'] ?? '') as String,
        icon: (m['icon'] ?? 'fastfood') as String,
        order: ((m['order'] ?? 0) as num).toInt(),
      );

  Map<String, dynamic> toMap() => {'name': name, 'icon': icon, 'order': order};

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Category.fromMap(d.id, d.data() ?? {});
}
