import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/review.dart' show AppNotification;

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);
  }

  Stream<List<AppNotification>> watch(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs
          .map((d) =>
              AppNotification.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList());

  Future<void> showLocal(String title, String body) => _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_status',
            'Order status',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );

  Future<void> markRead(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .doc(id)
      .update({'read': true});
}
