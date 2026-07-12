import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../models/project_model.dart';
import '../providers/project_provider.dart';

class ProjectFormDialog extends ConsumerStatefulWidget {
  final ProjectModel? project; // Jika ada nilainya berarti mode edit, jika null berarti mode tambah

  const ProjectFormDialog({super.key, this.project});

  @override
  ConsumerState<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _targetAmountController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _targetAmountController = TextEditingController(
      text: widget.project?.targetAmount != null && widget.project!.targetAmount > 0
          ? Formatter.formatRupiah(widget.project!.targetAmount)
              .replaceAll('Rp', '')
              .replaceAll(',00', '')
              .trim()
          : '',
    );
    _startDate = widget.project?.startDate;
    _endDate = widget.project?.endDate;
    _status = widget.project?.status ?? 'planned';
    _isPublic = widget.project?.isPublic ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final status = _status;

      final targetAmount = _targetAmountController.text.trim().isEmpty
          ? 0.0
          : double.parse(_targetAmountController.text.replaceAll('.', ''));

      bool success;
      if (widget.project == null) {
        // Mode Tambah
        success = await ref.read(projectProvider.notifier).addProject(
              name: name,
              description: desc.isEmpty ? null : desc,
              startDate: _startDate,
              endDate: _endDate,
              status: status,
              isPublic: _isPublic,
              targetAmount: targetAmount,
            );
      } else {
        // Mode Edit
        success = await ref.read(projectProvider.notifier).updateProject(
              id: widget.project!.id,
              name: name,
              description: desc.isEmpty ? null : desc,
              startDate: _startDate,
              endDate: _endDate,
              status: status,
              isPublic: _isPublic,
              targetAmount: targetAmount,
            );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.project == null ? 'Proyek baru berhasil dibuat!' : 'Proyek berhasil diperbarui!'),
            backgroundColor: const Color(0xFF0D5C46),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = ref.read(projectProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal memproses data proyek.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectProvider);
    final isEdit = widget.project != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Ubah Proyek' : 'Tambah Proyek',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Nama Proyek
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Proyek',
                  hintText: 'Renovasi Panti Asuhan',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama proyek tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Deskripsi
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Proyek',
                  hintText: 'Renovasi gedung utama yayasan...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date Pickers
              Row(
                children: [
                  // Tanggal Mulai
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _pickDate(true),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_month, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            _startDate == null ? 'Mulai (Pilih)' : Formatter.formatTanggalPendek(_startDate!),
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tanggal Selesai
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _pickDate(false),
                      child: Column(
                        children: [
                          const Icon(Icons.event, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            _endDate == null ? 'Selesai (Pilih)' : Formatter.formatTanggalPendek(_endDate!),
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status Proyek',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Direncanakan (Planned)')),
                  DropdownMenuItem(value: 'active', child: Text('Berjalan (Active)')),
                  DropdownMenuItem(value: 'completed', child: Text('Selesai (Completed)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Switch Publik
              SwitchListTile(
                value: _isPublic,
                title: const Text('Jadikan Proyek Publik'),
                subtitle: const Text('Donatur publik dapat melihat proyek ini tanpa login'),
                activeColor: const Color(0xFF0D5C46),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isPublic = val;
                  });
                },
              ),

              // Target Amount (jika publik)
              if (_isPublic) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Dana Crowdfunding (Rp)',
                    hintText: '5.000.000',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RupiahInputFormatter(),
                  ],
                  validator: (value) {
                    if (_isPublic && (value == null || value.trim().isEmpty)) {
                      return 'Target dana wajib diisi jika proyek diset publik';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : _handleSubmit,
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int numValue = int.parse(newValue.text.replaceAll('.', ''));
    final String formatted = Formatter.formatRupiah(numValue.toDouble())
        .replaceAll('Rp', '')
        .replaceAll(',00', '')
        .trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
