import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../duty_slip/duty_slip_engine.dart';

/// On only for the admin Google account. Opens every chapter, lesson, and duty-slip level.
class DevUnlockNotifier extends Notifier<bool> {
  static const _key = 'admin_dev_unlock';

  @override
  bool build() {
    final admin = ref.watch(authProvider).isAdmin;
    if (!admin) {
      devLevelsOpen = false;
      return false;
    }
    unawaited(_restore());
    return devLevelsOpen;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(_key) ?? false;
    if (!ref.read(authProvider).isAdmin) return;
    devLevelsOpen = on;
    state = on;
  }

  Future<void> setOn(bool on) async {
    if (!ref.read(authProvider).isAdmin) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
    devLevelsOpen = on;
    state = on;
  }
}

final devUnlockProvider = NotifierProvider<DevUnlockNotifier, bool>(DevUnlockNotifier.new);
