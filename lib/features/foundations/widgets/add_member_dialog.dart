import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/foundation_provider.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  const AddMemberDialog({super.key});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'viewer';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final role = _selectedRole;

      final success = await ref.read(foundationProvider.notifier).addMember(email, role);
      
      if (success && mounted) {
        // Refresh daftar anggota
        ref.invalidate(foundationMembersProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anggota "$email" berhasil ditambahkan sebagai $role!'),
            backgroundColor: const Color(0xFF0D5C46),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final error = ref.read(foundationProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal menambahkan anggota. Pastikan email sudah terdaftar.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foundationState = ref.watch(foundationProvider);

    return AlertDialog(
      title: Text(
        'Tambah Anggota Yayasan',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Undang anggota dengan memasukkan email mereka. Pastikan mereka telah mendaftar akun di aplikasi ini.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6B7F79),
                ),
              ),
              const SizedBox(height: 16),
              
              // Input Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Anggota',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'budi@domain.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Peran (Role)
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Peran Anggota',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin (Semua Akses)'),
                  ),
                  DropdownMenuItem(
                    value: 'bendahara',
                    child: Text('Bendahara (Urus Transaksi)'),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text('Viewer (Hanya Melihat)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: foundationState.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: foundationState.isLoading ? null : _handleSubmit,
          child: foundationState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Tambah'),
        ),
      ],
    );
  }
}
