import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_logo.dart';
import '../../../core/components/profile_menu_anchor.dart';
import '../../foundations/widgets/foundation_members_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../projects/screens/project_list_screen.dart';
import '../../projects/screens/public_project_feed_screen.dart';
import '../../foundations/screens/foundation_profile_edit_screen.dart';
import '../../reports/screens/report_screen.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../audit_logs/screens/audit_log_screen.dart';
import '../../transactions/screens/approval_list_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/utils/formatter.dart';
import '../../accounting/screens/journal_list_screen.dart';
import '../../accounting/screens/isak35_reports_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _showNotificationCenter() {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(notificationProvider);
            final role = ref.read(foundationProvider).activeFoundation?.currentUserRole ?? 'viewer';
            final isAdmin = role == 'admin';

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifikasi',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        ref.read(notificationProvider.notifier).markAllAsRead();
                      },
                      child: Text(
                        'Tandai Semua Dibaca',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: state.isLoading
                    ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : state.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada notifikasi baru',
                                  style: GoogleFonts.inter(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: state.notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final notif = state.notifications[index];

                              IconData iconData;
                              Color iconColor;
                              switch (notif.type) {
                                case 'pending_approval':
                                  iconData = Icons.rule_outlined;
                                  iconColor = Colors.orange;
                                  break;
                                case 'large_income':
                                  iconData = Icons.arrow_downward;
                                  iconColor = const Color(0xFF2E7D32);
                                  break;
                                default:
                                  iconData = Icons.info_outline;
                                  iconColor = Colors.blue;
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                leading: CircleAvatar(
                                  backgroundColor: iconColor.withAlpha(26),
                                  child: Icon(iconData, color: iconColor, size: 18),
                                ),
                                title: Text(
                                  notif.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.message,
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatter.formatTanggal(notif.createdAt),
                                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: !notif.isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () {
                                  ref.read(notificationProvider.notifier).markAsRead(notif.id);
                                  Navigator.pop(context);

                                  if (notif.type == 'pending_approval' && isAdmin) {
                                    setState(() {
                                      _selectedIndex = 4; // Pindah ke tab Persetujuan
                                    });
                                  }
                                },
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Widget _buildMobileDrawer(dynamic activeFoundation, bool isAdmin) {
    final List<SidebarItem> operasionalItems = [
      SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
      SidebarItem(title: 'Jelajah', icon: Icons.explore_outlined, index: 1),
      SidebarItem(title: 'Proyek', icon: Icons.business_outlined, index: 2),
      SidebarItem(title: 'Transaksi', icon: Icons.receipt_long_outlined, index: 3),
      if (isAdmin)
        SidebarItem(title: 'Persetujuan', icon: Icons.rule_outlined, index: 4),
    ];

    final List<SidebarItem> administratifItems = [
      SidebarItem(title: 'Jurnal Umum', icon: Icons.menu_book_outlined, index: isAdmin ? 5 : 4),
      SidebarItem(title: 'Laporan', icon: Icons.analytics_outlined, index: isAdmin ? 6 : 5),
      SidebarItem(title: 'Laporan ISAK 35', icon: Icons.table_chart_outlined, index: isAdmin ? 7 : 6),
      SidebarItem(title: 'Log Audit', icon: Icons.history_toggle_off_outlined, index: isAdmin ? 8 : 7),
      SidebarItem(title: 'Profil Yayasan', icon: Icons.apartment_outlined, index: isAdmin ? 9 : 8),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header logo + Close button
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppLogo(showText: true, fontSize: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B7570), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEBEBEB)),
          
          // Foundation switcher card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F2),
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      activeFoundation.name.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeFoundation.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          (activeFoundation.currentUserRole ?? 'viewer').toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF6B7570)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEBEBEB)),
          const SizedBox(height: 12),

          // Scrollable Menu List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group 1: Operasional
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      'OPERASIONAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B7570),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...operasionalItems.map((item) => HoverSidebarItem(
                        title: item.title,
                        icon: item.icon,
                        isSelected: _selectedIndex == item.index,
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          if (item.title == 'Jelajah') {
                            context.go('/');
                          } else {
                            setState(() => _selectedIndex = item.index);
                          }
                        },
                      )),
                  const SizedBox(height: 16),
                  
                  // Group 2: Administratif
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      'ADMINISTRATIF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B7570),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...administratifItems.map((item) => HoverSidebarItem(
                        title: item.title,
                        icon: item.icon,
                        isSelected: _selectedIndex == item.index,
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          setState(() => _selectedIndex = item.index);
                        },
                      )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDesktopSidebar(BuildContext context, dynamic activeFoundation, bool isAdmin) {
    final List<SidebarItem> operasionalItems = [
      SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
      SidebarItem(title: 'Jelajah', icon: Icons.explore_outlined, index: 1),
      SidebarItem(title: 'Proyek', icon: Icons.business_outlined, index: 2),
      SidebarItem(title: 'Transaksi', icon: Icons.receipt_long_outlined, index: 3),
      if (isAdmin)
        SidebarItem(title: 'Persetujuan', icon: Icons.rule_outlined, index: 4),
    ];

    final List<SidebarItem> administratifItems = [
      SidebarItem(title: 'Jurnal Umum', icon: Icons.menu_book_outlined, index: isAdmin ? 5 : 4),
      SidebarItem(title: 'Laporan', icon: Icons.analytics_outlined, index: isAdmin ? 6 : 5),
      SidebarItem(title: 'Laporan ISAK 35', icon: Icons.table_chart_outlined, index: isAdmin ? 7 : 6),
      SidebarItem(title: 'Log Audit', icon: Icons.history_toggle_off_outlined, index: isAdmin ? 8 : 7),
      SidebarItem(title: 'Profil Yayasan', icon: Icons.apartment_outlined, index: isAdmin ? 9 : 8),
    ];

    return Container(
      width: 250,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(
          right: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(showText: true, fontSize: 16, color: Colors.white),
                const SizedBox(height: 16),
                // Foundation info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.secondaryColor,
                        child: Text(
                          activeFoundation.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeFoundation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              (activeFoundation.currentUserRole ?? 'viewer').toUpperCase(),
                              style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70),
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
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 12),
          // Group 1: Operasional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'OPERASIONAL',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white30,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...operasionalItems.map((item) => HoverSidebarItem(
                title: item.title,
                icon: item.icon,
                isSelected: _selectedIndex == item.index,
                onTap: () {
                  if (item.title == 'Jelajah') {
                    context.go('/');
                  } else {
                    setState(() => _selectedIndex = item.index);
                  }
                },
              )),
          const SizedBox(height: 16),
          // Group 2: Administratif
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'ADMINISTRATIF',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white30,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...administratifItems.map((item) => HoverSidebarItem(
                title: item.title,
                icon: item.icon,
                isSelected: _selectedIndex == item.index,
                onTap: () => setState(() => _selectedIndex = item.index),
              )),
          const Spacer(),
          // Bottom area: Switch / logout quick action
          const Divider(height: 1, color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () {
                      ref.read(foundationProvider.notifier).selectFoundation(null);
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(
                      'Ganti Yayasan',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan notifikasi baru untuk memicu banner in-app secara realtime
    ref.listen(notificationProvider, (previous, next) {
      final newNotif = next.lastNewNotification;
      if (newNotif != null) {
        final role = ref.read(foundationProvider).activeFoundation?.currentUserRole ?? 'viewer';
        final isAdmin = role == 'admin';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(newNotif.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                Text(newNotif.message, style: GoogleFonts.inter(fontSize: 12)),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () {
                ref.read(notificationProvider.notifier).markAsRead(newNotif.id);
                if (newNotif.type == 'pending_approval' && isAdmin) {
                  setState(() {
                    _selectedIndex = 4; // Pindah ke tab Persetujuan
                  });
                }
              },
            ),
          ),
        );
        ref.read(notificationProvider.notifier).clearLastNewNotification();
      }
    });

    // Dengarkan pergantian yayasan untuk me-reset index
    ref.listen(foundationProvider, (previous, next) {
      if (previous?.activeFoundation?.id != next.activeFoundation?.id) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    });

    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    if (activeFoundation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = activeFoundation.currentUserRole ?? 'viewer';
    final isAdmin = role == 'admin';

    final List<Widget> screens = [
      const DashboardScreen(),
      const PublicProjectFeedScreen(showNavbar: false),
      const ProjectListScreen(),
      const TransactionListScreen(),
      if (isAdmin) const ApprovalListScreen(),
      const JournalListScreen(),
      const ReportScreen(),
      const Isak35ReportsScreen(),
      const AuditLogScreen(),
      const FoundationProfileEditScreen(),
    ];



    String getActivePageTitle() {
      final List<String> pageTitles = [
        'Dashboard',
        'Jelajah Proyek Sosial',
        'Manajemen Proyek',
        'Transaksi Keuangan',
        if (isAdmin) 'Persetujuan Transaksi',
        'Jurnal Umum (Double-Entry)',
        'Laporan Transaksi',
        'Laporan Keuangan ISAK 35',
        'Log Audit Keamanan',
        'Profil Yayasan',
      ];
      if (_selectedIndex >= 0 && _selectedIndex < pageTitles.length) {
        return pageTitles[_selectedIndex];
      }
      return 'Yayasan Finance';
    }

    Widget buildAppBarTitle() {
      return Text(
        getActivePageTitle(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1F1C),
        ),
      );
    }

    return Scaffold(
      drawer: !isDesktop ? _buildMobileDrawer(activeFoundation, isAdmin) : null,
      appBar: AppBar(
        centerTitle: !isDesktop ? true : null,
        elevation: 0,
        backgroundColor: Colors.white,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFEBEBEB), width: 1),
        ),
        leading: !isDesktop
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu Utama',
                ),
              )
            : null,
        title: buildAppBarTitle(),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));
              return Stack(
                alignment: Alignment.center,
                children: [
                  HoverIconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF6B7570)),
                    tooltip: 'Notifikasi',
                    onPressed: _showNotificationCenter,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.colorError,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            HoverIconButton(
              icon: const Icon(Icons.people_outline, color: Color(0xFF6B7570)),
              tooltip: 'Anggota Yayasan',
              onPressed: () => FoundationMembersDialog.show(context, activeFoundation.name),
            ),
            const SizedBox(width: 8),
            HoverIconButton(
              icon: const Icon(Icons.account_tree_outlined, color: Color(0xFF6B7570)),
              tooltip: 'Bagan Akun (COA)',
              onPressed: () {
                context.push('/dashboard/coa');
              },
            ),
          ],
          const SizedBox(width: 8),
          Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(authProvider).profile;
              final avatarUrl = profile?.avatarUrl;
              final initials = profile?.name.isNotEmpty == true 
                  ? profile!.name.substring(0, 1).toUpperCase() 
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        avatarWidget,
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF6B7570)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigasi untuk Desktop
          if (isDesktop) ...[
            _buildDesktopSidebar(context, activeFoundation, isAdmin),
          ],
          // Halaman Utama
          Expanded(
            child: Container(
              color: const Color(0xFFF7F6F2),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;

  SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}

class HoverSidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const HoverSidebarItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<HoverSidebarItem> createState() => _HoverSidebarItemState();
}

class _HoverSidebarItemState extends State<HoverSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    
    Color bgColor = Colors.transparent;
    if (isSelected) {
      bgColor = Colors.white.withAlpha(26);
    } else if (_isHovered) {
      bgColor = Colors.white.withAlpha(13);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.radiusSm,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
              const SizedBox(width: 13),
              Icon(
                widget.icon,
                color: isSelected ? AppTheme.secondaryColor : Colors.white60,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverIconButton extends StatefulWidget {
  final Widget icon;
  final String? tooltip;
  final VoidCallback onPressed;

  const HoverIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    required this.onPressed,
  });

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFF7F6F2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
