import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/formatter.dart';
import '../services/project_service.dart';

class PublicDonationFormDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onSuccess;

  const PublicDonationFormDialog({
    super.key,
    required this.projectId,
    required this.onSuccess,
  });

  @override
  State<PublicDonationFormDialog> createState() => _PublicDonationFormDialogState();
}

class _PublicDonationFormDialogState extends State<PublicDonationFormDialog> {
  final ProjectService _service = ProjectService();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isAnonymous = false;
  bool _isLoading = false;
  
  // Step 2 Data
  Map<String, dynamic>? _donationResult;

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final double baseAmount = double.parse(_amountController.text.replaceAll('.', ''));
      final result = await _service.submitPublicDonation(
        projectId: widget.projectId,
        donorName: _isAnonymous ? 'Hamba Allah' : _nameController.text.trim(),
        isAnonymous: _isAnonymous,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        baseAmount: baseAmount,
      );

      setState(() {
        _donationResult = result;
        _isLoading = false;
      });
      
      widget.onSuccess();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses donasi: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStep2 = _donationResult != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isStep2 ? _buildStep2() : _buildStep1(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kirim Donasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5A47)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Nominal Donasi
          const Text(
            'Nominal Donasi (Rp)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F5A47)),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              hintText: '50.000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _RupiahInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nominal wajib diisi';
              }
              final amount = double.tryParse(value.replaceAll('.', ''));
              if (amount == null || amount < 10000) {
                return 'Minimal donasi adalah Rp 10.000';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Nama Donatur
          const Text(
            'Nama Donatur',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            enabled: !_isAnonymous,
            decoration: InputDecoration(
              hintText: _isAnonymous ? 'Hamba Allah' : 'Masukkan nama lengkap Anda',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) {
              if (!_isAnonymous && (value == null || value.trim().isEmpty)) {
                return 'Nama wajib diisi jika tidak anonim';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Checkbox Anonim
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                activeColor: const Color(0xFF0F5A47),
                onChanged: (val) {
                  setState(() {
                    _isAnonymous = val ?? false;
                    if (_isAnonymous) {
                      _nameController.clear();
                    }
                  });
                },
              ),
              const Text('Donasikan secara Anonim (Hamba Allah)', style: TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),

          // Email
          const Text(
            'Alamat Email (Opsional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'nama@email.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Telepon
          const Text(
            'No. WhatsApp (Opsional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '08123456xxx',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A47),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Lanjutkan Donasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_donationResult == null) return const SizedBox();

    final uniqueCode = _donationResult!['unique_code'] as int;
    final totalAmount = _donationResult!['total_amount'] as double;
    final foundationName = _donationResult!['foundation_name'] as String;
    final bankDetails = _donationResult!['foundation_description'] ?? 'Detail bank belum disetel oleh yayasan. Silakan hubungi yayasan terkait.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(Icons.volunteer_activism, size: 64, color: Color(0xFF0F5A47)),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Instruksi Transfer Donasi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          '1. Salin Nominal Donasi Tepat:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatter.formatRupiah(totalAmount),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F5A47)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Color(0xFF0F5A47)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: totalAmount.toStringAsFixed(0)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nominal transfer berhasil disalin!')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PENTING: Kode unik 3 digit terakhir ($uniqueCode) ditambahkan otomatis untuk membantu bendahara memverifikasi donasi Anda.',
          style: const TextStyle(fontSize: 11, color: Colors.orange, height: 1.4),
        ),
        const SizedBox(height: 16),

        const Text(
          '2. Kirim Transfer ke Rekening Yayasan:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                foundationName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                bankDetails,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Done button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5A47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Saya Sudah Transfer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
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
