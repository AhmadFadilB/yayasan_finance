import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/foundation_provider.dart';

class FoundationProfileEditScreen extends ConsumerStatefulWidget {
  const FoundationProfileEditScreen({super.key});

  @override
  ConsumerState<FoundationProfileEditScreen> createState() => _FoundationProfileEditScreenState();
}

class _VisualPlaceholder extends StatelessWidget {
  final String text;
  final IconData icon;

  const _VisualPlaceholder({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF0D5C46)),
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.outfit(color: const Color(0xFF6B7F79), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A2A25)),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FoundationProfileEditScreenState extends ConsumerState<FoundationProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  String? _uploadedLogoUrl;
  String? _uploadedBannerUrl;

  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final active = ref.read(foundationProvider).activeFoundation;
    _nameController = TextEditingController(text: active?.name ?? '');
    _descController = TextEditingController(text: active?.description ?? '');
    _uploadedLogoUrl = active?.logoUrl;
    _uploadedBannerUrl = active?.bannerUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _uploadAsset(bool isLogo) async {
    final active = ref.read(foundationProvider).activeFoundation;
    if (active == null) return;

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
          if (isLogo) {
            _isUploadingLogo = true;
          } else {
            _isUploadingBanner = true;
          }
        });

        final service = ref.read(foundationServiceProvider);
        final url = await service.uploadFoundationFile(active.id, file.name, file.bytes!);

        setState(() {
          if (isLogo) {
            _uploadedLogoUrl = url;
            _isUploadingLogo = false;
          } else {
            _uploadedBannerUrl = url;
            _isUploadingBanner = false;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogo ? 'Logo berhasil diunggah!' : 'Banner berhasil diunggah!'),
              backgroundColor: const Color(0xFF0D5C46),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        if (isLogo) {
          _isUploadingLogo = false;
        } else {
          _isUploadingBanner = false;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah gambar: ${e.toString()}'),
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

    final success = await ref.read(foundationProvider.notifier).updateFoundationProfile(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          logoUrl: _uploadedLogoUrl,
          bannerUrl: _uploadedBannerUrl,
        );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil yayasan berhasil disimpan!' : 'Gagal memperbarui profil.'),
          backgroundColor: success ? const Color(0xFF0D5C46) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    if (activeFoundation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = activeFoundation.currentUserRole ?? 'viewer';
    final isAdmin = role == 'admin';

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Profil Yayasan',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Sesuaikan identitas, logo, dan banner publik yayasan Anda',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAdmin)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hanya Administrator yang memiliki akses untuk mengubah informasi dan profil yayasan.',
                          style: GoogleFonts.outfit(color: Colors.orange.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildVisualSettings(isAdmin)),
                    const SizedBox(width: 32),
                    Expanded(flex: 4, child: _buildTextSettings(isAdmin)),
                  ],
                )
              else ...[
                _buildVisualSettings(isAdmin),
                const SizedBox(height: 24),
                _buildTextSettings(isAdmin),
              ],
              
              if (isAdmin) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D5C46),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      'Simpan Profil Yayasan',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualSettings(bool isEditable) {
    final initials = _nameController.text.isNotEmpty ? _nameController.text.substring(0, 1).toUpperCase() : '?';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Profil Yayasan',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
            ),
            const SizedBox(height: 20),

            _EditBlock(
              title: 'Foto Banner (Publik)',
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _uploadedBannerUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _uploadedBannerUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const _VisualPlaceholder(
                            text: 'Belum ada banner terpasang',
                            icon: Icons.image_outlined,
                          ),
                  ),
                  if (isEditable)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withAlpha(153),
                        child: _isUploadingBanner
                            ? const CircularProgressIndicator(color: Colors.white)
                            : IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () => _uploadAsset(false),
                              ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _EditBlock(
              title: 'Logo / Foto Profil Yayasan',
              child: Row(
                children: [
                  Stack(
                    children: [
                      _uploadedLogoUrl != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_uploadedLogoUrl!),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF0D5C46),
                              child: Text(
                                initials,
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                            ),
                      if (isEditable)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF0D5C46),
                            child: _isUploadingLogo
                                ? const CircularProgressIndicator(color: Colors.white)
                                : IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 14),
                                    onPressed: () => _uploadAsset(true),
                                  ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekomendasi Logo',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Pilih gambar berformat JPG/PNG aspek rasio 1:1, max 2MB.',
                          style: GoogleFonts.outfit(color: const Color(0xFF6B7F79), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSettings(bool isEditable) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Yayasan',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
            ),
            const SizedBox(height: 20),

            _EditBlock(
              title: 'Nama Resmi Yayasan',
              child: TextFormField(
                controller: _nameController,
                enabled: isEditable,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: 'Nama resmi yayasan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama yayasan tidak boleh kosong.';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            _EditBlock(
              title: 'Profil / Deskripsi Lengkap',
              child: TextFormField(
                controller: _descController,
                enabled: isEditable,
                style: GoogleFonts.outfit(),
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Deskripsi lengkap, sejarah, visi misi, rekening donasi...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
