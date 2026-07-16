import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/foundation_provider.dart';
import '../../../core/components/profile_menu_anchor.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';

class FoundationSelectScreen extends ConsumerStatefulWidget {
  const FoundationSelectScreen({super.key});

  @override
  ConsumerState<FoundationSelectScreen> createState() => _FoundationSelectScreenState();
}

class _FoundationSelectScreenState extends ConsumerState<FoundationSelectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCreateFoundationDialog() {
    AppModal.show<void>(
      context: context,
      title: const Text('Buat Yayasan Baru'),
      subtitle: 'Mulai yayasan baru untuk mengelola keuangan program sosial Anda',
      content: Consumer(
        builder: (context, ref, child) {
          final foundationState = ref.watch(foundationProvider);
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Yayasan',
                    hintText: 'Yayasan Al-Manar',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama yayasan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsi singkat mengenai yayasan',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Batal',
                      style: AppButtonStyle.outline,
                      onPressed: () {
                        _nameController.clear();
                        _descController.clear();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Buat',
                      style: AppButtonStyle.primary,
                      isLoading: foundationState.isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final name = _nameController.text.trim();
                          final desc = _descController.text.trim();
                          
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          
                          final success = await ref.read(foundationProvider.notifier).createFoundation(
                                name,
                                desc.isEmpty ? null : desc,
                              );
                          
                          if (success && mounted) {
                            navigator.pop();
                            _nameController.clear();
                            _descController.clear();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Yayasan "$name" berhasil dibuat!'),
                                backgroundColor: AppTheme.colorSuccess,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foundationState = ref.watch(foundationProvider);
    final profile = ref.watch(authProvider).profile;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Yayasan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Jelajah Proyek Publik',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () {
              context.push('/');
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final currentProfile = ref.watch(authProvider).profile;
              final avatarUrl = currentProfile?.avatarUrl;
              final initials = currentProfile?.name.isNotEmpty == true 
                  ? currentProfile!.name.substring(0, 1).toUpperCase() 
                  : '?';

              final avatarWidget = CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );

              return ProfileMenuAnchor(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: avatarWidget,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Profil
              Card(
                elevation: 0,
                color: AppTheme.primaryColor.withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                  side: const BorderSide(color: AppColors.divider, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: profile?.avatarUrl != null 
                            ? NetworkImage(profile!.avatarUrl!) 
                            : null,
                        child: profile?.avatarUrl == null
                            ? Text(
                                (profile?.name ?? 'U').substring(0, 1).toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assalamualaikum,',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF6B7F79),
                              ),
                            ),
                            Text(
                              profile?.name ?? 'Memuat...',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Sub-judul / Ajakan
              Text(
                'Pilih Yayasan Aktif Anda:',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2A25),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (foundationState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Text(
                    foundationState.errorMessage!,
                    style: const TextStyle(color: Color(0xFFC62828)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Konten List Yayasan
              Expanded(
                child: foundationState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : foundationState.foundations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.account_balance_outlined,
                                  size: 72,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Anda belum bergabung dengan yayasan manapun.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                 AppButton(
                                  onPressed: _showCreateFoundationDialog,
                                  icon: Icons.add,
                                  text: 'Buat Yayasan Pertama',
                                  style: AppButtonStyle.primary,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 2 : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: foundationState.foundations.length,
                            itemBuilder: (context, index) {
                              final f = foundationState.foundations[index];
                              return AppCard(
                                onTap: () {
                                  ref.read(foundationProvider.notifier).selectFoundation(f);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              f.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withAlpha(26),
                                              borderRadius: AppRadius.radiusPill,
                                            ),
                                            child: Text(
                                              (f.currentUserRole ?? 'viewer').toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        f.description ?? 'Tidak ada deskripsi',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              
              // Tombol Tambah Yayasan di bagian bawah (jika sudah ada yayasan)
              if (foundationState.foundations.isNotEmpty && !foundationState.isLoading)
                AppButton(
                  onPressed: _showCreateFoundationDialog,
                  icon: Icons.add,
                  text: 'Buat Yayasan Baru',
                  style: AppButtonStyle.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
