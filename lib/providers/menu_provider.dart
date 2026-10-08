import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/food.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();
  List<Category> categories = [];
  List<Food> foods = [];
  bool loading = true;
  String? error;
  bool offline = false;
  String query = '';
  String selectedCategory = '';
  Timer? _debounce;

  MenuProvider() {
    _service.watchCategories().listen((c) {
      categories = c;
      notifyListeners();
    });
    _service.watchFoods().listen((f) {
      foods = f;
      loading = false;
      notifyListeners();
    }, onError: (_) {
      loading = false;
      offline = true;
      notifyListeners();
    });
  }

  void onSearch(String q) {
    query = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (q.trim().isEmpty) {
        _service.watchFoods(category: selectedCategory.isEmpty ? null : selectedCategory).first.then((f) {
          foods = f;
          notifyListeners();
        });
        return;
      }
      foods = await _service.searchFoods(q);
      notifyListeners();
    });
  }

  void selectCategory(String id) {
    selectedCategory = id;
    loading = true;
    notifyListeners();
    _service
        .watchFoods(category: id.isEmpty ? null : id)
        .first
        .then((f) {
      foods = f;
      loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
