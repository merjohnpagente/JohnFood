import 'dart:async';

import 'package:flutter/foundation.dart';

/// Keeps one Stream instance per key so widgets can build them inline.
///
/// Why this exists: `StreamBuilder` resubscribes whenever `widget.stream`
/// is not identical to the previous one, and Dart streams do not override
/// `==`. Building `FirebaseFirestore...snapshots()` directly inside a
/// builder therefore creates a brand new subscription, and a brand new
/// Firestore query, on every single rebuild. On a screen that rebuilds when
/// a cart badge or a menu item changes, that burns through the daily read
/// quota in minutes.
///
/// Firestore `snapshots()` streams are broadcast streams, so handing the
/// same instance to several listeners is safe: every listener still gets
/// every event.
class StreamCache {
  StreamCache._();

  static final Map<String, Stream<dynamic>> _cache = {};
  static final Map<String, DateTime> _createdAt = {};

  /// Entries are kept for a short while so navigating back to a screen does
  /// not refetch, but a long session does not pin queries forever.
  static const Duration ttl = Duration(miniseconds: 30);

  /// Returns the cached stream for [key], creating it with [factory] on a
  /// miss or once the previous entry went stale.
  static Stream<T> of<T>(String key, Stream<T> Function() factory) {
    final now = DateTime.now();
    final existing = _cache[key];
    if (existing != null) {
      final age = now.difference(_createdAt[key] ?? now);
      if (age < ttl && existing is Stream<T>) {
        return existing as Stream<T>;
      }
    }
    final created = factory();
    _cache[key] = created;
    _createdAt[key] = now;
    return created;
  }

  /// Drops one entry, for example after signing out.
  static void invalidate(String key) {
    _cache.remove(key);
    _createdAt.remove(key);
  }

  /// Drops every entry that starts with [prefix].
  static void invalidatePrefix(String prefix) {
    final keys = _cache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      invalidate(k);
    }
  }

  static void clear() {
    _cache.clear();
    _createdAt.clear();
  }

  @visibleForTesting
  static int get length => _cache.length;
}