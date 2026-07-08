import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/formatter.dart';
import '../../projects/providers/project_provider.dart';
import '../../coa/providers/coa_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionFormDialog extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // Jika ada nilainya berarti mode edit, jika null berarti mode tambah

  const TransactionFormDialog({super.key, this.transaction});

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearReceipt() {
    setState(() {
      _pickedFile = null;
      _receiptUrl = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.trim());
      final description = _descController.text.trim();

      setState(() {
        _isUploadingFile = true;
      });

      String? uploadUrl = _receiptUrl;

      if (_pickedFile != null) {
        Uint8List? fileBytes = _pickedFile!.bytes;
        if (fileBytes == null && !kIsWeb && _pickedFile!.path != null) {
          fileBytes = io.File(_pickedFile!.path!).readAsBytesSync();
        }

        if (fileBytes != null) {
          uploadUrl = await ref.read(transactionProvider.notifier).uploadReceiptFile(
                _pickedFile!.name,
                fileBytes,
              );

          if (uploadUrl == null) {
            setState(() {
              _isUploadingFile = false;
            });
            return; // Hentikan submit jika upload gagal
          }
        }
      }

      bool success;
      if (widget.transaction == null) {
        // Mode Tambah
        success = await ref.read(transactionProvider.notifier).addTransaction(
              projectId: _selectedProjectId,
              accountId: _selectedAccountId,
              type: _type,
              amount: amount,
              category: _category,
              description: description.isEmpty ? null : description,
              transactionDate: _transactionDate,
              receiptUrl: uploadUrl,
            );
      } else {
        // Mode Edit
        success = await ref.read(transactionProvider.notifier).updateTransaction(
              id: widget.transaction!.id,
              projectId: _selectedProjectId,
              accountId: _selectedAccountId,
              type: _type,
              amount: amount,
              category: _category,
              description: description.isEmpty ? null : description,
              transactionDate: _transactionDate,
              receiptUrl: uploadUrl,
            );
      }

      if (!mounted) return;

      setState(() {
        _isUploadingFile = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction == null ? 'Transaksi berhasil dicatat!' : 'Transaksi berhasil diperbarui!'),
            backgroundColor: const Color(0xFF0D5C46),
          ),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(transactionProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal memproses data transaksi.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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

    return AlertDialog(
      title: Text(
        isEdit ? 'Ubah Transaksi' : 'Catat Transaksi',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Button Tipe Transaksi
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'income',
                    label: Text('Uang Masuk'),
                    icon: Icon(Icons.arrow_downward, size: 16),
                  ),
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Uang Keluar'),
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
                  labelText: 'Jumlah Uang (Rp)',
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
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Color(0xFF0D5C46)),
                    ))
                  : DropdownButtonFormField<String>(
                      value: _selectedAccountId,
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
                value: _selectedProjectId,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Tanggal: ${Formatter.formatTanggal(_transactionDate)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
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
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A2A25)),
              ),
              const SizedBox(height: 8),
              if (_pickedFile != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D5C46).withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0D5C46).withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF0D5C46)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedFile!.name,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withAlpha(45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bukti Transaksi Terunggah',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _pickReceipt,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Pilih Berkas Bukti (Gambar / PDF)'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _handleSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEdit ? 'Simpan' : 'Catat'),
        ),
      ],
    );
  }
}
