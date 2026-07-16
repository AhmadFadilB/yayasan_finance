import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatter.dart';
import '../../../../core/theme/ui_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/app_logo.dart';
import '../models/project_model.dart';
import '../models/donation_model.dart';
import '../services/project_service.dart';
import '../widgets/public_donation_form_dialog.dart';
import '../../../../core/utils/url_helper.dart';
import '../widgets/project_carousel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../../../core/components/profile_menu_anchor.dart';
class PublicProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const PublicProjectDetailScreen({super.key, required this.projectId});

  @override
  State<PublicProjectDetailScreen> createState() => _PublicProjectDetailScreenState();
}

class _PublicProjectDetailScreenState extends State<PublicProjectDetailScreen> {
  final ProjectService _service = ProjectService();
  
  ProjectModel? _project;
  List<DonationModel> _donations = [];
  String? _foundationName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final proj = await _service.getPublicProject(widget.projectId);
      final list = await _service.getProjectDonations(widget.projectId);
      final fInfo = await _service.getFoundationBankInfo(widget.projectId);
      
      setState(() {
        _project = proj;
        _donations = list;
        _foundationName = fInfo['foundation_name'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading project details: $e');
      setState(() {
        _errorMessage = 'Gagal memuat detail proyek: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F5A47)),
                  SizedBox(height: 16),
                  Text('Memuat informasi crowdfunding...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
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
                          onPressed: _loadProjectData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5A47),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusSm,
                            ),
                          ),
                          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(isDesktop, theme),
    );
  }

  Widget _buildContent(bool isDesktop, ThemeData theme) {
    if (_project == null) return const SizedBox();

    final target = _project!.targetAmount;
    final raised = _project!.totalIncome;
    final progress = (target != null && target > 0) ? (raised / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);
    final isTargetMet = target != null && target > 0 && raised >= target;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            _buildNavbar(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Hero Cover Carousel Banner Image
                     AspectRatio(
                       aspectRatio: 16 / 9,
                       child: Container(
                         decoration: BoxDecoration(
                           borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                           border: Border.all(color: const Color(0xFFEBEBEB), width: 1.5),
                         ),
                         clipBehavior: Clip.antiAlias,
                         child: ProjectCarousel(
                           coverImageUrl: _project!.coverImageUrl,
                           galleryUrls: _project!.galleryUrls,
                           isPublic: true,
                         ),
                       ),
                     ),
                    const SizedBox(height: 20),

                    if (isTargetMet) _buildTargetCelebrationCard(),
                    
                    const SizedBox(height: 8),
                    // Project Title
                    Text(
                      _project!.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    if (_foundationName != null) ...[
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            context.go('/public/foundation?id=${_project!.foundationId}');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business, size: 16, color: Color(0xFF0F5A47)),
                              const SizedBox(width: 6),
                              Text(
                                _foundationName!,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F5A47),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Layout 2 Columns for Desktop or 1 for Mobile
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildDetailsSection(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _buildFundingCard(raised, target, percent, progress, isTargetMet),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFundingCard(raised, target, percent, progress, isTargetMet),
                          const SizedBox(height: 24),
                          _buildDetailsSection(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCelebrationCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(77)),
      ),
      child: const Row(
        children: [
          Icon(Icons.stars, color: Colors.green, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone Tercapai! 🎉',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Target dana proyek sosial ini telah sepenuhnya terkumpul. Terima kasih kepada seluruh donatur!',
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deskripsi Proyek',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                _project!.description ?? 'Tidak ada deskripsi untuk proyek ini.',
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Donor List Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Donatur Terverifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_donations.length} Orang',
                      style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_donations.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada donasi terverifikasi.\nMari menjadi donatur pertama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _donations.length,
                  separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F1F1), height: 24),
                  itemBuilder: (context, index) {
                    final item = _donations[index];
                    final String initial = item.isAnonymous
                        ? 'HA'
                        : item.donorName.isNotEmpty
                            ? item.donorName.substring(0, 1).toUpperCase()
                            : '?';
                    final String name = item.isAnonymous ? 'Hamba Allah (Anonim)' : item.donorName;
                    
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: item.isAnonymous ? Colors.teal.shade50 : Colors.green.shade50,
                          radius: 20,
                          backgroundImage: (!item.isAnonymous && item.donorAvatarUrl != null)
                              ? NetworkImage(item.donorAvatarUrl!)
                              : null,
                          child: (item.isAnonymous || item.donorAvatarUrl == null)
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    color: item.isAnonymous ? Colors.teal : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  Formatter.formatTanggal(item.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatter.formatRupiah(item.amount ?? 0),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F5A47),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFundingCard(
    double raised,
    double? target,
    String percent,
    double progress,
    bool isTargetMet,
  ) {
    final hasTarget = target != null && target > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat 1: Raised
          const Text(
            'Dana Terkumpul',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            Formatter.formatRupiah(raised),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F5A47),
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          if (hasTarget) ...[
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 8,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F5A47), Color(0xFF4CAF50)],
                        ),
                        borderRadius: AppRadius.radiusPill,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Target details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasTarget ? '$percent% Tercapai' : 'Donasi Terbuka',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              Text(
                target != null && target > 0
                    ? 'Target: ${Formatter.formatRupiah(target)}'
                    : 'Target: Tanpa Batas',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Button Donasi
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => PublicDonationFormDialog(
                    projectId: widget.projectId,
                    onSuccess: _loadProjectData,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A47),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusSm,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Donasi Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Share Button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                final String basePath = UrlHelper.getActualPath();
                final String cleanPath = basePath.endsWith('/') ? basePath : '$basePath/';
                final String publicUrl = '${Uri.base.origin}$cleanPath#/public/project?id=${widget.projectId}';
                Clipboard.setData(ClipboardData(text: publicUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link crowdfunding berhasil disalin! Bagikan ke sosial media.'),
                    backgroundColor: Color(0xFF0F5A47),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEBEBEB)),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusSm,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Text('Bagikan Proyek', style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Name (Clickable back to discovery)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: const AppLogo(showText: true, fontSize: 18),
            ),
          ),
          
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
}
