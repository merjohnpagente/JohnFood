import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo.dart';

class PromoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<double> preview(String code, double subtotal) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return 0;
    if (c == 'JOHN10') return (subtotal * 0.10).clamp(0, subtotal).toDouble();
    if (c == 'FREEDEL') return 49.0.clamp(0, subtotal + 49).toDouble();
    try {
      final d = await _db.collection('promos').doc(c).get();
      if (!d.exists) return 0;
      return Promo.fromDoc(d).discountFor(subtotal);
    } catch (_) {
      return 0;
    }
  }
}
