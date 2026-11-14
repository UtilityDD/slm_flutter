import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User ids the phone still treats as unverified when the server column is missing.
class VerifyHoldNotifier extends Notifier<Set<String>> {
  static const _key = 'slm_verify_hold';

  @override
  Set<String> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    state = raw.toSet();
  }

  Future<void> hold(String id) async {
    if (id.isEmpty || state.contains(id)) return;
    final next = {...state, id};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  static const _markedKey = 'slm_verify_marked';

  /// True once this phone has flipped [id]'s fresh signup to unverified, so a
  /// later admin verify (even inside the first minutes) is never undone.
  Future<bool> wasMarked(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_markedKey) ?? const <String>[]).contains(id);
  }

  Future<void> markOnce(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_markedKey) ?? const <String>[];
    if (list.contains(id)) return;
    await prefs.setStringList(_markedKey, [...list, id]);
  }

  Future<void> release(String id) async {
    if (!state.contains(id)) return;
    final next = {...state}..remove(id);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final verifyHoldProvider = NotifierProvider<VerifyHoldNotifier, Set<String>>(
  VerifyHoldNotifier.new,
);
