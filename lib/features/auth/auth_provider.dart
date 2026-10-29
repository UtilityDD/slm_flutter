import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  const AuthState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
    this.email,
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
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      email: email ?? this.email,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  int _fetchGen = 0;

  @override
  AuthState build() {
    try {
      final sub = SupabaseService.client.auth.onAuthStateChange.listen(_onAuth);
      ref.onDispose(sub.cancel);
    } catch (_) {
      return AuthState(profile: LinemanProfile.guest());
    }
    return const AuthState(isLoading: true);
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
      case sb.AuthChangeEvent.signedOut:
        _fetchGen++;
        state = AuthState(profile: LinemanProfile.guest());
      default:
        break;
    }
  }

  Future<void> refreshProfile() async {
    final id = state.profile?.id;
    if (id == null || state.isGuest) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null || user.id != id) return;
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
        state = AuthState(
          profile: profile,
          isLoading: false,
          email: user.email,
        );
      } else {
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
    } catch (e) {
      if (gen != _fetchGen) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'প্রোফাইল লোড করতে ব্যর্থ হয়েছে: $e',
      );
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
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
    state = AuthState(profile: LinemanProfile.guest());
  }

  Future<void> signOut() async {
    _fetchGen++;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await SupabaseService.client.auth.signOut();
    } finally {
      state = AuthState(profile: LinemanProfile.guest());
    }
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
  if (DateTime.now().toUtc().difference(created) > const Duration(minutes: 20))
    return false;
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
