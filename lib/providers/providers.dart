import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrdersProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<Order> orders = [];
  bool loading = true;

  void watch(String uid) {
    _service.watchUserOrders(uid).listen((o) {
      orders = o;
      loading = false;
      notifyListeners();
    });
  }

  List<Order> get active => orders
      .where((o) =>
          o.status == 'pending' ||
          o.status == 'preparing' ||
          o.status == 'on_the_way')
      .toList();

  List<Order> get history =>
      orders.where((o) => !active.contains(o)).toList();
}

class AdminProvider extends ChangeNotifier {
  bool loading = false;
  int todayOrders = 0;
  double todayRevenue = 0;
  int activeOrders = 0;

  Future<void> loadStats() async {
    loading = true;
    notifyListeners();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    todayOrders = snap.docs.length;
    double rev = 0;
    int active = 0;
    for (final d in snap.docs) {
      final m = d.data();
      rev += ((m['total'] ?? 0) as num).toDouble();
      final s = (m['status'] ?? '') as String;
      if (s == 'pending' || s == 'preparing' || s == 'on_the_way') active++;
    }
    todayRevenue = rev;
    activeOrders = active;
    loading = false;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool dark = false;
  void toggle() {
    dark = !dark;
    notifyListeners();
  }
}
