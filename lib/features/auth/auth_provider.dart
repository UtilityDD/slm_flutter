import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/app_config.dart';
import '../../core/models/lineman_profile.dart';
import '../../core/network/supabase_service.dart';
import 'verify_hold.dart';

class AuthState {
  final bool isLoading;
  final LinemanProfile? profile;
  final String? errorMessage;
  final String? email;

  /// Signed in, but the profile could not be fetched: [profile] is the last
  /// copy saved on this phone (or a bare one from the session). Do not write
  /// totals computed from it back to the server.
  final bool offline;

  const AuthState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
    this.email,
    this.offline = false,
  });

  bool get isAuthenticated => profile != null && !profile!.isGuest;
  bool get isGuest => profile != null && profile!.isGuest;

  bool get isAdmin {
    final mail = email?.trim().toLowerCase();
    return mail != null && AppConfig.adminEmails.contains(mail);
  }

  AuthState copyWith({
    bool? isLoading,
    LinemanProfile? profile,
    String? errorMessage,
    String? email,
    bool? offline,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      email: email ?? this.email,
      offline: offline ?? this.offline,
    );
  }
}

/// Shown when the profile cannot be fetched (no raw exception text).
const authOfflineMessage = 'ইন্টারনেট নেই। ফোনে রাখা প্রোফাইল দেখানো হচ্ছে। নেট ফিরলে নিজে থেকে আবার চেষ্টা হবে।';

const _profileCacheKey = 'auth_profile_cache_v1';

/// Last good profile row, so a signed-in lineman stays signed in offline.
class ProfileCache {
  static Future<void> save(String uid, Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode({'uid': uid, 'row': row}));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['uid'] != uid) return null;
      final row = decoded['row'];
      return row is Map ? Map<String, dynamic>.from(row) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
    } catch (_) {}
  }
}

class AuthNotifier extends Notifier<AuthState> {
  int _fetchGen = 0;
  String? _blockNotice;
  Timer? _retry;
  int _retryCount = 0;

  StreamSubscription<sb.AuthState>? _authSub;

  /// Listens to the auth stream. It replays past events, so subscribing after
  /// Supabase has started still delivers the restored session.
  bool _listenAuth() {
    try {
      _authSub ??= SupabaseService.client.auth.onAuthStateChange.listen(_onAuth);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  AuthState build() {
    ref.onDispose(() => _authSub?.cancel());
    if (SupabaseService.hasClient || !SupabaseService.isStarted) {
      // Never started (tests) or broken: guest straight away, as before.
      if (!_listenAuth()) return AuthState(profile: LinemanProfile.guest());
    }
    // main.dart starts Supabase just after the first frame. Wait for it
    // (stays "loading", same as while the profile is fetched), then listen.
    // If restoring failed no initialSession may come: run as guest.
    unawaited(SupabaseService.ready.then((ok) {
      if (!ref.mounted) return;
      final listening = _listenAuth();
      if ((!ok || !listening) && state.isLoading && state.profile == null) {
        state = AuthState(profile: LinemanProfile.guest());
      }
    }));
    ref.onDispose(() => _retry?.cancel());
    try {
      // Coming back to the app is the cheapest "maybe online now" signal.
      final life = AppLifecycleListener(onResume: _retryIfOffline);
      ref.onDispose(life.dispose);
    } catch (_) {}
    return const AuthState(isLoading: true);
  }

  void _retryIfOffline() {
    if (!state.offline) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) unawaited(_fetchProfile(user));
  }

  /// Back-off retry while offline: 15 s, 30 s, 60 s ... capped at 5 min.
  void _scheduleRetry(sb.User user) {
    _retry?.cancel();
    final seconds = (15 * (1 << _retryCount.clamp(0, 5))).clamp(15, 300);
    _retryCount++;
    _retry = Timer(Duration(seconds: seconds), () {
      if (state.offline) unawaited(_fetchProfile(user));
    });
  }

  void _onAuth(sb.AuthState change) {
    final session = change.session;
    switch (change.event) {
      case sb.AuthChangeEvent.initialSession:
      case sb.AuthChangeEvent.signedIn:
        if (session == null) {
          state = AuthState(profile: LinemanProfile.guest());
        } else {
          unawaited(_fetchProfile(session.user));
        }
      case sb.AuthChangeEvent.tokenRefreshed:
      case sb.AuthChangeEvent.userUpdated:
        // A refreshed token means the network is back.
        if (session != null && state.offline) unawaited(_fetchProfile(session.user));
      case sb.AuthChangeEvent.signedOut:
        _fetchGen++;
        _retry?.cancel();
        state = AuthState(profile: LinemanProfile.guest(), errorMessage: _blockNotice);
      default:
        break;
    }
  }

  Future<void> refreshProfile() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null || state.isGuest) return;
    final id = state.profile?.id;
    if (id != null && user.id != id) return;
    await _fetchProfile(user);
  }

  Future<void> _fetchProfile(sb.User user) async {
    final gen = ++_fetchGen;
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        email: user.email,
      );
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (gen != _fetchGen) return;

      if (res != null) {
        var profile = LinemanProfile.fromJson(res);
        if (profile.verified == true) {
          unawaited(ref.read(verifyHoldProvider.notifier).release(user.id));
        } else if (_freshUntouched(user, res)) {
          profile = profile.withVerified(false);
          unawaited(ref.read(verifyHoldProvider.notifier).hold(user.id));
          unawaited(_markUnverified(user.id));
        }
        if (profile.blocked && !state.isAdmin) {
          _blockNotice = 'এই অ্যাকাউন্ট বন্ধ করা হয়েছে। অ্যাডমিনের সাথে যোগাযোগ করুন।';
          await _signOutQuiet();
          state = AuthState(profile: LinemanProfile.guest(), errorMessage: _blockNotice);
          return;
        }
        _retry?.cancel();
        _retryCount = 0;
        unawaited(ProfileCache.save(user.id, res));
        state = AuthState(
          profile: profile,
          isLoading: false,
          email: user.email,
        );
      } else {
        _retry?.cancel();
        _retryCount = 0;
        state = AuthState(
          profile: LinemanProfile.signedIn(
            id: user.id,
            fullName: _googleName(user),
            avatarUrl: _googleAvatar(user),
          ),
          isLoading: false,
          email: user.email,
        );
      }
    } catch (_) {
      if (gen != _fetchGen) return;
      // Keep the session: show the last saved profile (or a bare one from the
      // session) and try again later instead of looking signed out.
      final current = state.profile;
      LinemanProfile? profile =
          current != null && !current.isGuest && current.id == user.id ? current : null;
      if (profile == null) {
        final row = await ProfileCache.load(user.id);
        if (gen != _fetchGen) return;
        if (row != null) {
          try {
            profile = LinemanProfile.fromJson(row);
          } catch (_) {}
        }
      }
      profile ??= LinemanProfile.signedIn(
        id: user.id,
        fullName: _googleName(user),
        avatarUrl: _googleAvatar(user),
      );
      state = AuthState(
        profile: profile,
        isLoading: false,
        email: user.email,
        offline: true,
        errorMessage: authOfflineMessage,
      );
      _scheduleRetry(user);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _blockNotice = null;
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'গুগল থেকে পরিচয় আসেনি। ওয়েব ক্লায়েন্ট আইডি মিলিয়ে দেখুন।',
        );
        return false;
      }
      await SupabaseService.client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on GoogleSignInException catch (e) {
      final quiet =
          e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable;
      if (quiet) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return false;
      }
      final config =
          e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError;
      state = state.copyWith(
        isLoading: false,
        errorMessage: config
            ? 'অ্যাকাউন্ট ফেরেনি। অ্যান্ড্রয়েড ক্লায়েন্ট ওয়েব ক্লায়েন্টের একই প্রজেক্টে রাখুন। প্যাকেজ নাম ও SHA-1 মিলিয়ে আবার চালান।'
            : 'গুগল লগইন হয়নি। আবার চেষ্টা করুন।',
      );
      return false;
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('cancel')) {
        state = state.copyWith(isLoading: false, errorMessage: null);
        return false;
      }
      final String message;
      if (text.contains('database') ||
          text.contains('profiles') ||
          text.contains('trigger')) {
        message = 'নতুন সদস্যের প্রোফাইল তৈরি হয়নি। supabase/fix_new_google_signup.sql একবার চালান।';
      } else if (text.contains('signup') ||
          text.contains('signups not allowed')) {
        message = 'নতুন অ্যাকাউন্ট বন্ধ আছে। সুপাবেসে Allow new users to sign up চালু করুন।';
      } else if (text.contains('nonce')) {
        message = 'সুপাবেসে Google-এর Skip nonce checks চালু করুন।';
      } else {
        message = 'গুগল লগইন হয়নি। আবার চেষ্টা করুন।';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  void continueAsGuest() {
    _fetchGen++;
    _blockNotice = null;
    state = AuthState(profile: LinemanProfile.guest());
  }

  Future<void> signOut() async {
    await _signOutQuiet();
    state = AuthState(profile: LinemanProfile.guest());
  }

  Future<void> _signOutQuiet() async {
    _fetchGen++;
    _retry?.cancel();
    unawaited(ProfileCache.clear());
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
  }
}

bool _googleReady = false;

Future<void> _ensureGoogle() async {
  if (_googleReady) return;
  await GoogleSignIn.instance.initialize(
    serverClientId: AppConfig.googleWebClientId,
  );
  _googleReady = true;
}

String? _googleName(sb.User user) {
  final meta = user.userMetadata;
  final name = meta?['full_name'] ?? meta?['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  final email = user.email;
  if (email != null && email.trim().isNotEmpty) return email.trim();
  return null;
}

String? _googleAvatar(sb.User user) {
  final meta = user.userMetadata;
  final url = meta?['avatar_url'] ?? meta?['picture'];
  if (url is String && url.trim().isNotEmpty) return url.trim();
  return null;
}

bool _freshUntouched(sb.User user, Map<String, dynamic> row) {
  final created = DateTime.tryParse(user.createdAt)?.toUtc();
  if (created == null) return false;
  if (DateTime.now().toUtc().difference(created) > const Duration(minutes: 20)) {
    return false;
  }
  final points = (row['points'] as num?)?.toInt() ?? 0;
  final level = (row['training_level'] as num?)?.toInt() ?? 1;
  if (points > 0 || level > 1) return false;
  final block = row['block']?.toString().trim() ?? '';
  final job = row['job']?.toString().trim() ?? '';
  final phone = (row['phone_number'] ?? row['phone'])?.toString().trim() ?? '';
  return block.isEmpty && job.isEmpty && phone.isEmpty;
}

Future<void> _markUnverified(String id) async {
  try {
    await SupabaseService.client
        .from('profiles')
        .update({'verified': false})
        .eq('id', id);
  } catch (_) {}
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
