import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
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
          o.status == 'assigned' ||
          o.status == 'preparing' ||
          o.status == 'on_the_way')
      .toList();

  List<Order> get history =>
      orders.where((o) => !active.contains(o)).toList();
}

class AdminProvider extends ChangeNotifier {
  bool loading = false;
  int todayOrders = 0;
  int activeOrders = 0;
  double todayRevenue = 0;
  double monthRevenue = 0;
  double yearRevenue = 0;
  double _overall = 0;
  Map<String, Map<String, dynamic>> topSales = {};

  double get overallRevenue => _overall;

  /// Safe share of the overall total (0 when there is nothing to divide by).
  double shareOf(double value) =>
      _overall <= 0 ? 0 : (value / _overall).clamp(0, 1).toDouble();

  Future<void> loadStats() async {
    loading = true;
    notifyListeners();
    try {
      // One fetch, all buckets computed locally. Cancelled orders earn
      // nothing and are excluded from every revenue figure.
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5000)
          .get();
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month);
      final yearStart = DateTime(now.year);
      int tOrders = 0;
      double tRev = 0, mRev = 0, yRev = 0, allRev = 0;
      int active = 0;
      final topSales = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        final m = d.data();
        final s = (m['status'] ?? '') as String;
        if (s == 'pending' ||
            s == 'assigned' ||
            s == 'preparing' ||
            s == 'on_the_way') {
          active++;
        }
        if (s == 'cancelled') continue;
        final total = ((m['total'] ?? 0) as num).toDouble();
        final created =
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        allRev += total;
        // Sales figures come from the items actually ordered.
        final items = ((m['items'] ?? []) as List);
        for (final raw in items) {
          final it = Map<String, dynamic>.from(raw as Map);
          final fid = (it['foodId'] ?? '') as String;
          if (fid.isEmpty) continue;
          final qty = ((it['qty'] ?? 1) as num).toInt();
          final line =
              ((it['price'] ?? 0) as num).toDouble() * qty;
          final entry = topSales.putIfAbsent(fid, () {
            final name = (it['name'] ?? fid) as String;
            return <String, dynamic>{'name': name, 'qty': 0, 'revenue': 0.0};
          });
          entry['qty'] = ((entry['qty'] ?? 0) as int) + qty;
          entry['revenue'] =
              ((entry['revenue'] ?? 0.0) as double) + line;
        }
        if (!created.isBefore(yearStart)) yRev += total;
        if (!created.isBefore(monthStart)) mRev += total;
        if (!created.isBefore(dayStart)) {
          tRev += total;
          tOrders++;
        }
      }
      todayOrders = tOrders;
      todayRevenue = tRev;
      monthRevenue = mRev;
      yearRevenue = yRev;
      _overall = allRev;
      activeOrders = active;
      this.topSales = topSales;
    } catch (_) {
      // Keep last values on offline; dashboard shows cached numbers.
    }
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
