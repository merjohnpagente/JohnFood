import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/food.dart';
import '../services/menu_service.dart';

/// Holds the menu in memory and filters on the device. Switching category or
/// typing a search no longer issues a Firestore query, which is what keeps
/// the app inside the free plan's daily read quota.
class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();

  /// Everything the server offered, unfiltered.
  List<Food> _all = const [];
  List<Category> categories = const [];
  List<Food> foods = const [];

  bool loading = true;
  bool offline = false;
  String query = '';
  String selectedCategory = '';

  StreamSubscription<List<Category>>? _catSub;
  StreamSubscription<List<Food>>? _foodSub;

  MenuProvider() {
    _catSub = _service.watchCategories().listen((c) {
      categories = c.isEmpty ? MenuService.sampleCategoriesList() : c;
      _apply();
    }, onError: (_) {
      categories = MenuService.sampleCategoriesList();
      offline = true;
      _apply();
    });

    _foodSub = _service.watchFoods().listen((f) {
      _all = f;
      loading = false;
      _apply();
    }, onError: (_) {
      loading = false;
      offline = true;
      _apply();
    });
  }

  /// Recomputes the visible list. Purely local, so it is safe to call on
  /// every keystroke.
  void _apply() {
    var list = _all;
    if (selectedCategory.isNotEmpty) {
      list = list.where((f) => f.category == selectedCategory).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q))
          .toList();
    }
    foods = list;
    notifyListeners();
  }

  void onSearch(String q) {
    query = q;
    _apply();
  }

  void selectCategory(String id) {
    selectedCategory = id;
    _apply();
  }

  /// Looks a food up in the full catalogue, not the filtered view, so a
  /// detail page still resolves when the food is outside the active filter.
  Food? foodById(String id) {
    for (final f in _all) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Popular picks sorted by rating, used by the home banners.
  List<Food> popular(int count) {
    final sorted = [..._all]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(count).toList();
  }

  @override
  void dispose() {
    _catSub?.cancel();
    _foodSub?.cancel();
    super.dispose();
  }
}