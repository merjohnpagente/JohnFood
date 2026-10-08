import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// One review per order item; updates food rating average in a transaction.
  Future<void> submitReview({
    required String orderId,
    required String userId,
    required String foodId,
    required double rating,
    required String comment,
  }) async {
    final foodRef = _db.collection('foods').doc(foodId);
    final reviewRef = _db.collection('reviews').doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(foodRef);
      final data = snap.data() ?? {};
      final oldAvg = ((data['rating'] ?? 0) as num).toDouble();
      final count = ((data['ratingCount'] ?? 0) as num).toInt();
      final next = ((oldAvg * count) + rating) / (count + 1);
      tx.set(reviewRef, {
        'orderId': orderId,
        'userId': userId,
        'foodId': foodId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (snap.exists) {
        tx.update(foodRef, {'rating': next, 'ratingCount': count + 1});
      }
    });
  }
}
