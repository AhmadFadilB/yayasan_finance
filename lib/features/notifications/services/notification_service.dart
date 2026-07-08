import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil daftar notifikasi pengguna
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Menandai satu notifikasi sebagai dibaca
  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // Menandai semua notifikasi pengguna sebagai dibaca
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      rethrow;
    }
  }

  // Mendapatkan stream notifikasi secara realtime
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => NotificationModel.fromJson(item))
              .toList();
        });
  }
}
