import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo.dart';

/// Promo codes live in Firestore so admins can create and expire them
/// without shipping a new build. No hardcoded codes.
class PromoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Codes a customer can currently see (active, not expired, not used up).
  Stream<List<Promo>> watchActive() => _db
      .collection('promos')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map(Promo.fromDoc)
          .where((p) => p.isValid)
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code)));

  /// Everything, for the admin promo screen.
  Stream<List<Promo>> watchAll() => _db
      .collection('promos')
      .snapshots()
      .map((s) => s.docs.map(Promo.fromDoc).toList()
        ..sort((a, b) => a.code.compareTo(b.code)));

  /// Validates [code] against [subtotal] and returns the discount.
  /// Returns 0 for unknown, expired, inactive or not-enough-spend codes.
  Future<double> preview(
    String code,
    double subtotal, {
    double deliveryFee = 49,
  }) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return 0;
    try {
      final d = await _db.collection('promos').doc(c).get();
      if (!d.exists) return 0;
      return Promo.fromDoc(d)
          .discountFor(subtotal, deliveryFee: deliveryFee);
    } catch (_) {
      return 0;
    }
  }

  /// Explains why a code did not apply, so the cart can tell the customer
  /// instead of just saying "invalid".
  Future<String?> previewMessage(
    String code,
    double subtotal, {
    double deliveryFee = 49,
  }) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    try {
      final d = await _db.collection('promos').doc(c).get();
      if (!d.exists) return 'That code does not exist.';
      final p = Promo.fromDoc(d);
      if (!p.active) return 'That code is no longer active.';
      if (p.isExpired) return 'That code has expired.';
      if (p.isUsedUp) return 'That code has been fully used.';
      if (subtotal < p.minSubtotal) {
        return 'Minimum spend is ${p.minSubtotal.toStringAsFixed(0)}.';
      }
      final amount = p.discountFor(subtotal, deliveryFee: deliveryFee);
      return amount <= 0 ? 'That code does not apply to this order.' : null;
    } catch (_) {
      return 'Could not check that code. Try again.';
    }
  }

  // ---- admin writes ----

  Future<void> save({
    required String code,
    required String type,
    required double value,
    required bool active,
    double minSubtotal = 0,
    DateTime? expiresAt,
    int maxUses = 0,
  }) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty || c.contains(' ')) {
      throw Exception('Code must be letters and numbers only');
    }
    if (type == 'percent' && (value <= 0 || value > 100)) {
      throw Exception('Percentage must be between 1 and 100');
    }
    if (type == 'fixed' && value <= 0) {
      throw Exception('Amount must be more than 0');
    }
    await _db.collection('promos').doc(c).set({
      'type': type,
      'value': value,
      'active': active,
      'minSubtotal': minSubtotal,
      'maxUses': maxUses,
      'expiresAt': expiresAt == null
          ? null
          : Timestamp.fromDate(DateTime(
              expiresAt.year, expiresAt.month, expiresAt.day, 23, 59, 59)),
    });
  }

  Future<void> setActive(String code, bool active) => _db
      .collection('promos')
      .doc(code.trim().toUpperCase())
      .update({'active': active});

  Future<void> delete(String code) => _db
      .collection('promos')
      .doc(code.trim().toUpperCase())
      .delete();

  /// Counts one use. Called after an order is placed with this code.
  Future<void> recordUse(String code) async {
    final ref = _db.collection('promos').doc(code.trim().toUpperCase());
    await _db.runTransaction((tx) async {
      final s = await tx.get(ref);
      if (!s.exists) return;
      final used = (((s.data()?['used'] ?? 0) as num).toInt()) + 1;
      tx.update(ref, {'used': used});
    });
  }
}