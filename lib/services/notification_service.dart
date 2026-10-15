import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/review.dart' show AppNotification;
import '../utils/stream_cache.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      // iOS shows the permission prompt on first use; without a handler
      // the tap does nothing.
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings =
        InitializationSettings(android: android, iOS: darwin);
    await _local.initialize(
      settings,
      // iOS needs an explicit handler for taps on the notification banner.
      onDidReceiveNotificationResponse: (r) {},
    );
    // Android 13+ needs this before notifications will show at all.
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  /// Cached per uid: building this inline in a StreamBuilder would
  /// otherwise resubscribe, and refetch, on every rebuild.
  Stream<List<AppNotification>> watch(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return StreamCache.of('notifs:$uid', () {
      return _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AppNotification.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>))
              .toList());
    });
  }

  /// Fires a local alert. Safe to call often; never throws to the caller.
  Future<void> showLocal(String title, String body) async {
    if (title.isEmpty && body.isEmpty) return;
    try {
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_status',
            'Order status',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.event,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Local notification failed: $e');
    }
  }

  Future<void> markRead(String uid, String id) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .doc(id)
      .update({'read': true});
}