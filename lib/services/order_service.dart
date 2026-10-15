import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/cart_item.dart';
import '../models/order.dart';
import 'promo_service.dart';

double calcSubtotal(List<CartItem> items) =>
    items.fold(0, (s, i) => s + i.lineTotal);

/// Free delivery threshold and base fee, kept in one place so the cart,
/// checkout and the rules stay in sync.
const double kFreeDeliveryThreshold = 500;
const double kBaseDeliveryFee = 49;

double calcDeliveryFee(double subtotal) =>
    subtotal >= kFreeDeliveryThreshold ? 0 : kBaseDeliveryFee;

double calcTotal(double subtotal, double fee, double discount) =>
    (subtotal + fee - discount).clamp(0, double.infinity).toDouble();

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Only methods the app can actually settle. Kept in sync with the
  /// validPaymentMethod helper in firestore.rules.
  static const allowedPayments = [
    'Cash on delivery',
    'GCash',
    'Maya',
  ];

  /// Forward-only transitions. Admin may still cancel from any active state.
  static const Map<String, List<String>> allowedTransitions = {
    'pending': ['assigned', 'preparing', 'cancelled'],
    'assigned': ['preparing', 'cancelled'],
    'preparing': ['on_the_way', 'cancelled'],
    'on_the_way': ['delivered', 'cancelled'],
    'delivered': [],
    'cancelled': [],
  };

  /// Loads one page of a user's orders. [after] is the last document seen,
  /// so the caller can walk backwards through history.
  Future<List<Order>> fetchUserOrders({
    required String uid,
    DocumentSnapshot<Map<String, dynamic>>? after,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    final s = await q.get();
    return s.docs.map(Order.fromDoc).toList();
  }

  Stream<List<Order>> watchUserOrders(String uid, {bool activeOnly = false}) {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30);
    return q.snapshots().map((s) {
      var list = s.docs.map(Order.fromDoc).toList();
      if (activeOnly) {
        list = list
            .where((o) =>
                o.status == 'pending' ||
                o.status == 'assigned' ||
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
      .map((d) => d.exists ? Order.fromDoc(d) : null);

  /// Places an order + notification entry atomically (no Cloud Functions).
  /// Idempotent via [clientRequestId]: retrying with the same id returns
  /// the original order instead of creating a duplicate.
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String address,
    required String phone,
    required String paymentMethod,
    required String notes,
    double discount = 0,
    String promoCode = '',
    double? customerLat,
    double? customerLng,
    String customerName = '',
    String paymentRef = '',
    String paymentProofUrl = '',
    required String clientRequestId,
  }) async {
    if (items.isEmpty) throw Exception('Cart is empty');
    if (items.length > 50) throw Exception('Too many items');
    final cleanAddress = address.trim();
    if (cleanAddress.length < 5) {
      throw Exception('Enter a complete delivery address');
    }
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (cleanPhone.length < 7 || cleanPhone.length > 15) {
      throw Exception('Enter a valid contact number');
    }
    if (!allowedPayments.contains(paymentMethod)) {
      throw Exception('Choose a valid payment method');
    }
    final cleanRef = paymentRef.trim();
    if (cleanRef.length > 50) throw Exception('Reference number too long');
    if (paymentMethod == 'GCash' && cleanRef.isEmpty) {
      throw Exception('Enter your GCash reference number');
    }
    if (paymentProofUrl.length > 1000) {
      throw Exception('Proof image too large');
    }
    if (clientRequestId.trim().isEmpty) {
      throw Exception('Missing request id. Please retry.');
    }
    // Idempotency: return existing order for this client request.
    final existing = await _db
        .collection('orders')
        .where('clientRequestId', isEqualTo: clientRequestId.trim())
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final subtotal = calcSubtotal(items);
    final fee = calcDeliveryFee(subtotal);
    final safeDiscount = discount.clamp(0, subtotal + fee).toDouble();
    final total = calcTotal(subtotal, fee, safeDiscount);
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
      'discount': safeDiscount,
      'promoCode': promoCode.trim().toUpperCase(),
      'total': total,
      'status': 'pending',
      'address': cleanAddress,
      'phone': cleanPhone,
      'customerName': customerName.trim(),
      'customerLat': customerLat,
      'customerLng': customerLng,
      'riderId': null,
      'riderLat': null,
      'riderLng': null,
      'paymentMethod': paymentMethod,
      'paymentRef': cleanRef,
      'paymentProofUrl': paymentProofUrl,
      'paymentVerified': false,
      'notes': notes.trim(),
      'clientRequestId': clientRequestId.trim(),
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
    // Count the promo use only for genuinely new orders. Idempotent
    // retries return above, so a double-tap can never double-count.
    final code = promoCode.trim().toUpperCase();
    if (code.isNotEmpty) {
      try {
        await PromoService().recordUse(code);
      } catch (_) {
        // Usage accounting must never fail the order itself.
      }
    }
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
    if (!allowedTransitions.keys.contains(status) &&
        !allowedTransitions.values.expand((e) => e).contains(status)) {
      throw Exception('Unknown status: $status');
    }
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

  /// Rider accepts an assigned order -> preparing.
  Future<void> acceptAssignment({
    required String orderId,
    required String customerId,
    required String riderId,
  }) =>
      changeStatus(
        orderId: orderId,
        userId: customerId,
        status: 'preparing',
        riderId: riderId,
      );

  /// Rider declines: release assignment back to pending so admin can reassign.
  /// Allowed by rules (rider may update own riderId/status fields).
  Future<void> declineAssignment({
    required String orderId,
    required String customerId,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('orders').doc(orderId), {
      'riderId': null,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.collection('users').doc(customerId).collection('notifications').doc(),
      {
        'title': 'Order pending',
        'body': 'Looking for another rider.',
        'orderId': orderId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  /// Customer attaches a GCash proof after the order exists (base64 fallback
  /// path). Allowed by rules only while the order is still pending.
  Future<void> updatePaymentProof({
    required String orderId,
    required String paymentProofUrl,
  }) async {
    if (paymentProofUrl.length > 1000) {
      throw Exception('Proof image too large');
    }
    await _db.collection('orders').doc(orderId).update({
      'paymentProofUrl': paymentProofUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin verifies (or rejects) a GCash/Maya payment.
  /// Rejecting cancels the order so the customer can reorder.
  Future<void> verifyPayment({
    required String orderId,
    required String customerId,
    required bool verified,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('orders').doc(orderId), {
      if (verified) 'paymentVerified': true,
      if (!verified) 'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.collection('users').doc(customerId).collection('notifications').doc(),
      {
        'title': verified ? 'Payment verified' : 'Payment rejected',
        'body': verified
            ? 'Your payment was verified. Preparing your food.'
            : 'Your payment proof was rejected. Please reorder with a valid receipt.',
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
