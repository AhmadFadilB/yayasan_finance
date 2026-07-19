import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/utils/formatter.dart';
import '../../coa/providers/coa_provider.dart';
import '../../coa/models/coa_model.dart';
import '../../projects/providers/project_provider.dart';
import '../../projects/models/project_model.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../providers/accounting_provider.dart';
import '../models/journal_model.dart';

class JournalFormScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const JournalFormScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends ConsumerState<JournalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _proofNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _changeReasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<JournalItemModel> _items = [];
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.entryId != null;
    
    // Seed at least 2 rows for double-entry (Debit & Credit)
    if (!_isEdit) {
      _items = [
        JournalItemModel(id: '', entryId: '', accountId: '', debit: 0, credit: 0),
        JournalItemModel(id: '', entryId: '', accountId: '', debit: 0, credit: 0),
      ];
      _generateProofNumber();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingEntryData());
    }
  }

  void _generateProofNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    _proofNumberController.text = 'JV-$dateStr-$rand';
  }

  void _loadExistingEntryData() {
    final state = ref.read(accountingProvider);
    final entry = state.entries.firstWhere((e) => e.id == widget.entryId);
    
    setState(() {
      _proofNumberController.text = entry.proofNumber;
      _descriptionController.text = entry.description ?? '';
      _selectedDate = entry.transactionDate;
      _items = entry.items.map((i) => i.copyWith()).toList();
    });
  }

  double get _totalDebit => _items.fold(0.0, (sum, item) => sum + item.debit);
  double get _totalCredit => _items.fold(0.0, (sum, item) => sum + item.credit);
  bool get _isBalanced => (_totalDebit - _totalCredit).abs() < 0.01;

  void _addNewRow() {
    setState(() {
      _items.add(JournalItemModel(id: '', entryId: '', accountId: '', debit: 0, credit: 0));
    });
  }

  void _removeRow(int index) {
    if (_items.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jurnal double-entry minimal memerlukan 2 baris (Debit & Kredit).'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coaState = ref.watch(coaProvider);
    final projectState = ref.watch(projectProvider);
    final accountingState = ref.watch(accountingProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Voucher Jurnal' : 'Tambah Voucher Jurnal Baru',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: accountingState.isLoading ? null : _saveForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
              ),
              child: Text(accountingState.isLoading ? 'Menyimpan...' : 'Simpan'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Informasi Utama
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Utama Jurnal',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proofNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Bukti (Voucher)',
                              hintText: 'JV-YYYYMMDD-XXX',
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Nomor bukti tidak boleh kosong.' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Transaksi',
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(Formatter.formatTanggal(_selectedDate)),
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Jurnal / Memo Global',
                        hintText: 'Tulis deskripsi ringkas tentang transaksi ini...',
                      ),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _changeReasonController,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Perubahan (Audit Trail)',
                          hintText: 'Mengapa voucher jurnal ini perlu diubah?',
                        ),
                        validator: (v) => v == null || v.trim().length < 5 
                            ? 'Alasan perubahan minimal 5 karakter wajib disertakan.' 
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Baris Item Debit/Kredit
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entri Baris Jurnal',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: _addNewRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Baris'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: _items.length,
                       itemBuilder: (context, index) {
                         return _buildItemRow(index, coaState.coaList, projectState.projects);
                       },
                     ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),

                    // Balance Footer Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTotalIndicator('Total Debit:', _totalDebit, const Color(0xFF0F5A47)),
                        const SizedBox(width: 32),
                        _buildTotalIndicator('Total Kredit:', _totalCredit, const Color(0xFFE53935)),
                        const SizedBox(width: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isBalanced ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20),
                            borderRadius: AppRadius.radiusSm,
                            border: Border.all(
                              color: _isBalanced ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isBalanced ? Icons.check_circle_outline : Icons.error_outline,
                                color: _isBalanced ? Colors.green[800] : Colors.red[800],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isBalanced ? 'Balanced (Seimbang)' : 'Unbalanced (Belum Seimbang)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _isBalanced ? Colors.green[900] : Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalIndicator(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
        const SizedBox(height: 2),
        Text(
          Formatter.formatRupiah(amount),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(int index, List<CoaModel> accounts, List<ProjectModel> projects) {
    final item = _items[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown Akun COA
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: item.accountId.isEmpty ? null : item.accountId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Pilih Akun'),
              items: accounts.map((acc) {
                return DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.code} - ${acc.name}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _items[index] = item.copyWith(accountId: value);
                  });
                }
              },
              validator: (v) => v == null || v.isEmpty ? 'Akun wajib dipilih.' : null,
            ),
          ),
          const SizedBox(width: 12),

          // Input Debit
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.debit > 0 ? item.debit.toStringAsFixed(0) : '',
              decoration: const InputDecoration(labelText: 'Debit', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final double val = double.tryParse(value) ?? 0.0;
                setState(() {
                  _items[index] = item.copyWith(debit: val, credit: val > 0 ? 0.0 : item.credit);
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Input Kredit
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.credit > 0 ? item.credit.toStringAsFixed(0) : '',
              decoration: const InputDecoration(labelText: 'Kredit', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final double val = double.tryParse(value) ?? 0.0;
                setState(() {
                  _items[index] = item.copyWith(credit: val, debit: val > 0 ? 0.0 : item.debit);
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Dropdown Proyek (Opsional)
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              initialValue: item.projectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Proyek'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Umum (Non-Proyek)')),
                ...projects.map((proj) {
                  return DropdownMenuItem(value: proj.id, child: Text(proj.name));
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _items[index] = item.copyWith(projectId: value);
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Input Memo
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.memo ?? '',
              decoration: const InputDecoration(labelText: 'Memo'),
              onChanged: (value) {
                setState(() {
                  _items[index] = item.copyWith(memo: value);
                });
              },
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Delete Row
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeRow(index),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total Debit dan Kredit tidak seimbang. Silakan sesuaikan kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verify each line has either debit or credit, but not both
    for (var item in _items) {
      if (item.debit == 0 && item.credit == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setiap baris jurnal harus memiliki nominal Debit atau Kredit.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final activeFoundation = ref.read(foundationProvider).activeFoundation;
    if (activeFoundation == null) return;

    final entry = JournalEntryModel(
      id: widget.entryId ?? '',
      foundationId: activeFoundation.id,
      proofNumber: _proofNumberController.text,
      transactionDate: _selectedDate,
      description: _descriptionController.text,
      changeReason: _isEdit ? _changeReasonController.text : null,
      createdAt: DateTime.now(),
      items: _items,
    );

    final success = _isEdit 
        ? await ref.read(accountingProvider.notifier).editJournalEntry(entry)
        : await ref.read(accountingProvider.notifier).addJournalEntry(entry);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Jurnal berhasil diperbarui!' : 'Jurnal berhasil disimpan!'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      context.pop();
    } else if (mounted) {
      final err = ref.read(accountingProvider).errorMessage ?? 'Gagal memproses jurnal.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
