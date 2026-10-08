import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Zero-cost images: Cloudinary unsigned upload when configured,
/// otherwise base64 in foodImages/{id} (kept well under 1MiB) + cache.
class ImageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get canUploadCloudinary => AppConfig.cloudinaryConfigured;

  Future<String> uploadFoodImage(String foodId, List<int> jpegBytes, String filename) async {
    if (canUploadCloudinary) {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
      );
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', jpegBytes, filename: filename));
      final res = await req.send();
      final body = await res.stream.bytesToString();
      final url = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(body)?.group(1);
      if (url == null) throw Exception('Upload failed');
      await _db.collection('foods').doc(foodId).update({'image': url.replaceAll(r'\/', '/')});
      return url.replaceAll(r'\/', '/');
    }
    final b64 = base64Encode(jpegBytes);
    await _db.collection('foodImages').doc(foodId).set({
      'data': b64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return 'foodImages/$foodId';
  }

  Future<String?> cachedBase64(String foodId) async {
    final d = await _db.collection('foodImages').doc(foodId).get();
    return (d.data()?['data']) as String?;
  }
}
