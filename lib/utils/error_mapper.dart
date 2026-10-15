import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

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
      case 'operation-not-allowed':
        return 'This sign-in method is disabled. Contact support.';
      case 'account-exists-with-different-credential':
        return 'This email uses another sign-in method. Try email login instead.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'cancelled':
        return 'Sign in cancelled.';
      case 'popup-blocked':
        return 'Popup blocked. Allow popups for this site and retry.';
      case 'unauthorized-domain':
        return 'This site is not authorized for sign-in. Contact support.';
      case 'missing-id-token':
        return 'Google sign-in is misconfigured on this build. Try email login or contact support.';
      default:
        return 'Something went wrong. Please retry.';
    }
  }
  if (e is PlatformException) {
    final msg = '${e.code} ${e.message ?? ''}';
    // Google Sign-In ApiException 10 = SHA-1 / google-services.json missing.
    if (msg.contains('10') || msg.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in is not set up for this app build. Try email login or contact support.';
    }
    if (e.code == 'sign_in_canceled') return 'Sign in cancelled.';
    if (e.code == 'network_error') {
      return 'No connection. Check internet and retry.';
    }
    return 'Something went wrong. Please retry.';
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
  final text = e.toString();
  if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
    return 'Google sign-in is not set up for this app build. Try email login or contact support.';
  }
  return 'Something went wrong. Please retry.';
}
