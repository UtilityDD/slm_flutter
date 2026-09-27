import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/lineman_profile.dart';
import '../../core/network/supabase_service.dart';

class AuthState {
  final bool isLoading;
  final LinemanProfile? profile;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
  });

  bool get isAuthenticated => profile != null && !profile!.isGuest;
  bool get isGuest => profile != null && profile!.isGuest;

  AuthState copyWith({
    bool? isLoading,
    LinemanProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initAuth();
    return const AuthState(isLoading: true);
  }

  void _initAuth() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        await _fetchProfile(session.user.id);
      } else {
        state = AuthState(profile: LinemanProfile.guest(), isLoading: false);
      }
    } catch (_) {
      state = AuthState(profile: LinemanProfile.guest(), isLoading: false);
    }
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        state = AuthState(
          profile: LinemanProfile.fromJson(res),
          isLoading: false,
        );
      } else {
        state = AuthState(profile: LinemanProfile.guest(), isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'প্রোফাইল লোড করতে ব্যর্থ হয়েছে: $e',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _fetchProfile(response.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'লগইন ত্রুটি: অনুগ্রহ করে সঠিক তথ্য দিন।',
      );
      return false;
    }
  }

  void continueAsGuest() {
    state = AuthState(profile: LinemanProfile.guest(), isLoading: false);
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } finally {
      state = AuthState(profile: LinemanProfile.guest(), isLoading: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
