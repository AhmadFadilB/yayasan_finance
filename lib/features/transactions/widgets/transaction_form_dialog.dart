import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/components/app_button.dart';
import '../../projects/providers/project_provider.dart';
import '../../coa/providers/coa_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionFormDialog extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // Jika ada nilainya berarti mode edit, jika null berarti mode tambah

  const TransactionFormDialog({super.key, this.transaction});

  static Future<void> show(BuildContext context, {TransactionModel? transaction}) {
    return AppModal.show<void>(
      context: context,
      title: Text(transaction != null ? 'Ubah Transaksi' : 'Catat Transaksi'),
      subtitle: transaction != null ? 'Ubah rincian data transaksi keuangan' : 'Catat pemasukan atau pengeluaran baru',
      content: TransactionFormDialog(transaction: transaction),
    );
  }

  @override
  ConsumerState<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends ConsumerState<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descController;
  String _type = 'income'; // 'income' atau 'expense'
  String _category = 'Donasi';
  String? _selectedAccountId;
  String? _selectedProjectId;
  DateTime _transactionDate = DateTime.now();

  PlatformFile? _pickedFile;
  String? _receiptUrl;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction?.type ?? 'income';
    _amountController = TextEditingController(
      text: widget.transaction != null ? widget.transaction!.amount.toInt().toString() : '',
    );
    _descController = TextEditingController(text: widget.transaction?.description ?? '');
    _category = widget.transaction?.category ?? (_type == 'income' ? 'Donasi' : 'Operasional');
    _selectedAccountId = widget.transaction?.accountId;
    _selectedProjectId = widget.transaction?.projectId;
    _transactionDate = widget.transaction?.transactionDate ?? DateTime.now();
    _receiptUrl = widget.transaction?.receiptUrl;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: AppTheme.colorError,
          ),
        );
      }
    }
  }

  void _clearReceipt() {
    setState(() {
      _pickedFile = null;
      _receiptUrl = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploadingFile = true;
    });

    try {
      String? finalReceiptUrl = _receiptUrl;

      // Unggah berkas jika ada file yang baru dipilih
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        final uploadedUrl = await ref
            .read(transactionProvider.notifier)
            .uploadReceiptFile(_pickedFile!.name, _pickedFile!.bytes!);

        if (uploadedUrl != null) {
          finalReceiptUrl = uploadedUrl;
        } else {
          throw Exception('Gagal mengunggah berkas bukti transaksi.');
        }
      }

      final success = widget.transaction != null
          ? await ref.read(transactionProvider.notifier).updateTransaction(
                id: widget.transaction!.id,
                projectId: _selectedProjectId,
                accountId: _selectedAccountId,
                type: _type,
                amount: double.parse(_amountController.text),
                category: _category,
                description: _descController.text,
                transactionDate: _transactionDate,
                receiptUrl: finalReceiptUrl,
              )
          : await ref.read(transactionProvider.notifier).addTransaction(
                projectId: _selectedProjectId,
                accountId: _selectedAccountId,
                type: _type,
                amount: double.parse(_amountController.text),
                category: _category,
                description: _descController.text,
                transactionDate: _transactionDate,
                receiptUrl: finalReceiptUrl,
              );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction != null
                ? 'Transaksi berhasil diperbarui'
                : 'Transaksi berhasil dicatat'),
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.colorError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider).projects;
    final transactionState = ref.watch(transactionProvider);
    final coaList = ref.watch(activeCoaProvider);
    final coaState = ref.watch(coaProvider);
    final showCoaCode = ref.watch(showCoaCodeProvider);
    final isEdit = widget.transaction != null;
    final isLoading = transactionState.isLoading || _isUploadingFile;

    // Filter daftar akun COA sesuai tipe transaksi
    final filteredCoa = coaList.where((acc) {
      return _type == 'income' ? acc.category == 'revenue' : acc.category == 'expense';
    }).toList();

    // Pastikan selected ID ada di daftar terfilter, jika tidak pilih yang pertama secara default
    final hasSelectedAccount = filteredCoa.any((acc) => acc.id == _selectedAccountId);
    if (!hasSelectedAccount && filteredCoa.isNotEmpty) {
      _selectedAccountId = filteredCoa.first.id;
      _category = filteredCoa.first.name;
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Button Tipe Transaksi
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'income',
                label: Text('Debit (Uang Masuk)'),
                icon: Icon(Icons.arrow_downward, size: 16),
              ),
              ButtonSegment(
                value: 'expense',
                label: Text('Kredit (Uang Keluar)'),
                icon: Icon(Icons.arrow_upward, size: 16),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (newSelection) {
              setState(() {
                _type = newSelection.first;
                // Reset selected account ID agar memilih default tipe akun baru
                _selectedAccountId = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Field Jumlah (Amount)
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal Transaksi (Rp)',
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: '150000',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Jumlah uang tidak boleh kosong';
              }
              final n = num.tryParse(value);
              if (n == null || n <= 0) {
                return 'Masukkan nominal angka yang valid (lebih besar dari 0)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Dropdown Kategori Akun (COA)
          coaState.isLoading && coaList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              : DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Akun (COA)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: filteredCoa.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text(showCoaCode ? '${acc.code} - ${acc.name}' : acc.name),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Harap pilih kategori akun';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value != null) {
                      final acc = filteredCoa.firstWhere((element) => element.id == value);
                      setState(() {
                        _selectedAccountId = value;
                        _category = acc.name;
                      });
                    }
                  },
                ),
          const SizedBox(height: 16),

          // Dropdown Proyek
          DropdownButtonFormField<String?>(
            initialValue: _selectedProjectId,
            decoration: const InputDecoration(
              labelText: 'Proyek Terkait (Opsional)',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Umum (Tidak terikat proyek)')),
              ...projects.map((proj) {
                return DropdownMenuItem(value: proj.id, child: Text(proj.name));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedProjectId = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Date Picker
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
            ),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              'Tanggal: ${Formatter.formatTanggal(_transactionDate)}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Field Deskripsi
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Keterangan Tambahan',
              hintText: 'Donasi hamba Allah via transfer...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Bukti Transaksi (Upload File Section)
          Text(
            'Bukti Transaksi (Opsional)',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          if (_pickedFile != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(12),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pickedFile!.name,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: _clearReceipt,
                  ),
                ],
              ),
            ),
          ] else if (_receiptUrl != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: AppRadius.radiusSm,
                border: Border.all(color: Colors.grey.withAlpha(45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bukti Transaksi Terunggah',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _clearReceipt,
                  ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.5),
              ),
              onPressed: _pickReceipt,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Pilih Berkas Bukti (Gambar / PDF)'),
            ),
          ],
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Batal',
                style: AppButtonStyle.outline,
                onPressed: isLoading ? null : () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              AppButton(
                text: isEdit ? 'Simpan' : 'Catat',
                style: AppButtonStyle.primary,
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
