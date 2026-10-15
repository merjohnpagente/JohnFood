import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String foodId;
  final String name;
  final double price;
  final int qty;
  final String option;

  const OrderItem({required this.foodId, required this.name, required this.price, required this.qty, this.option = ''});

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        foodId: (m['foodId'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        price: ((m['price'] ?? 0) as num).toDouble(),
        qty: ((m['qty'] ?? 1) as num).toInt(),
        option: (m['option'] ?? '') as String,
      );

  Map<String, dynamic> toMap() =>
      {'foodId': foodId, 'name': name, 'price': price, 'qty': qty, 'option': option};
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String promoCode;
  final double total;
  final String status;
  final String address;
  final String phone;
  final String customerName;
  final double? customerLat;
  final double? customerLng;
  final String? riderId;
  final double? riderLat;
  final double? riderLng;
  final String paymentMethod;
  final String paymentRef;
  final String paymentProofUrl;
  final bool paymentVerified;
  final String notes;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    this.promoCode = '',
    required this.total,
    required this.status,
    required this.address,
    required this.phone,
    this.customerName = '',
    this.customerLat,
    this.customerLng,
    this.riderId,
    this.riderLat,
    this.riderLng,
    required this.paymentMethod,
    this.paymentRef = '',
    this.paymentProofUrl = '',
    this.paymentVerified = false,
    required this.notes,
    this.createdAt,
  });

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Order(
      id: d.id,
      userId: (m['userId'] ?? '') as String,
      items: ((m['items'] ?? []) as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: ((m['subtotal'] ?? 0) as num).toDouble(),
      deliveryFee: ((m['deliveryFee'] ?? 0) as num).toDouble(),
      discount: ((m['discount'] ?? 0) as num).toDouble(),
      promoCode: (m['promoCode'] ?? '') as String,
      total: ((m['total'] ?? 0) as num).toDouble(),
      status: (m['status'] ?? 'pending') as String,
      address: (m['address'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      customerName: (m['customerName'] ?? '') as String,
      customerLat: (m['customerLat'] as num?)?.toDouble(),
      customerLng: (m['customerLng'] as num?)?.toDouble(),
      riderId: m['riderId'] as String?,
      riderLat: (m['riderLat'] as num?)?.toDouble(),
      riderLng: (m['riderLng'] as num?)?.toDouble(),
      paymentMethod: (m['paymentMethod'] ?? 'Cash on delivery') as String,
      paymentRef: (m['paymentRef'] ?? '') as String,
      paymentProofUrl: (m['paymentProofUrl'] ?? '') as String,
      paymentVerified: (m['paymentVerified'] ?? false) as bool,
      notes: (m['notes'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
