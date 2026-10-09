import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': 'customer',
      'phone': '',
      'photoUrl': '',
      'addresses': <String>[],
      'favorites': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    final g = await GoogleSignIn().signIn();
    if (g == null) throw FirebaseAuthException(code: 'cancelled', message: 'Sign in cancelled');
    final auth = await g.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final userCred = await _auth.signInWithCredential(cred);
    final doc = await _db.collection('users').doc(userCred.user!.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(userCred.user!.uid).set({
        'name': userCred.user!.displayName ?? 'Customer',
        'email': userCred.user!.email ?? '',
        'role': 'customer',
        'phone': '',
        'photoUrl': userCred.user!.photoURL ?? '',
        'addresses': <String>[],
        'favorites': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return userCred;
  }

  Future<void> sendReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Admin creates a rider login without signing out the admin.
  /// Uses a secondary app instance, then writes the profile (role rider)
  /// from the still-signed-in admin session.
  Future<void> createRiderAccount({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    FirebaseApp secondary;
    try {
      secondary = Firebase.app('userCreator');
    } catch (_) {
      secondary = await Firebase.initializeApp(
        name: 'userCreator',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    try {
      final cred = await FirebaseAuth.instanceFor(app: secondary)
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await FirebaseAuth.instanceFor(app: secondary).signOut();
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'rider',
        'phone': phone.trim(),
        'photoUrl': '',
        'addresses': <String>[],
        'favorites': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      await secondary.delete();
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
