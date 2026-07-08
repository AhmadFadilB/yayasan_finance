import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

// State untuk daftar transaksi
class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider untuk TransactionService
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

// StateNotifier untuk mengelola transaksi
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _service;
  final Ref _ref;

  TransactionNotifier(this._service, this._ref) : super(TransactionState()) {
    // Dengarkan perubahan yayasan aktif. Jika berganti, load ulang transaksi.
    _ref.listen(foundationProvider, (previous, next) {
      if (next.activeFoundation != null) {
        loadTransactions(next.activeFoundation!.id);
      } else {
        state = TransactionState();
      }
    });

    // Inisialisasi awal jika sudah ada yayasan aktif
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation != null) {
      loadTransactions(activeFoundation.id);
    }
  }

  // Mengambil daftar transaksi dari database
  Future<void> loadTransactions(String foundationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getTransactions(foundationId);
      state = state.copyWith(
        transactions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat transaksi: ${e.toString()}',
      );
    }
  }

  // Mengunggah file bukti transaksi ke Supabase Storage
  Future<String?> uploadReceiptFile(String filename, Uint8List bytes) async {
    try {
      final activeFoundation = _ref.read(foundationProvider).activeFoundation;
      if (activeFoundation == null) return null;

      final cleanFilename = filename.replaceAll(RegExp(r'[^\w\s\.\-]'), '').replaceAll(' ', '_');
      final String path = '${activeFoundation.id}/${DateTime.now().millisecondsSinceEpoch}_$cleanFilename';

      await Supabase.instance.client.storage
          .from('receipts')
          .uploadBinary(path, bytes);

      final String publicUrl = Supabase.instance.client.storage
          .from('receipts')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengunggah bukti: ${e.toString()}');
      return null;
    }
  }

  // Menambahkan transaksi baru
  Future<bool> addTransaction({
    required String? projectId,
    required String? accountId,
    required String type,
    required double amount,
    required String category,
    required String? description,
    required DateTime transactionDate,
    String? receiptUrl,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    final currentUser = _ref.read(authProvider).session?.user;
    
    if (activeFoundation == null || currentUser == null) {
      state = state.copyWith(errorMessage: 'Aksi tidak diizinkan. Periksa koneksi.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final userRole = activeFoundation.currentUserRole ?? 'viewer';
      final String initialStatus = (type == 'expense' && amount >= 1000000 && userRole == 'bendahara')
          ? 'pending'
          : 'approved';

      final newTx = TransactionModel(
        id: '', // Di-generate otomatis oleh DB
        foundationId: activeFoundation.id,
        projectId: projectId,
        accountId: accountId,
        type: type,
        amount: amount,
        category: category,
        description: description,
        transactionDate: transactionDate,
        createdBy: currentUser.id,
        createdAt: DateTime.now(),
        receiptUrl: receiptUrl,
        status: initialStatus,
      );

      await _service.createTransaction(newTx);
      // Muat ulang daftar transaksi
      await loadTransactions(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambahkan transaksi: ${e.toString()}',
      );
      return false;
    }
  }

  // Mengupdate transaksi
  Future<bool> updateTransaction({
    required String id,
    required String? projectId,
    required String? accountId,
    required String type,
    required double amount,
    required String category,
    required String? description,
    required DateTime transactionDate,
    String? receiptUrl,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    final currentUser = _ref.read(authProvider).session?.user;
    
    if (activeFoundation == null || currentUser == null) {
      state = state.copyWith(errorMessage: 'Aksi tidak diizinkan.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final existingTx = state.transactions.firstWhere((t) => t.id == id);
      final userRole = activeFoundation.currentUserRole ?? 'viewer';
      final String newStatus = (type == 'expense' && amount >= 1000000 && userRole == 'bendahara')
          ? 'pending'
          : (userRole == 'admin' ? 'approved' : existingTx.status);

      final tx = TransactionModel(
        id: id,
        foundationId: activeFoundation.id,
        projectId: projectId,
        accountId: accountId,
        type: type,
        amount: amount,
        category: category,
        description: description,
        transactionDate: transactionDate,
        createdBy: existingTx.createdBy,
        createdAt: existingTx.createdAt,
        receiptUrl: receiptUrl ?? existingTx.receiptUrl,
        status: newStatus,
        approvedBy: newStatus == 'approved' ? existingTx.approvedBy : null,
        approvedAt: newStatus == 'approved' ? existingTx.approvedAt : null,
      );

      await _service.updateTransaction(tx);
      await loadTransactions(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui transaksi: ${e.toString()}',
      );
      return false;
    }
  }

  // Menyetujui transaksi (oleh Admin)
  Future<bool> approveTransaction(String transactionId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    final currentUser = _ref.read(authProvider).session?.user;

    if (activeFoundation == null || currentUser == null) {
      state = state.copyWith(errorMessage: 'Aksi tidak diizinkan.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final existingTx = state.transactions.firstWhere((tx) => tx.id == transactionId);
      final updatedTx = existingTx.copyWith(
        status: 'approved',
        approvedBy: currentUser.id,
        approvedAt: DateTime.now(),
      );

      await _service.updateTransaction(updatedTx);
      await loadTransactions(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyetujui transaksi: ${e.toString()}',
      );
      return false;
    }
  }

  // Menolak transaksi (oleh Admin)
  Future<bool> rejectTransaction(String transactionId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    final currentUser = _ref.read(authProvider).session?.user;

    if (activeFoundation == null || currentUser == null) {
      state = state.copyWith(errorMessage: 'Aksi tidak diizinkan.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final existingTx = state.transactions.firstWhere((tx) => tx.id == transactionId);
      final updatedTx = existingTx.copyWith(
        status: 'rejected',
        approvedBy: currentUser.id,
        approvedAt: DateTime.now(),
      );

      await _service.updateTransaction(updatedTx);
      await loadTransactions(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menolak transaksi: ${e.toString()}',
      );
      return false;
    }
  }

  // Menghapus transaksi
  Future<bool> deleteTransaction(String transactionId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.deleteTransaction(transactionId);
      await loadTransactions(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus transaksi: ${e.toString()}',
      );
      return false;
    }
  }
}

// Provider utama untuk daftar transaksi
final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionNotifier(service, ref);
});
