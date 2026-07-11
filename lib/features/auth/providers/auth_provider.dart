import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_handler.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

// State untuk autentikasi
class AuthState {
  final Session? session;
  final ProfileModel? profile;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.session,
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    Session? session,
    ProfileModel? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearProfile = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// StateNotifier untuk mengelola AuthState
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState(session: _authService.currentSession)) {
    // Inisialisasi profil jika session sudah ada dari login sebelumnya
    if (state.session != null) {
      _loadProfile(state.session!.user.id);
    }

    // Dengarkan perubahan status autentikasi dari Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        state = AuthState(session: null, profile: null);
      } else {
        state = state.copyWith(session: session);
        _loadProfile(session.user.id);
      }
    });
  }

  // Load profil dari DB
  Future<void> _loadProfile(String userId) async {
    try {
      final profile = await _authService.getProfile(userId);
      state = state.copyWith(profile: profile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal memuat profil: ${ErrorHandler.formatError(e)}');
    }
  }

  // Aksi Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signIn(email: email, password: password);
      // Profil dimuat otomatis via listener onAuthStateChange
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorHandler.formatError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorHandler.formatError(e));
      return false;
    }
  }

  // Aksi Register
  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signUp(email: email, password: password, name: name);
      // Profil dimuat otomatis via listener
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorHandler.formatError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: ErrorHandler.formatError(e));
      return false;
    }
  }

  // Aksi Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      state = AuthState(session: null, profile: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal logout: ${ErrorHandler.formatError(e)}');
    }
  }
}

// Provider utama untuk AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
