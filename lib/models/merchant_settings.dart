import 'package:cloud_firestore/cloud_firestore.dart';

/// Merchant settings live in a single Firestore doc so the wallet number
/// can be changed without shipping a new build.
class MerchantSettings {
  final String name;
  final String gcashNumber;
  final String mayaNumber;
  final String address;

  const MerchantSettings({
    this.name = 'John Foods',
    this.gcashNumber = '',
    this.mayaNumber = '',
    this.address = '',
  });

  static const docId = 'main';

  factory MerchantSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return MerchantSettings(
      name: (m['name'] ?? 'John Foods') as String,
      gcashNumber: (m['gcashNumber'] ?? '') as String,
      mayaNumber: (m['mayaNumber'] ?? '') as String,
      address: (m['address'] ?? '') as String,
    );
  }

  /// Wallet to pay, empty when the merchant has not set one up.
  String walletFor(String method) {
    switch (method) {
      case 'GCash':
        return gcashNumber;
      case 'Maya':
        return mayaNumber;
      default:
        return '';
    }
  }

  bool isReady(String method) =>
      method == 'Cash on delivery' || walletFor(method).isNotEmpty;

  /// Admin writes the settings doc.
  Future<void> save({
    required String name,
    required String gcashNumber,
    required String mayaNumber,
    required String address,
  }) async {
    await FirebaseFirestore.instance
        .collection('merchantSettings')
        .doc(docId)
        .set({
          'name': name.trim(),
          'gcashNumber': gcashNumber.trim(),
          'mayaNumber': mayaNumber.trim(),
          'address': address.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}