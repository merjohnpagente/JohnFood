import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String photoUrl;
  final List<String> addresses;
  final List<String> favorites;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.photoUrl = '',
    this.addresses = const [],
    this.favorites = const [],
  });

  bool get isAdmin => role == 'admin';
  bool get isRider => role == 'rider';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: d.id,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      role: (m['role'] ?? 'customer') as String,
      phone: (m['phone'] ?? '') as String,
      photoUrl: (m['photoUrl'] ?? '') as String,
      addresses: ((m['addresses'] ?? []) as List).map((e) => '$e').toList(),
      favorites: ((m['favorites'] ?? []) as List).map((e) => '$e').toList(),
    );
  }
}
