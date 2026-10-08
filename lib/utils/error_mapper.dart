import 'package:firebase_auth/firebase_auth.dart';

/// Never show raw Firebase or exception text to users.
String friendlyError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'Email already in use. Try logging in.';
      case 'weak-password':
        return 'Use a stronger password (6+ characters).';
      case 'network-request-failed':
        return 'No connection. Check internet and retry.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please retry.';
    }
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'You do not have permission for that action.';
    }
    if (e.code == 'unavailable') {
      return 'Service offline. Showing saved data.';
    }
    return 'Something went wrong. Please retry.';
  }
  return 'Something went wrong. Please retry.';
}
