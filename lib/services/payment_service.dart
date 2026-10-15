import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/merchant_settings.dart';

/// Payment methods the app can actually settle. Card and e-wallet are
/// deliberately excluded: there is no gateway, so accepting them would let a
/// customer place an order with no way to pay.
class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> methods = [
    'Cash on delivery',
    'GCash',
    'Maya',
  ];

  /// Methods that need a reference number and a screenshot before the
  /// kitchen can start.
  static bool needsProof(String method) =>
      method == 'GCash' || method == 'Maya';

  static String label(String method) {
    switch (method) {
      case 'GCash':
        return 'GCash transfer';
      case 'Maya':
        return 'Maya transfer';
      default:
        return 'Cash on delivery';
    }
  }

  Stream<MerchantSettings> watchSettings() => _db
      .collection('merchantSettings')
      .doc(MerchantSettings.docId)
      .snapshots()
      .map((d) => d.exists ? MerchantSettings.fromDoc(d) : const MerchantSettings());

  Future<MerchantSettings> load() async {
    final d = await _db
        .collection('merchantSettings')
        .doc(MerchantSettings.docId)
        .get();
    return d.exists ? MerchantSettings.fromDoc(d) : const MerchantSettings();
  }

  /// Admin-only write.
  Future<void> save(MerchantSettings s) => s.save(
        name: s.name,
        gcashNumber: s.gcashNumber,
        mayaNumber: s.mayaNumber,
        address: s.address,
      );
}