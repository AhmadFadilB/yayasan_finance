import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../models/audit_log_model.dart';
import '../services/audit_log_service.dart';

class AuditLogState {
  final List<AuditLog> logs;
  final bool isLoading;
  final String? errorMessage;

  AuditLogState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AuditLogState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuditLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return AuditLogService();
});

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  final AuditLogService _service;
  final Ref _ref;

  AuditLogNotifier(this._service, this._ref) : super(AuditLogState()) {
    // Dengarkan perubahan yayasan aktif. Jika berganti, load ulang log audit.
    _ref.listen(foundationProvider, (previous, next) {
      if (next.activeFoundation != null) {
        loadLogs(next.activeFoundation!.id);
      } else {
        state = AuditLogState();
      }
    });

    // Dengarkan perubahan transaksi. Jika ada transaksi baru/diubah/dihapus, refresh log.
    _ref.listen(transactionProvider, (previous, next) {
      final activeFoundation = _ref.read(foundationProvider).activeFoundation;
      if (activeFoundation != null && !next.isLoading && previous?.transactions != next.transactions) {
        loadLogs(activeFoundation.id);
      }
    });

    // Dengarkan perubahan proyek. Jika ada proyek baru/diubah/dihapus, refresh log.
    _ref.listen(projectProvider, (previous, next) {
      final activeFoundation = _ref.read(foundationProvider).activeFoundation;
      if (activeFoundation != null && !next.isLoading && previous?.projects != next.projects) {
        loadLogs(activeFoundation.id);
      }
    });

    // Inisialisasi awal jika ada yayasan aktif
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation != null) {
      loadLogs(activeFoundation.id);
    }
  }

  // Memuat daftar log audit dari database
  Future<void> loadLogs(String foundationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getAuditLogs(foundationId);
      state = state.copyWith(
        logs: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat log audit: ${e.toString()}',
      );
    }
  }
}

// Provider utama untuk audit log state
final auditLogProvider = StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  final service = ref.watch(auditLogServiceProvider);
  return AuditLogNotifier(service, ref);
});
