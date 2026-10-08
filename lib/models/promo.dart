import 'package:cloud_firestore/cloud_firestore.dart';

class Promo {
  final String code;
  final String type;
  final double value;
  final bool active;

  const Promo({required this.code, required this.type, required this.value, required this.active});

  factory Promo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Promo(
      code: d.id,
      type: (m['type'] ?? 'percent') as String,
      value: ((m['value'] ?? 0) as num).toDouble(),
      active: (m['active'] ?? false) as bool,
    );
  }

  double discountFor(double subtotal) {
    if (!active) return 0;
    if (type == 'fixed') return value.clamp(0, subtotal).toDouble();
    return (subtotal * value / 100).clamp(0, subtotal).toDouble();
  }
}
