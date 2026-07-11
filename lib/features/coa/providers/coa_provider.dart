import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/error_handler.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../models/coa_model.dart';
import '../services/coa_service.dart';

class CoaState {
  final List<CoaModel> coaList;
  final bool isLoading;
  final String? errorMessage;

  CoaState({
    this.coaList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CoaState copyWith({
    List<CoaModel>? coaList,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CoaState(
      coaList: coaList ?? this.coaList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final coaServiceProvider = Provider<CoaService>((ref) {
  return CoaService();
});

class CoaNotifier extends StateNotifier<CoaState> {
  final CoaService _service;
  final Ref _ref;

  CoaNotifier(this._service, this._ref) : super(CoaState()) {
    // Dengarkan perubahan yayasan aktif. Jika berganti, load ulang COA.
    _ref.listen(foundationProvider, (previous, next) {
      if (next.activeFoundation != null) {
        loadCoa(next.activeFoundation!.id);
      } else {
        state = CoaState();
      }
    });

    // Inisialisasi awal jika ada yayasan aktif
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation != null) {
      loadCoa(activeFoundation.id);
    }
  }

  // Memuat bagan akun (COA) dari database
  Future<void> loadCoa(String foundationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getCoa(foundationId);
      state = state.copyWith(
        coaList: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat Bagan Akun: ${ErrorHandler.formatError(e)}',
      );
    }
  }

  // Menambahkan akun COA baru
  Future<bool> addCoa({
    required String code,
    required String name,
    required String category,
    String? parentCode,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) {
      state = state.copyWith(errorMessage: 'Tidak ada yayasan aktif.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newCoa = CoaModel(
        id: '', // Di-generate otomatis oleh DB
        foundationId: activeFoundation.id,
        code: code,
        name: name,
        category: category,
        parentCode: parentCode,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _service.createCoa(newCoa);
      await loadCoa(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menambahkan akun: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  // Mengubah akun COA yang ada
  Future<bool> updateCoa({
    required String id,
    required String code,
    required String name,
    required String category,
    required bool isActive,
    String? parentCode,
  }) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final coa = CoaModel(
        id: id,
        foundationId: activeFoundation.id,
        code: code,
        name: name,
        category: category,
        parentCode: parentCode,
        isActive: isActive,
        createdAt: DateTime.now(), // Diabaikan oleh DB update
      );

      await _service.updateCoa(coa);
      await loadCoa(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui akun: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  // Menghapus akun COA
  Future<bool> deleteCoa(String coaId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.deleteCoa(coaId);
      await loadCoa(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus akun: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }
}

// Provider utama untuk coa state
final coaProvider = StateNotifierProvider<CoaNotifier, CoaState>((ref) {
  final service = ref.watch(coaServiceProvider);
  return CoaNotifier(service, ref);
});

// Provider penyaring akun aktif saja untuk kegunaan dropdown form
final activeCoaProvider = Provider<List<CoaModel>>((ref) {
  final coaState = ref.watch(coaProvider);
  return coaState.coaList.where((account) => account.isActive).toList();
});

class ShowCoaCodeNotifier extends StateNotifier<bool> {
  ShowCoaCodeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('show_coa_code') ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_coa_code', value);
  }
}

final showCoaCodeProvider = StateNotifierProvider<ShowCoaCodeNotifier, bool>((ref) {
  return ShowCoaCodeNotifier();
});
