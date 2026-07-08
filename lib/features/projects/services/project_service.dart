import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil daftar seluruh proyek pada yayasan tertentu
  Future<List<ProjectModel>> getProjects(String foundationId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('foundation_id', foundationId)
          .order('created_at', ascending: false);
      
      final list = response as List<dynamic>;
      return list.map((item) => ProjectModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan proyek baru
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final Map<String, dynamic> data = project.toJson();
      if (project.id.isEmpty) {
        data.remove('id');
      }
      
      final response = await _supabase
          .from('projects')
          .insert(data)
          .select()
          .single();
      
      return ProjectModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Mengedit proyek yang sudah ada
  Future<ProjectModel> updateProject(ProjectModel project) async {
    try {
      final response = await _supabase
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id)
          .select()
          .single();
      
      return ProjectModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus proyek
  Future<void> deleteProject(String projectId) async {
    try {
      await _supabase
          .from('projects')
          .delete()
          .eq('id', projectId);
    } catch (e) {
      rethrow;
    }
  }
}
