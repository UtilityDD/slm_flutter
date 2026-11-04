import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService {
  /// Throws (LateInitializationError) until [initialize] has run, or if it
  /// failed. Callers guard it with try/catch and fall back to guest / cache.
  static SupabaseClient get client => Supabase.instance.client;

  static Future<bool>? _ready;

  /// [initialize] was called (it may still be waiting or running).
  static bool get isStarted => _ready != null;

  static bool _hasClient = false;

  /// [client] exists (Supabase sets it synchronously when init starts).
  static bool get hasClient => _hasClient;

  /// Completes with `true` once the saved session has been restored from the
  /// phone, `false` if initialisation failed. Does not start it: if
  /// [initialize] was never called (tests), this reports whether a client exists.
  static Future<bool> get ready => _ready ?? Future.value(hasClient);

  /// Starts Supabase once (after [after] completes, if given); later calls
  /// return the same future.
  ///
  /// Needs no network: it reads the saved session from SharedPreferences and
  /// emits `initialSession`; the token refresh runs later in the background.
  /// So `main.dart` starts it after the first frame instead of awaiting it.
  /// `onAuthStateChange` replays the restored session to late listeners.
  /// Only a plugin or configuration error can make it fail; that is logged
  /// and the app runs as guest.
  static Future<bool> initialize({Future<void>? after}) =>
      _ready ??= after == null ? _initialize() : after.then((_) => _initialize());

  static Future<bool> _initialize() async {
    try {
      final init = Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      // The synchronous part of initialize has made the client.
      _hasClient = true;
      await init;
      return true;
    } catch (e) {
      debugPrint('Supabase init failed, running as guest: $e');
      return false;
    }
  }
}
