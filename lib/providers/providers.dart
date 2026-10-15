import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

/// The customer's own orders, split into what is still in progress and what
/// is history. Backed by the cached stream in [OrderService] so the orders
/// tab does not refetch on every rebuild.
class OrdersProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<Order> orders = const [];
  bool loading = true;
  String _watching = '';

  void watch(String uid) {
    if (uid.isEmpty || uid == _watching) return;
    _watching = uid;
    _service.watchUserOrders(uid).listen((o) {
      orders = o;
      loading = false;
      notifyListeners();
    }, onError: (_) {
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

/// Dashboard figures use Firestore aggregation queries, which cost one read
/// no matter how many orders they scan. Reading the orders to sum them in
/// Dashboard figures.
///
/// The installed cloud_firestore has no aggregation queries (no `sum`, no
/// `count` on a Query), so the numbers are computed from one bounded read of
/// the most recent orders and cached for a short while. That keeps a
/// dashboard open from spending a read per pull-to-refresh, at the cost of
/// ignoring orders older than the cap. If the project ever moves to a plan
/// with aggregation queries or Cloud Functions, replace this with a
/// server-side rollup.
class AdminProvider extends ChangeNotifier {
  bool loading = false;
  int todayOrders = 0;
  int activeOrders = 0;
  double todayRevenue = 0;
  double monthRevenue = 0;
  double yearRevenue = 0;
  double _overall = 0;
  Map<String, Map<String, dynamic>> topSales = {};

  /// Newest orders considered. Raising it improves accuracy and costs reads.
  static const int _cap = 400;

  /// Do not refetch within this window.
  static const Duration _cacheTtl = Duration(minutes: 2);

  DateTime? _fetchedAt;

  double get overallRevenue => _overall;

  /// Safe share of the overall total (0 when there is nothing to divide by).
  double shareOf(double value) =>
      _overall <= 0 ? 0 : (value / _overall).clamp(0, 1).toDouble();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> loadStats({bool force = false}) async {
    final fresh = _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < _cacheTtl;
    if (fresh && !force) return;

    loading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month);
      final yearStart = DateTime(now.year);

      final snap = await _db
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(_cap)
          .get();

      var tOrders = 0;
      var tRev = 0.0, mRev = 0.0, yRev = 0.0, allRev = 0.0;
      var active = 0;
      final sales = <String, Map<String, dynamic>>{};

      for (final d in snap.docs) {
        final m = d.data();
        final status = (m['status'] ?? '') as String;
        if (status == 'pending' ||
            status == 'assigned' ||
            status == 'preparing' ||
            status == 'on_the_way') {
          active++;
        }
        if (status == 'cancelled') continue;

        final total = ((m['total'] ?? 0) as num).toDouble();
        final created =
            (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        allRev += total;
        if (!created.isBefore(yearStart)) yRev += total;
        if (!created.isBefore(monthStart)) mRev += total;
        if (!created.isBefore(dayStart)) {
          tRev += total;
          tOrders++;
        }

        for (final raw in ((m['items'] ?? []) as List)) {
          final it = Map<String, dynamic>.from(raw as Map);
          final fid = (it['foodId'] ?? '') as String;
          if (fid.isEmpty) continue;
          final qty = ((it['qty'] ?? 1) as num).toInt();
          final line = ((it['price'] ?? 0) as num).toDouble() * qty;
          final e = sales.putIfAbsent(fid, () {
            final name = (it['name'] ?? fid) as String;
            return <String, dynamic>{'name': name, 'qty': 0, 'revenue': 0.0};
          });
          e['qty'] = ((e['qty'] ?? 0) as int) + qty;
          e['revenue'] = ((e['revenue'] ?? 0.0) as double) + line;
        }
      }

      todayOrders = tOrders;
      todayRevenue = tRev;
      monthRevenue = mRev;
      yearRevenue = yRev;
      _overall = allRev;
      activeOrders = active;
      topSales = sales;
      _fetchedAt = DateTime.now();
    } catch (_) {
      // Offline: keep the last values rather than blanking the dashboard.
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