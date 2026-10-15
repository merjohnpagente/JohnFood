import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String orderId;
  final String userId;
  final String foodId;
  final double rating;
  final String comment;

  const Review({required this.id, required this.orderId, required this.userId, required this.foodId, required this.rating, required this.comment});

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Review(
      id: d.id,
      orderId: (m['orderId'] ?? '') as String,
      userId: (m['userId'] ?? '') as String,
      foodId: (m['foodId'] ?? '') as String,
      rating: ((m['rating'] ?? 0) as num).toDouble(),
      comment: (m['comment'] ?? '') as String,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String orderId;
  final bool read;

  const AppNotification({required this.id, required this.title, required this.body, required this.orderId, required this.read});

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppNotification(
      id: d.id,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      orderId: (m['orderId'] ?? '') as String,
      read: (m['read'] ?? false) as bool,
    );
  }
}
