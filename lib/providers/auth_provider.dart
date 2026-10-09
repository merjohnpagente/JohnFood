import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? _user;
  bool _loading = true;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get loggedIn => _user != null;
  String? get error => _error;

  AuthProvider() {
    _service.authState.listen(_onAuth);
  }

  Future<void> _onAuth(User? u) async {
    if (u == null) {
      _user = null;
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
      final doc = await ref.get();
      if (!doc.exists) {
        // Console-created user or failed write: create the profile lazily.
        final data = {
          'name': u.displayName ?? 'Customer',
          'email': u.email ?? '',
          'role': 'customer',
          'phone': '',
          'photoUrl': u.photoURL ?? '',
          'addresses': <String>[],
          'favorites': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        };
        try {
          await ref.set(data);
        } catch (_) {
          // Offline: keep going with in-memory profile, retry on refresh.
        }
        _user = AppUser(
          uid: u.uid,
          name: (data['name'] ?? 'Customer') as String,
          email: (data['email'] ?? '') as String,
          role: 'customer',
        );
      } else {
        _user = AppUser.fromDoc(doc);
      }
      _error = null;
    } catch (_) {
      // Offline at startup: don't trap the user on a spinner.
      _error = 'No connection. Check internet and retry.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final u = FirebaseAuth.instance.currentUser;
    await _onAuth(u);
  }

  Future<void> retry() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await refresh();
  }
}
