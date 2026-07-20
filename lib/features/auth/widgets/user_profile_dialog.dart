import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class UserProfileDialog extends ConsumerStatefulWidget {
  const UserProfileDialog({super.key});

  @override
  ConsumerState<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends ConsumerState<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _uploadedAvatarUrl;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _uploadedAvatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatar() async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) return;

        setState(() {
          _isUploadingAvatar = true;
        });

        final service = ref.read(authServiceProvider);
        final url = await service.uploadAvatar(profile.id, file.name, file.bytes!);

        setState(() {
          _uploadedAvatarUrl = url;
          _isUploadingAvatar = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto profil berhasil diunggah!'),
              backgroundColor: AppTheme.colorSuccess,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final profileSuccess = await authNotifier.updatePersonalProfile(
      name: _nameController.text.trim(),
      avatarUrl: _uploadedAvatarUrl,
    );

    bool passwordSuccess = true;
    if (_passwordController.text.isNotEmpty) {
      passwordSuccess = await authNotifier.updatePassword(_passwordController.text);
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      final success = profileSuccess && passwordSuccess;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil pribadi berhasil disimpan!'),
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
        Navigator.pop(context); // Close the dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memperbarui profil.'),
            backgroundColor: AppTheme.colorError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final initials = _nameController.text.isNotEmpty ? _nameController.text.substring(0, 1).toUpperCase() : '?';

    return AlertDialog(
      title: Text(
        'Edit Profil Akun Saya',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Upload Section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _uploadedAvatarUrl != null
                        ? CircleAvatar(
                            radius: 48,
                            backgroundImage: NetworkImage(_uploadedAvatarUrl!),
                          )
                        : CircleAvatar(
                            radius: 48,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              initials,
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor,
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                onPressed: _uploadAvatar,
                                tooltip: 'Unggah Foto',
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email (Read-only)
                TextFormField(
                  initialValue: profile?.id != null ? ref.watch(authProvider).session?.user.email : '',
                  enabled: false,
                  style: GoogleFonts.inter(color: Colors.grey),
                  decoration: InputDecoration(
                    labelText: 'Email Akun',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email_outlined),
                    fillColor: const Color(0xFFF3F4F6),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ubah Kata Sandi (Kosongkan jika tidak diubah)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),

                // New Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (_passwordController.text.isNotEmpty && val != _passwordController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
