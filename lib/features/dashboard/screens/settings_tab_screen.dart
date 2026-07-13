import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../foundations/models/foundation_model.dart';

class SettingsTabScreen extends ConsumerStatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  ConsumerState<SettingsTabScreen> createState() => _SettingsTabScreenState();
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

class _SettingsBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsBlock({required this.title, required this.child});

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

class _SettingsTabScreenState extends ConsumerState<SettingsTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _personalFormKey = GlobalKey<FormState>();
  final _foundationFormKey = GlobalKey<FormState>();

  // Personal inputs
  late TextEditingController _personalNameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String? _personalUploadedAvatarUrl;

  // Foundation inputs
  late TextEditingController _foundationNameController;
  late TextEditingController _foundationDescController;
  String? _foundationUploadedLogoUrl;
  String? _foundationUploadedBannerUrl;

  bool _isUploadingAvatar = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;
  bool _isSavingPersonal = false;
  bool _isSavingFoundation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial personal values
    final profile = ref.read(authProvider).profile;
    _personalNameController = TextEditingController(text: profile?.name ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _personalUploadedAvatarUrl = profile?.avatarUrl;

    // Initial foundation values
    final activeF = ref.read(foundationProvider).activeFoundation;
    _foundationNameController = TextEditingController(text: activeF?.name ?? '');
    _foundationDescController = TextEditingController(text: activeF?.description ?? '');
    _foundationUploadedLogoUrl = activeF?.logoUrl;
    _foundationUploadedBannerUrl = activeF?.bannerUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _personalNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _foundationNameController.dispose();
    _foundationDescController.dispose();
    super.dispose();
  }

  // Personal Upload Avatar
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
          _personalUploadedAvatarUrl = url;
          _isUploadingAvatar = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diunggah!'),
              backgroundColor: Color(0xFF0D5C46),
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

  // Save Personal Profile Settings
  Future<void> _savePersonalProfile() async {
    if (!_personalFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingPersonal = true;
    });

    final authNotifier = ref.read(authProvider.notifier);
    final profileSuccess = await authNotifier.updatePersonalProfile(
      name: _personalNameController.text.trim(),
      avatarUrl: _personalUploadedAvatarUrl,
    );

    bool passwordSuccess = true;
    if (_passwordController.text.isNotEmpty) {
      passwordSuccess = await authNotifier.updatePassword(_passwordController.text);
      if (passwordSuccess) {
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    }

    setState(() {
      _isSavingPersonal = false;
    });

    if (mounted) {
      final success = profileSuccess && passwordSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil pribadi berhasil diperbarui!' : 'Gagal memperbarui profil pribadi.'),
          backgroundColor: success ? const Color(0xFF0D5C46) : Colors.red,
        ),
      );
    }
  }

  // Foundation Upload Files
  Future<void> _uploadFoundationFile(bool isLogo) async {
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
            _foundationUploadedLogoUrl = url;
            _isUploadingLogo = false;
          } else {
            _foundationUploadedBannerUrl = url;
            _isUploadingBanner = false;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isLogo ? 'Logo yayasan berhasil diunggah!' : 'Banner yayasan berhasil diunggah!'),
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

  // Save Foundation Settings
  Future<void> _saveFoundationProfile() async {
    if (!_foundationFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingFoundation = true;
    });

    final success = await ref.read(foundationProvider.notifier).updateFoundationProfile(
          name: _foundationNameController.text.trim(),
          description: _foundationDescController.text.trim(),
          logoUrl: _foundationUploadedLogoUrl,
          bannerUrl: _foundationUploadedBannerUrl,
        );

    setState(() {
      _isSavingFoundation = false;
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
    final role = activeFoundation?.currentUserRole ?? 'viewer';
    final isAdmin = role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Text(
          'Pengaturan Akun & Yayasan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profil Saya'),
            Tab(icon: Icon(Icons.business), text: 'Profil Yayasan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalTab(),
          _buildFoundationTab(activeFoundation, isAdmin),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    final session = ref.watch(authProvider).session;
    final initials = _personalNameController.text.isNotEmpty ? _personalNameController.text.substring(0, 1).toUpperCase() : '?';

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFEBEBEB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Foto Profil',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
                            ),
                            const SizedBox(height: 24),
                            Stack(
                              children: [
                                _personalUploadedAvatarUrl != null
                                    ? CircleAvatar(
                                        radius: 60,
                                        backgroundImage: NetworkImage(_personalUploadedAvatarUrl!),
                                      )
                                    : CircleAvatar(
                                        radius: 60,
                                        backgroundColor: const Color(0xFF0D5C46),
                                        child: Text(
                                          initials,
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF0D5C46),
                                    child: _isUploadingAvatar
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : IconButton(
                                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                            onPressed: _uploadAvatar,
                                            tooltip: 'Unggah Foto Profil',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Foto ini akan tampil di bagian anggota yayasan dan donasi proyek publik (non-anonim).',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(color: const Color(0xFF6B7F79), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFEBEBEB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildPersonalTextFormFields(session?.user.email),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              // Mobile Layout
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFEBEBEB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _personalUploadedAvatarUrl != null
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(_personalUploadedAvatarUrl!),
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF0D5C46),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF0D5C46),
                              child: _isUploadingAvatar
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : IconButton(
                                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                      onPressed: _uploadAvatar,
                                      tooltip: 'Unggah Foto Profil',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFEBEBEB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildPersonalTextFormFields(session?.user.email),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C46),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSavingPersonal ? null : _savePersonalProfile,
                icon: _isSavingPersonal
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text('Simpan Profil Pribadi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTextFormFields(String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Profil Pribadi',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
        ),
        const SizedBox(height: 20),

        // Nama
        _SettingsBlock(
          title: 'Nama Pengguna',
          child: TextFormField(
            controller: _personalNameController,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              hintText: 'Nama lengkap Anda...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
              return null;
            },
          ),
        ),

        const SizedBox(height: 20),

        // Email (Read only)
        _SettingsBlock(
          title: 'Alamat Email (Akun)',
          child: TextFormField(
            initialValue: email ?? 'Tidak diketahui',
            enabled: false,
            style: GoogleFonts.outfit(color: Colors.grey),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.email_outlined),
              fillColor: const Color(0xFFF3F4F6),
              filled: true,
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        Text(
          'Ubah Kata Sandi (Kosongkan jika tidak ingin diubah)',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0D5C46)),
        ),
        const SizedBox(height: 16),

        // Password Baru
        _SettingsBlock(
          title: 'Kata Sandi Baru',
          child: TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              hintText: 'Masukkan minimal 6 karakter...',
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
        ),

        const SizedBox(height: 20),

        // Konfirmasi Password
        _SettingsBlock(
          title: 'Konfirmasi Kata Sandi',
          child: TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: GoogleFonts.outfit(),
            decoration: InputDecoration(
              hintText: 'Ulangi kata sandi baru...',
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
        ),
      ],
    );
  }

  Widget _buildFoundationTab(FoundationModel? active, bool isEditable) {
    if (active == null) {
      return const Center(child: Text('Tidak ada yayasan aktif.'));
    }

    final initials = _foundationNameController.text.isNotEmpty ? _foundationNameController.text.substring(0, 1).toUpperCase() : '?';
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _foundationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditable)
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
                  Expanded(flex: 3, child: _buildFoundationVisualSettings(isEditable, initials)),
                  const SizedBox(width: 32),
                  Expanded(flex: 4, child: _buildFoundationTextSettings(isEditable)),
                ],
              )
            else ...[
              _buildFoundationVisualSettings(isEditable, initials),
              const SizedBox(height: 24),
              _buildFoundationTextSettings(isEditable),
            ],

            if (isEditable) ...[
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
                  onPressed: _isSavingFoundation ? null : _saveFoundationProfile,
                  icon: _isSavingFoundation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text('Simpan Profil Yayasan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoundationVisualSettings(bool isEditable, String initials) {
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

            // Banner
            _SettingsBlock(
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
                    child: _foundationUploadedBannerUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_foundationUploadedBannerUrl!, fit: BoxFit.cover),
                          )
                        : const _VisualPlaceholder(text: 'Belum ada banner terpasang', icon: Icons.image_outlined),
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
                                onPressed: () => _uploadFoundationFile(false),
                              ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logo
            _SettingsBlock(
              title: 'Logo Yayasan',
              child: Row(
                children: [
                  Stack(
                    children: [
                      _foundationUploadedLogoUrl != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_foundationUploadedLogoUrl!),
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
                                    onPressed: () => _uploadFoundationFile(true),
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
                          'Gunakan gambar kotak 1:1, max 2MB.',
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

  Widget _buildFoundationTextSettings(bool isEditable) {
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

            _SettingsBlock(
              title: 'Nama Resmi Yayasan',
              child: TextFormField(
                controller: _foundationNameController,
                enabled: isEditable,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: 'Nama yayasan...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama yayasan tidak boleh kosong';
                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),

            _SettingsBlock(
              title: 'Profil / Deskripsi Lengkap',
              child: TextFormField(
                controller: _foundationDescController,
                enabled: isEditable,
                style: GoogleFonts.outfit(),
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Sejarah, Visi Misi, Rekening Donasi...',
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
