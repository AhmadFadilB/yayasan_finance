import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/app_logo.dart';
import '../../../../core/components/profile_menu_anchor.dart';
import '../widgets/project_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadProjects,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Elegant Top Header / Navigation bar
            if (widget.showNavbar)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildNavbar(authState),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),

            // Hero Search Section
            SliverToBoxAdapter(
              child: _buildHeroSection(isDesktop),
            ),

            // Main Feed Grid/List
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0F5A47)),
                      SizedBox(height: 16),
                      Text('Memuat proyek publik...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorPlaceholder(),
              )
            else
              _buildSliverFeedContent(isDesktop),
          ],
        ),
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
          const AppLogo(showText: true, fontSize: 18),
          
          // Action Account Avatar Menu / Login Trigger
          Consumer(
            builder: (context, ref, child) {
              final auth = ref.watch(authProvider);
              final activeFoundation = ref.watch(foundationProvider).activeFoundation;
              
              final avatarWidget = auth.isAuthenticated
                  ? CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      backgroundImage: auth.profile?.avatarUrl != null 
                          ? NetworkImage(auth.profile!.avatarUrl!) 
                          : null,
                      child: auth.profile?.avatarUrl == null
                          ? Text(
                              auth.profile?.name.isNotEmpty == true 
                                  ? auth.profile!.name.substring(0, 1).toUpperCase() 
                                  : '?',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    )
                  : const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE5E7EB),
                      child: Icon(Icons.person, color: Color(0xFF9CA3AF), size: 20),
                    );

              return Row(
                children: [
                  if (auth.isAuthenticated && activeFoundation != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.dashboard_outlined, size: 16),
                        label: Text(
                          'Kembali ke ${activeFoundation.name}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ProfileMenuAnchor(
                    child: avatarWidget,
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
          colors: [AppTheme.primaryColor, Color(0xFF1D7860)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isDesktop ? 40 : 16,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isDesktop ? 26 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(height: 8),
                Text(
                  'Donasi Anda tersalurkan langsung ke rekening yayasan terkait tanpa potongan perantara.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white.withAlpha(217),
                  ),
                ),
              ],
              SizedBox(height: isDesktop ? 20 : 12),
              
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusSm,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama proyek, deskripsi, atau yayasan...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDesktop ? 16 : 12),
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
          borderRadius: AppRadius.radiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
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
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusSm,
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverFeedContent(bool isDesktop) {
    if (_filteredProjects.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          mainAxisExtent: 380,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final proj = _filteredProjects[index];
            return _buildProjectCard(proj);
          },
          childCount: _filteredProjects.length,
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
    final double? target = proj['target_amount'] != null ? (proj['target_amount'] as num).toDouble() : null;
    final double raised = (proj['total_income'] as num?)?.toDouble() ?? 0.0;
    final String id = proj['id'] as String;
    final String? coverImageUrl = proj['cover_image_url'] as String?;

    return ProjectCard(
      id: id,
      name: name,
      description: desc,
      coverImageUrl: coverImageUrl,
      isPublic: true,
      status: 'active',
      foundationName: foundationName,
      targetAmount: target,
      totalIncome: raised,
      totalExpense: 0,
      balance: 0,
      isAdmin: false,
      onTap: () {
        context.go('/public/project?id=$id');
      },
    );
  }
}
