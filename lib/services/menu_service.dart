import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_data.dart';
import '../models/category.dart';
import '../models/food.dart';
import '../utils/stream_cache.dart';

/// The menu changes rarely, so it is fetched once and held in memory.
///
/// Reads are the scarce resource on the free plan (50k/day), so:
/// * categories and the full available catalogue are read once per session,
///   not once per category switch;
/// * filtering and searching happen on the device, costing zero reads.
///
/// Firestore `snapshots()` streams are broadcast streams, so several widgets
/// can listen to the cached instance safely.
class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Last successful catalogue, used to answer searches and category
  /// switches without touching the network.
  List<Food> _cache = const [];

  Stream<List<Category>> watchCategories() =>
      StreamCache.of('menu:categories', () {
        return _db
            .collection('categories')
            .orderBy('order')
            .snapshots()
            .map((s) => s.docs.map(Category.fromDoc).toList());
      });

  /// The whole available menu, ordered by name. Category filtering is done
  /// by the caller, so switching tabs costs nothing.
  Stream<List<Food>> watchFoods() => StreamCache.of('menu:foods', () {
        return _db
            .collection('foods')
            .where('available', isEqualTo: true)
            .orderBy('name')
            .snapshots()
            .map((s) {
          final docs = s.docs;
          if (docs.isEmpty) return _sampleFoods();
          final list = docs.map(Food.fromDoc).toList();
          _cache = list;
          return list;
        });
      });

  /// Client-side search over the cached catalogue: no Firestore read.
  Future<List<Food>> searchFoods(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final source = _cache.isEmpty ? await watchFoods().first : _cache;
    return source
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q))
        .toList();
  }

  /// Shown only when the database has no menu yet, so a fresh install is not
  /// an empty screen. Never written to Firestore automatically.
  static List<Food> _sampleFoods() => sampleFoods
      .map((f) => Food(
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
          ))
      .toList();

  static List<Category> sampleCategoriesList() => sampleCategories
      .map((c) =>
          Category(id: c.id, name: c.name, icon: c.icon, order: c.order))
      .toList();

  /// Drops the cached catalogue so the next read hits Firestore. Called by
  /// the admin screens after writing the menu.
  static void invalidate() => StreamCache.invalidatePrefix('menu:');

  /// Admin-only: writes the sample menu into Firestore in batches.
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
    invalidate();
  }
}