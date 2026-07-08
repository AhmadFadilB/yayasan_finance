import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil daftar seluruh transaksi pada yayasan tertentu dengan join data project & profile
  Future<List<TransactionModel>> getTransactions(String foundationId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('*, projects(name), profiles!transactions_created_by_fkey(name), approver:approved_by(name)')
          .eq('foundation_id', foundationId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);
      
      final list = response as List<dynamic>;
      return list.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan transaksi baru ke database
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final Map<String, dynamic> data = transaction.toJson();
      // Hilangkan field ID jika string kosong untuk membiarkan DB generate otomatis UUID
      if (transaction.id.isEmpty) {
        data.remove('id');
      }
      
      final response = await _supabase
          .from('transactions')
          .insert(data)
          .select('*, projects(name), profiles!transactions_created_by_fkey(name), approver:approved_by(name)')
          .single();
      
      return TransactionModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Mengedit transaksi yang sudah ada
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    try {
      final response = await _supabase
          .from('transactions')
          .update(transaction.toJson())
          .eq('id', transaction.id)
          .select('*, projects(name), profiles!transactions_created_by_fkey(name), approver:approved_by(name)')
          .single();
      
      return TransactionModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Menghapus transaksi
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId);
    } catch (e) {
      rethrow;
    }
  }
}
