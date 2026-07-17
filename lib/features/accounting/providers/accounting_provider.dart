import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_handler.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../models/journal_model.dart';
import '../services/accounting_service.dart';

class AccountingState {
  final List<JournalEntryModel> entries;
  final bool isLoading;
  final String? errorMessage;

  AccountingState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AccountingState copyWith({
    List<JournalEntryModel>? entries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccountingState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final accountingServiceProvider = Provider<AccountingService>((ref) {
  return AccountingService();
});

class AccountingNotifier extends StateNotifier<AccountingState> {
  final AccountingService _service;
  final Ref _ref;

  AccountingNotifier(this._service, this._ref) : super(AccountingState()) {
    // Listen to changes in the active foundation
    _ref.listen(foundationProvider, (previous, next) {
      if (next.activeFoundation != null) {
        loadEntries(next.activeFoundation!.id);
      } else {
        state = AccountingState();
      }
    });

    // Initial load if foundation is already selected
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation != null) {
      loadEntries(activeFoundation.id);
    }
  }

  Future<void> loadEntries(String foundationId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _service.getJournalEntries(foundationId);
      state = state.copyWith(entries: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat jurnal: ${ErrorHandler.formatError(e)}',
      );
    }
  }

  Future<bool> addJournalEntry(JournalEntryModel entry) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.createJournalEntry(entry);
      await loadEntries(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mencatat jurnal: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  Future<bool> editJournalEntry(JournalEntryModel entry) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.updateJournalEntry(entry);
      await loadEntries(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memperbarui jurnal: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }

  Future<bool> removeJournalEntry(String entryId) async {
    final activeFoundation = _ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.deleteJournalEntry(entryId);
      await loadEntries(activeFoundation.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus jurnal: ${ErrorHandler.formatError(e)}',
      );
      return false;
    }
  }
}

final accountingProvider = StateNotifierProvider<AccountingNotifier, AccountingState>((ref) {
  final service = ref.watch(accountingServiceProvider);
  return AccountingNotifier(service, ref);
});
