import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final double rating;
  final int ratingCount;
  final String image;
  final String category;
  final String deliveryTime;
  final bool available;
  final List<String> options;

  const Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.ratingCount,
    required this.image,
    required this.category,
    required this.deliveryTime,
    required this.available,
    this.options = const [],
  });

  factory Food.fromMap(String id, Map<String, dynamic> m) => Food(
        id: id,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        price: ((m['price'] ?? 0) as num).toDouble(),
        rating: ((m['rating'] ?? 0) as num).toDouble(),
        ratingCount: ((m['ratingCount'] ?? 0) as num).toInt(),
        image: (m['image'] ?? '') as String,
        category: (m['category'] ?? '') as String,
        deliveryTime: (m['deliveryTime'] ?? '25 min') as String,
        available: (m['available'] ?? true) as bool,
        options: ((m['options'] ?? []) as List).map((e) => '$e').toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'rating': rating,
        'ratingCount': ratingCount,
        'image': image,
        'category': category,
        'deliveryTime': deliveryTime,
        'available': available,
        'options': options,
      };

  factory Food.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Food.fromMap(d.id, d.data() ?? {});
}
