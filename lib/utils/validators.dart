String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter your email';
  final t = v.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? v, {bool allowShort = false}) {
  if (v == null || v.isEmpty) return 'Enter your password';
  if (!allowShort && v.length < 6) return 'Password must be 6+ characters';
  return null;
}

String? validateRequired(String? v, String label) {
  if (v == null || v.trim().isEmpty) return 'Enter $label';
  return null;
}

String? validatePhone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter contact number';
  final t = v.trim().replaceAll(RegExp(r'[\s-]'), '');
  if (t.length < 7 || t.length > 15) return 'Enter a valid number';
  return null;
}
