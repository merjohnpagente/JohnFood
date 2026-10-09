import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../data/sample_data.dart';
import '../models/category.dart';
import '../models/food.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Category>> watchCategories() {
    return _db.collection('categories').orderBy('order').snapshots().map(
      (s) {
        if (s.docs.isEmpty) {
          return sampleCategories
              .map((c) => Category(id: c.id, name: c.name, icon: c.icon, order: c.order))
              .toList();
        }
        return s.docs.map(Category.fromDoc).toList();
      },
    );
  }

  Stream<List<Food>> watchFoods({String? category, int limit = 20}) {
    Query<Map<String, dynamic>> q =
        _db.collection('foods').where('available', isEqualTo: true).limit(limit);
    if (category != null && category.isNotEmpty) {
      q = _db
          .collection('foods')
          .where('category', isEqualTo: category)
          .where('available', isEqualTo: true)
          .limit(limit);
    }
    return q.snapshots().map((s) {
      if (s.docs.isEmpty) {
        final all = sampleFoods.map(
          (f) => Food(
            id: f.id,
            name: f.name,
            description: f.description,
            price: f.price,
            rating: f.rating,
            ratingCount: 50,
            image: f.image,
            category: f.category,
            deliveryTime: f.deliveryTime,
            available: true,
          ),
        );
        if (category == null || category.isEmpty) return all.toList();
        return all.where((f) => f.category == category).toList();
      }
      return s.docs.map(Food.fromDoc).toList();
    });
  }

  Future<List<Food>> searchFoods(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final snap = await _db.collection('foods').limit(50).get();
    if (snap.docs.isEmpty) {
      return sampleFoods
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q))
          .map(
            (f) => Food(
              id: f.id,
              name: f.name,
              description: f.description,
              price: f.price,
              rating: f.rating,
              ratingCount: 50,
              image: f.image,
              category: f.category,
              deliveryTime: f.deliveryTime,
              available: true,
            ),
          )
          .toList();
    }
    return snap.docs
        .map(Food.fromDoc)
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q))
        .toList();
  }

  /// Admin-only: writes sample menu into Firestore in batches.
  Future<void> importSampleMenu() async {
    final batch = _db.batch();
    for (final c in sampleCategories) {
      batch.set(_db.collection('categories').doc(c.id), {
        'name': c.name,
        'icon': c.icon,
        'order': c.order,
      });
    }
    for (final f in sampleFoods) {
      batch.set(_db.collection('foods').doc(f.id), {
        'name': f.name,
        'description': f.description,
        'price': f.price,
        'rating': f.rating,
        'ratingCount': 50,
        'image': f.image,
        'category': f.category,
        'deliveryTime': f.deliveryTime,
        'available': true,
        'options': <String>[],
      });
    }
    await batch.commit();
  }
}
