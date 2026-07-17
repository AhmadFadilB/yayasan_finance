import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_model.dart';

class AccountingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all journal entries for a foundation
  Future<List<JournalEntryModel>> getJournalEntries(String foundationId) async {
    try {
      final response = await _supabase
          .from('journal_entries')
          .select('*, profiles(name)')
          .eq('foundation_id', foundationId)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      final List<JournalEntryModel> entries = [];
      for (var row in response as List<dynamic>) {
        final entryId = row['id'] as String;

        // Fetch associated items for this entry
        final itemsRes = await _supabase
            .from('journal_items')
            .select('*, chart_of_accounts(code, name), projects(name)')
            .eq('entry_id', entryId);

        final items = (itemsRes as List<dynamic>)
            .map((itemRow) => JournalItemModel.fromJson(itemRow as Map<String, dynamic>))
            .toList();

        entries.add(JournalEntryModel.fromJson(row as Map<String, dynamic>, items: items));
      }

      return entries;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new journal entry atomically using database RPC
  Future<String> createJournalEntry(JournalEntryModel entry) async {
    try {
      final itemsJson = entry.items.map((item) => {
        'account_id': item.accountId,
        'debit': item.debit,
        'credit': item.credit,
        if (item.projectId != null) 'project_id': item.projectId,
        if (item.memo != null) 'memo': item.memo,
      }).toList();

      final response = await _supabase.rpc(
        'create_journal_entry',
        params: {
          'p_foundation_id': entry.foundationId,
          'p_proof_number': entry.proofNumber,
          'p_transaction_date': entry.transactionDate.toIso8601String().substring(0, 10),
          'p_description': entry.description,
          'p_items': itemsJson,
        },
      );

      return response as String;
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing journal entry atomically using database RPC
  Future<void> updateJournalEntry(JournalEntryModel entry) async {
    try {
      final itemsJson = entry.items.map((item) => {
        'account_id': item.accountId,
        'debit': item.debit,
        'credit': item.credit,
        if (item.projectId != null) 'project_id': item.projectId,
        if (item.memo != null) 'memo': item.memo,
      }).toList();

      await _supabase.rpc(
        'update_journal_entry',
        params: {
          'p_entry_id': entry.id,
          'p_proof_number': entry.proofNumber,
          'p_transaction_date': entry.transactionDate.toIso8601String().substring(0, 10),
          'p_description': entry.description,
          'p_change_reason': entry.changeReason,
          'p_items': itemsJson,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete a journal entry (will cascade delete items)
  Future<void> deleteJournalEntry(String entryId) async {
    try {
      await _supabase
          .from('journal_entries')
          .delete()
          .eq('id', entryId);
    } catch (e) {
      rethrow;
    }
  }
}
