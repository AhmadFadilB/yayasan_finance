import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/donation_model.dart';

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

  // Mengambil detail satu proyek publik secara bebas (tanpa auth session checks)
  Future<ProjectModel> getPublicProject(String projectId) async {
    try {
      final projectRes = await _supabase
          .from('projects')
          .select()
          .eq('id', projectId)
          .single();
          
      final txsRes = await _supabase
          .from('transactions')
          .select('amount')
          .eq('project_id', projectId)
          .eq('status', 'approved')
          .eq('type', 'income');
          
      double totalIncome = 0;
      for (var tx in txsRes as List<dynamic>) {
        totalIncome += (tx['amount'] as num).toDouble();
      }
      
      return ProjectModel.fromJson(projectRes, totalIncome: totalIncome);
    } catch (e) {
      rethrow;
    }
  }

  // Mengambil daftar donatur publik yang disetujui (status = approved)
  Future<List<DonationModel>> getProjectDonations(String projectId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select('''
            id,
            donor_name,
            is_anonymous,
            created_at,
            unique_code,
            transactions!inner (
              amount,
              status,
              project_id
            )
          ''')
          .eq('transactions.project_id', projectId)
          .eq('transactions.status', 'approved')
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        if (map['transactions'] != null) {
          map['amount'] = map['transactions']['amount'];
        }
        return DonationModel.fromJson(map);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mengirim donasi pending dari publik
  Future<Map<String, dynamic>> submitPublicDonation({
    required String projectId,
    required String donorName,
    required bool isAnonymous,
    required String? email,
    required String? phone,
    required double baseAmount,
    required int uniqueCode,
    String? receiptUrl,
  }) async {
    try {
      final project = await _supabase
          .from('projects')
          .select('foundation_id')
          .eq('id', projectId)
          .single();
      final foundationId = project['foundation_id'] as String;

      final double totalAmount = baseAmount + uniqueCode;

      final coaRes = await _supabase
          .from('coa')
          .select('id')
          .eq('foundation_id', foundationId)
          .eq('code', '4210')
          .maybeSingle();
      final String? accountId = coaRes?['id'] as String?;

      final txRes = await _supabase
          .from('transactions')
          .insert({
            'foundation_id': foundationId,
            'project_id': projectId,
            'account_id': accountId,
            'type': 'income',
            'amount': totalAmount,
            'category': 'Donasi',
            'description': 'Donasi Publik - $donorName${isAnonymous ? " (Anonim)" : ""}',
            'status': 'pending',
            'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
            'receipt_url': receiptUrl,
          })
          .select('id')
          .single();
      final txId = txRes['id'] as String;

      await _supabase
          .from('donations')
          .insert({
            'transaction_id': txId,
            'donor_name': donorName,
            'is_anonymous': isAnonymous,
            'email': email,
            'phone': phone,
            'unique_code': uniqueCode,
          });

      return {
        'transaction_id': txId,
        'unique_code': uniqueCode,
        'total_amount': totalAmount,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Mengambil informasi bank yayasan terasosiasi dengan proyek
  Future<Map<String, dynamic>> getFoundationBankInfo(String projectId) async {
    try {
      final project = await _supabase
          .from('projects')
          .select('foundation_id')
          .eq('id', projectId)
          .single();
      final foundationId = project['foundation_id'] as String;

      final foundation = await _supabase
          .from('foundations')
          .select('name, description')
          .eq('id', foundationId)
          .single();

      return {
        'foundation_name': foundation['name'] as String,
        'foundation_description': foundation['description'] as String?,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Mengunggah file bukti transfer dari publik ke bucket 'receipts'
  Future<String?> uploadPublicReceipt(String filename, Uint8List bytes) async {
    try {
      final cleanFilename = filename.replaceAll(RegExp(r'[^\w\s\.\-]'), '').replaceAll(' ', '_');
      final String path = 'public/${DateTime.now().millisecondsSinceEpoch}_$cleanFilename';

      await _supabase.storage
          .from('receipts')
          .uploadBinary(path, bytes);

      final String publicUrl = _supabase.storage
          .from('receipts')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Mengambil daftar seluruh proyek publik (dari seluruh yayasan) beserta akumulasi donasi yang disetujui
  Future<List<Map<String, dynamic>>> getAllPublicProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select('*, foundations(name)')
          .eq('is_public', true)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      final List<Map<String, dynamic>> resultList = [];

      for (var item in list) {
        final Map<String, dynamic> projectMap = Map<String, dynamic>.from(item);
        final String projectId = projectMap['id'] as String;

        // Hitung total dana terkumpul (pemasukan disetujui) untuk proyek ini
        final txsRes = await _supabase
            .from('transactions')
            .select('amount')
            .eq('project_id', projectId)
            .eq('status', 'approved')
            .eq('type', 'income');

        double totalIncome = 0;
        for (var tx in txsRes as List<dynamic>) {
          totalIncome += (tx['amount'] as num).toDouble();
        }

        projectMap['total_income'] = totalIncome;
        resultList.add(projectMap);
      }

      return resultList;
    } catch (e) {
      rethrow;
    }
  }
}
