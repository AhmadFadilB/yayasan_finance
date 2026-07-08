import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coa_model.dart';

class CoaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil bagan akun (COA) untuk yayasan tertentu
  Future<List<CoaModel>> getCoa(String foundationId) async {
    try {
      final response = await _supabase
          .from('chart_of_accounts')
          .select()
          .eq('foundation_id', foundationId)
          .order('code', ascending: true);
      
      final list = response as List<dynamic>;
      return list.map((item) => CoaModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Membuat akun COA baru
  Future<CoaModel> createCoa(CoaModel coa) async {
    try {
      final Map<String, dynamic> data = coa.toJson();
      if (coa.id.isEmpty) {
        data.remove('id');
      }
      
      final response = await _supabase
          .from('chart_of_accounts')
          .insert(data)
          .select()
          .single();
      
      return CoaModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Memperbarui akun COA
  Future<CoaModel> updateCoa(CoaModel coa) async {
    try {
      final response = await _supabase
          .from('chart_of_accounts')
          .update(coa.toJson())
          .eq('id', coa.id)
          .select()
          .single();
      
      return CoaModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus akun COA
  Future<void> deleteCoa(String coaId) async {
    try {
      await _supabase
          .from('chart_of_accounts')
          .delete()
          .eq('id', coaId);
    } catch (e) {
      rethrow;
    }
  }
}
