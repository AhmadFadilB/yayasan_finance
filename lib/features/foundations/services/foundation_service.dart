import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/foundation_model.dart';

class FoundationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil daftar yayasan yang diikuti oleh pengguna tertentu
  Future<List<FoundationModel>> getFoundationsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('foundation_members')
          .select('role, foundations(*)')
          .eq('profile_id', userId);
      
      final list = response as List<dynamic>;
      return list.map((item) => FoundationModel.fromJoinJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Membuat yayasan baru.
  // Otomatis menolak jika nama kosong. Database trigger otomatis mendaftarkan pembuat sebagai admin.
  Future<FoundationModel> createFoundation({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('foundations')
          .insert({
            'name': name,
            'description': description,
          })
          .select()
          .single();
      
      // Karena trigger di DB butuh waktu asinkron sepersekian milidetik untuk menulis data ke table foundation_members,
      // kita set role pembuat secara lokal sebagai 'admin'.
      return FoundationModel.fromJson(response, role: 'admin');
    } catch (e) {
      rethrow;
    }
  }

  // Mengambil daftar seluruh anggota pada yayasan tertentu
  Future<List<FoundationMemberModel>> getMembers(String foundationId) async {
    try {
      final response = await _supabase
          .from('foundation_members')
          .select('role, created_at, profiles(id, name)')
          .eq('foundation_id', foundationId);
      
      final list = response as List<dynamic>;
      return list.map((item) => FoundationMemberModel.fromJoinJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mengundang anggota baru menggunakan alamat email via RPC Supabase
  Future<void> addMemberByEmail({
    required String foundationId,
    required String email,
    required String role,
  }) async {
    try {
      await _supabase.rpc(
        'add_member_by_email',
        params: {
          'p_foundation_id': foundationId,
          'p_email': email,
          'p_role': role,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
