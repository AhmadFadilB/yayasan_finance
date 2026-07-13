import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../dashboard/screens/main_navigation_screen.dart';
import '../../foundations/screens/foundation_select_screen.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../auth/widgets/user_profile_dialog.dart';
import '../services/project_service.dart';

class PublicProjectFeedScreen extends ConsumerStatefulWidget {
  final bool showNavbar;
  const PublicProjectFeedScreen({super.key, this.showNavbar = true});

  @override
  ConsumerState<PublicProjectFeedScreen> createState() => _PublicProjectFeedScreenState();
}

class _PublicProjectFeedScreenState extends ConsumerState<PublicProjectFeedScreen> {
  final ProjectService _projectService = ProjectService();
  
  List<Map<String, dynamic>> _allProjects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _projectService.getAllPublicProjects();
      setState(() {
        _allProjects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat daftar proyek publik. Silakan periksa koneksi internet Anda.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = _allProjects;
      } else {
        _filteredProjects = _allProjects.where((proj) {
          final name = (proj['name'] as String).toLowerCase();
          final desc = (proj['description'] as String? ?? '').toLowerCase();
          final foundation = (proj['foundations'] != null && proj['foundations']['name'] != null)
              ? (proj['foundations']['name'] as String).toLowerCase()
              : '';
          return name.contains(query) || desc.contains(query) || foundation.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Column(
        children: [
          // Elegant Top Header / Navigation bar
          if (widget.showNavbar) ...[
            _buildNavbar(authState),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],

          // Hero Search Section
          _buildHeroSection(isDesktop),

          // Main Feed Grid/List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0F5A47)),
                        SizedBox(height: 16),
                        Text('Memuat proyek publik...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorPlaceholder()
                    : _buildFeedContent(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(AuthState authState) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F0EC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.volunteer_activism, color: Color(0xFF0F5A47), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Yayasan Crowdfund',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F5A47),
                ),
              ),
            ],
          ),
          
          // Action Account Avatar Menu / Login Trigger
          Consumer(
            builder: (context, ref, child) {
              final auth = ref.watch(authProvider);
              if (!auth.isAuthenticated) {
                // Not logged in: show grey profile avatar redirecting to login
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE5E7EB),
                    child: Icon(Icons.person, color: Color(0xFF9CA3AF), size: 20),
                  ),
                );
              }

              // Logged in: show account settings dropdown
              final profile = auth.profile;
              final avatarUrl = profile?.avatarUrl;
              final initials = profile?.name.isNotEmpty == true 
                  ? profile!.name.substring(0, 1).toUpperCase() 
                  : '?';

              final avatarWidget = CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0F5A47),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              );

              final active = ref.watch(foundationProvider).activeFoundation;

              return PopupMenuButton<String>(
                tooltip: 'Menu Akun',
                offset: const Offset(0, 48),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: avatarWidget,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      showDialog(
                        context: context,
                        builder: (_) => const UserProfileDialog(),
                      );
                      break;
                    case 'dashboard':
                      if (active == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const FoundationSelectScreen()),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                        );
                      }
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
                      profile?.name ?? 'Akun Saya',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: Color(0xFF0F5A47)),
                        const SizedBox(width: 8),
                        Text('Edit Profil', style: GoogleFonts.outfit()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'dashboard',
                    child: Row(
                      children: [
                        Icon(active == null ? Icons.account_balance : Icons.dashboard, size: 20, color: const Color(0xFF0F5A47)),
                        const SizedBox(width: 8),
                        Text(active == null ? 'Pilih Yayasan' : 'Ke Dasbor', style: GoogleFonts.outfit()),
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
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F5A47), Color(0xFF1D7860)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isDesktop ? 48 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Dukung Proyek Sosial Secara Transparan',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Donasi Anda tersalurkan langsung ke rekening yayasan terkait tanpa potongan perantara.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 14 : 12,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 24),
              
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama proyek, deskripsi, atau yayasan...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedContent(bool isDesktop) {
    if (_filteredProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Tidak menemukan proyek publik yang cocok.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 380,
          ),
          itemCount: _filteredProjects.length,
          itemBuilder: (context, index) {
            final proj = _filteredProjects[index];
            return _buildProjectCard(proj);
          },
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> proj) {
    final String name = proj['name'] as String;
    final String? desc = proj['description'] as String?;
    final String foundationName = (proj['foundations'] != null && proj['foundations']['name'] != null)
        ? proj['foundations']['name'] as String
        : 'Yayasan';
    final double target = (proj['target_amount'] as num?)?.toDouble() ?? 0.0;
    final double raised = (proj['total_income'] as num?)?.toDouble() ?? 0.0;
    final double progress = target > 0 ? (raised / target).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).round();
    final String id = proj['id'] as String;
    final String foundationId = proj['foundation_id'] as String;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/public/project?id=$id',
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section (Card Header style)
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE6F0EC), Color(0xFFD4E8E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/public/foundation?id=$foundationId',
                      );
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F5A47).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          foundationName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F5A47),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Middle section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc ?? 'Tidak ada deskripsi.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom section stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 6,
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F5A47), Color(0xFF4CAF50)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatter.formatRupiah(raised),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0F5A47),
                            ),
                          ),
                          Text(
                            'terkumpul',
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            target > 0 ? Formatter.formatRupiah(target) : 'Tak Terbatas',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'target',
                            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
