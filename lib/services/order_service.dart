import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/cart_item.dart';
import '../models/order.dart';

double calcSubtotal(List<CartItem> items) =>
    items.fold(0, (s, i) => s + i.lineTotal);

double calcDeliveryFee(double subtotal) => subtotal >= 500 ? 0 : 49;

double calcTotal(double subtotal, double fee, double discount) =>
    (subtotal + fee - discount).clamp(0, double.infinity).toDouble();

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Order>> watchUserOrders(String uid, {bool activeOnly = false}) {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20);
    return q.snapshots().map((s) {
      var list = s.docs.map(Order.fromDoc).toList();
      if (activeOnly) {
        list = list
            .where((o) =>
                o.status == 'pending' ||
                o.status == 'preparing' ||
                o.status == 'on_the_way')
            .toList();
      }
      return list;
    });
  }

  Stream<Order?> watchOrder(String orderId) => _db
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((d) => d.exists ? Order.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>) : null);

  /// Places an order + notification entry atomically (no Cloud Functions).
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String address,
    required String paymentMethod,
    required String notes,
    double discount = 0,
    double? customerLat,
    double? customerLng,
    required String clientRequestId,
  }) async {
    final subtotal = calcSubtotal(items);
    final fee = calcDeliveryFee(subtotal);
    final total = calcTotal(subtotal, fee, discount);
    final ref = _db.collection('orders').doc();
    final notifRef =
        _db.collection('users').doc(userId).collection('notifications').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'userId': userId,
      'items': items
          .map((i) => {
                'foodId': i.food.id,
                'name': i.food.name,
                'price': i.food.price,
                'qty': i.qty,
                'option': i.selectedOption,
              })
          .toList(),
      'subtotal': subtotal,
      'deliveryFee': fee,
      'discount': discount,
      'total': total,
      'status': 'pending',
      'address': address,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'riderId': null,
      'riderLat': null,
      'riderLng': null,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'clientRequestId': clientRequestId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(notifRef, {
      'title': 'Order placed',
      'body': 'Your order is pending confirmation.',
      'orderId': ref.id,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  Future<void> cancelOrder(String orderId) =>
      _db.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> changeStatus({
    required String orderId,
    required String userId,
    required String status,
    String? riderId,
    double? riderLat,
    double? riderLng,
  }) async {
    final batch = _db.batch();
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (riderId != null) data['riderId'] = riderId;
    if (riderLat != null) data['riderLat'] = riderLat;
    if (riderLng != null) data['riderLng'] = riderLng;
    batch.update(_db.collection('orders').doc(orderId), data);
    batch.set(
      _db.collection('users').doc(userId).collection('notifications').doc(),
      {
        'title': 'Order $status',
        'body': 'Your order is now $status.',
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> updateRiderPosition(String orderId, double lat, double lng) =>
      _db.collection('orders').doc(orderId).update({
        'riderLat': lat,
        'riderLng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
