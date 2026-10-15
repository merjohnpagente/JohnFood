import 'package:cloud_firestore/cloud_firestore.dart';

/// A promo code owned by the admin. Expiry and minimum spend are enforced
/// server side in the rules and again here when previewing.
class Promo {
  final String code;
  final String type; // 'percent' | 'fixed' | 'freeship'
  final double value;
  final bool active;
  final double minSubtotal;
  final DateTime? expiresAt;
  final int maxUses;
  final int used;

  const Promo({
    required this.code,
    this.type = 'percent',
    this.value = 0,
    this.active = true,
    this.minSubtotal = 0,
    this.expiresAt,
    this.maxUses = 0,
    this.used = 0,
  });

  factory Promo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Promo(
      code: d.id,
      type: (m['type'] ?? 'percent') as String,
      value: ((m['value'] ?? 0) as num).toDouble(),
      active: (m['active'] ?? true) as bool,
      minSubtotal: ((m['minSubtotal'] ?? 0) as num).toDouble(),
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      maxUses: ((m['maxUses'] ?? 0) as num).toInt(),
      used: ((m['used'] ?? 0) as num).toInt(),
    );
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isUsedUp => maxUses > 0 && used >= maxUses;

  bool get isValid => active && !isExpired && !isUsedUp;

  /// True when this code can be applied to a [subtotal] order.
  bool appliesTo(double subtotal) =>
      isValid && subtotal >= minSubtotal;

  /// Discount amount for [subtotal]. Free shipping returns the delivery fee
  /// the caller passes in.
  double discountFor(double subtotal, {double deliveryFee = 49}) {
    if (!appliesTo(subtotal)) return 0;
    switch (type) {
      case 'fixed':
        return value.clamp(0, subtotal).toDouble();
      case 'freeship':
        return deliveryFee.clamp(0, deliveryFee).toDouble();
      default:
        return (subtotal * value / 100).clamp(0, subtotal).toDouble();
    }
  }

  String describe() {
    if (!active) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isUsedUp) return 'Fully used';
    if (minSubtotal > 0) {
      return 'Min spend ${minSubtotal.toStringAsFixed(0)}';
    }
    return 'Active';
  }
}