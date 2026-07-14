import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/foundation_provider.dart';
import '../../auth/widgets/user_profile_dialog.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Buat Yayasan Baru',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                _descController.clear();
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final name = _nameController.text.trim();
                  final desc = _descController.text.trim();
                  
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  // Tutup dialog terlebih dahulu untuk menghindari crash navigasi/rebuild
                  navigator.pop();
                  _nameController.clear();
                  _descController.clear();

                  final success = await ref.read(foundationProvider.notifier).createFoundation(
                        name,
                        desc.isEmpty ? null : desc,
                      );
                  
                  if (success && mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Yayasan "$name" berhasil dibuat!'),
                        backgroundColor: const Color(0xFF0D5C46),
                      ),
                    );
                  }
                }
              },
              child: const Text('Buat'),
            ),
          ],
        );
      },
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
                backgroundColor: const Color(0xFF0D5C46),
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

              return PopupMenuButton<String>(
                tooltip: 'Menu Akun',
                offset: const Offset(0, 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: avatarWidget,
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      showDialog(
                        context: context,
                        builder: (_) => const UserProfileDialog(),
                      );
                      break;
                    case 'logout':
                      ref.read(authProvider.notifier).logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      currentProfile?.name ?? 'Akun Saya',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: Color(0xFF0D5C46)),
                        const SizedBox(width: 8),
                        Text('Edit Profil', style: GoogleFonts.outfit()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Logout', style: GoogleFonts.outfit(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
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
                color: const Color(0xFF0D5C46).withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF0D5C46), width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF0D5C46),
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
                    borderRadius: BorderRadius.circular(8),
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
                                ElevatedButton.icon(
                                  onPressed: _showCreateFoundationDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Buat Yayasan Pertama'),
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
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
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
                                              color: Color(0xFF0D5C46),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                f.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1A2A25),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D5C46).withAlpha(26),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                (f.currentUserRole ?? 'viewer').toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0D5C46),
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
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: const Color(0xFF6B7F79),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              
              // Tombol Tambah Yayasan di bagian bawah (jika sudah ada yayasan)
              if (foundationState.foundations.isNotEmpty && !foundationState.isLoading)
                ElevatedButton.icon(
                  onPressed: _showCreateFoundationDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Yayasan Baru'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
