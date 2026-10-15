import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Dashboard figures use Firestore aggregation queries, which cost one read
/// no matter how many orders they scan. Reading the orders to sum them in
/// Dart would cost one read per order, which is the single biggest quota
/// drain in the app.
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

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> loadStats() async {
    loading = true;
    notifyListeners();
    final db = _db;
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month);
      final yearStart = DateTime(now.year);

      // Aggregations: 1 read each.
      final todayCount = await _countFrom(dayStart);
      final monthRev = await _sumFrom(monthStart);
      final yearRev = await _sumFrom(yearStart);
      final overallRev = await _sumFrom(null);

      // Exclude cancelled revenue. Aggregation cannot filter on two fields,
      // so the cancelled correction is applied with one bounded read.
      final cancelled = await _cancelledSum();

      todayOrders = todayCount;
      monthRevenue = monthRev - cancelled.month;
      yearRevenue = yearRev - cancelled.total;
      _overall = overallRev - cancelled.total;
      activeOrders = await _activeCount();

      // Top sellers needs the item arrays, which aggregation cannot reach.
      // Bounded and infrequent: only the most recent non-cancelled orders.
      topSales = await _topSellers();
    } catch (_) {
      // Offline: keep the last values rather than blanking the dashboard.
    }
    loading = false;
    notifyListeners();
  }

  Future<int> _countFrom(DateTime from) async {
    final snap = await _db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<double> _sumFrom(DateTime? from) async {
    Query<Map<String, dynamic>> q = _db.collection('orders');
    if (from != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    final snap = await q.select(total).sum('total').get();
    return (snap.data ?? 0).toDouble();
  }

  /// Cancelled orders, newest first, capped so the read stays bounded.
  Future<({double total, double month})> _cancelledSum() async {
    final snap = await _db
        .collection('orders')
        .where('status', isEqualTo: 'cancelled')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    var total = 0.0;
    var month = 0.0;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    for (final d in snap.docs) {
      final m = d.data();
      final v = ((m['total'] ?? 0) as num).toDouble();
      total += v;
      final created = (m['createdAt'] as Timestamp?)?.toDate();
      if (created != null && !created.isBefore(monthStart)) month += v;
    }
    return (total: total, month: month);
  }

  Future<int> _activeCount() async {
    var total = 0;
    for (final status in ['pending', 'assigned', 'preparing', 'on_the_way']) {
      final snap = await _db
          .collection('orders')
          .where('status', isEqualTo: status)
          .count()
          .get();
      total += snap.count ?? 0;
    }
    return total;
  }

  /// Reads only the recent orders, since aggregation cannot reach the
  /// nested items array that sales are computed from.
  Future<Map<String, Map<String, dynamic>>> _topSellers({int cap = 300}) async {
    final snap = await _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(cap)
        .get();
    final out = <String, Map<String, dynamic>>{};
    for (final d in snap.docs) {
      final m = d.data();
      if ((m['status'] ?? '') == 'cancelled') continue;
      for (final raw in ((m['items'] ?? []) as List)) {
        final it = Map<String, dynamic>.from(raw as Map);
        final fid = (it['foodId'] ?? '') as String;
        if (fid.isEmpty) continue;
        final qty = ((it['qty'] ?? 1) as num).toInt();
        final line = ((it['price'] ?? 0) as num).toDouble() * qty;
        final e = out.putIfAbsent(fid, () {
          final name = (it['name'] ?? fid) as String;
          return <String, dynamic>{'name': name, 'qty': 0, 'revenue': 0.0};
        });
        e['qty'] = ((e['qty'] ?? 0) as int) + qty;
        e['revenue'] = ((e['revenue'] ?? 0.0) as double) + line;
      }
    }
    return out;
  }
}

class ThemeProvider extends ChangeNotifier {
  bool dark = false;
  void toggle() {
    dark = !dark;
    notifyListeners();
  }
}