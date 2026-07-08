import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log_model.dart';

class AuditLogService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil daftar log audit pada yayasan aktif
  Future<List<AuditLog>> getAuditLogs(String foundationId) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .eq('foundation_id', foundationId)
          .order('created_at', ascending: false);
      
      final list = response as List<dynamic>;
      return list.map((item) => AuditLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
