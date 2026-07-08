import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mendapatkan session user saat ini
  Session? get currentSession => _supabase.auth.currentSession;

  // Mendapatkan user auth saat ini
  User? get currentUser => _supabase.auth.currentUser;

  // Login dengan Email & Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Register dengan Email & Password + Simpan nama di metadata
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout dari aplikasi
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan profil pengguna berdasarkan ID dari database PostgreSQL
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // Mengubah nama profil saat ini
  Future<void> updateProfileName(String userId, String newName) async {
    try {
      await _supabase
          .from('profiles')
          .update({'name': newName})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
