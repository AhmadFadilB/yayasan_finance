import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../foundations/widgets/add_member_dialog.dart';
import '../../projects/screens/project_list_screen.dart';
import '../../projects/screens/public_project_feed_screen.dart';
import '../../foundations/screens/foundation_profile_edit_screen.dart';
import '../../auth/widgets/user_profile_dialog.dart';
import '../../reports/screens/report_screen.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../audit_logs/screens/audit_log_screen.dart';
import '../../transactions/screens/approval_list_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/utils/formatter.dart';
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
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        ref.read(notificationProvider.notifier).markAllAsRead();
                      },
                      child: Text(
                        'Tandai Semua Dibaca',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0D5C46), fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D5C46)))
                    : state.notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada notifikasi baru',
                                  style: GoogleFonts.outfit(color: Colors.grey),
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

  void _showUserProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => const UserProfileDialog(),
    );
  }

  Widget _buildMobileDrawer(dynamic activeFoundation, bool isAdmin) {
    // Menu items list
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dasbor', 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard},
      {'title': 'Jelajah', 'icon': Icons.explore_outlined, 'selectedIcon': Icons.explore},
      {'title': 'Proyek', 'icon': Icons.business_outlined, 'selectedIcon': Icons.business},
      {'title': 'Transaksi', 'icon': Icons.receipt_long_outlined, 'selectedIcon': Icons.receipt_long},
      if (isAdmin)
        {'title': 'Validasi', 'icon': Icons.rule_outlined, 'selectedIcon': Icons.rule},
      {'title': 'Laporan', 'icon': Icons.analytics_outlined, 'selectedIcon': Icons.analytics},
      {'title': 'Audit', 'icon': Icons.history_toggle_off_outlined, 'selectedIcon': Icons.history_toggle_off},
      {'title': 'Profil Yayasan', 'icon': Icons.business_outlined, 'selectedIcon': Icons.business},
    ];

    final initials = activeFoundation.name.isNotEmpty 
        ? activeFoundation.name.substring(0, 1).toUpperCase() 
        : '?';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header with Emerald theme
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F5A47), Color(0xFF0D5C46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withAlpha(51),
                  backgroundImage: activeFoundation.logoUrl != null 
                      ? NetworkImage(activeFoundation.logoUrl!) 
                      : null,
                  child: activeFoundation.logoUrl == null
                      ? Text(
                          initials,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeFoundation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (activeFoundation.currentUserRole ?? 'viewer').toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF0D5C46).withAlpha(18),
                    selectedColor: const Color(0xFF0D5C46),
                    iconColor: const Color(0xFF6B7F79),
                    textColor: const Color(0xFF1A2A25),
                    leading: Icon(
                      isSelected ? item['selectedIcon'] : item['icon'],
                    ),
                    title: Text(
                      item['title'],
                      style: GoogleFonts.outfit(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.pop(context); // Close Drawer
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFoundationMembersDialog(String foundationName) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final membersAsync = ref.watch(foundationMembersProvider);
            final activeF = ref.read(foundationProvider).activeFoundation;
            final isAdmin = activeF?.currentUserRole == 'admin';

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Anggota $foundationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0D5C46)),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => const AddMemberDialog(),
                        );
                      },
                    ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return const Center(child: Text('Tidak ada anggota terdaftar.'));
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF0D5C46),
                                backgroundImage: member.avatarUrl != null 
                                    ? NetworkImage(member.avatarUrl!) 
                                    : null,
                                child: member.avatarUrl == null
                                    ? Text(
                                        member.name.isNotEmpty 
                                            ? member.name.substring(0, 1).toUpperCase() 
                                            : '?',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  member.name,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D5C46).withAlpha(18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  member.role.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(0xFF0D5C46),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Error: ${e.toString()}')),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
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
                Text(newNotif.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(newNotif.message, style: GoogleFonts.outfit(fontSize: 12)),
              ],
            ),
            backgroundColor: const Color(0xFF0D5C46),
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
      const ReportScreen(),
      const AuditLogScreen(),
      const FoundationProfileEditScreen(),
    ];



    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: Text('Jelajah'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: Text('Proyek'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Transaksi'),
      ),
      if (isAdmin)
        const NavigationRailDestination(
          icon: Icon(Icons.rule_outlined),
          selectedIcon: Icon(Icons.rule),
          label: Text('Persetujuan'),
        ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Laporan'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.history_toggle_off_outlined),
        selectedIcon: Icon(Icons.history_toggle_off),
        label: Text('Log Audit'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.business),
        selectedIcon: Icon(Icons.business),
        label: Text('Profil Yayasan'),
      ),
    ];

    Widget buildAppBarTitle() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                activeFoundation.name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2A25),
                ),
              ),
              const SizedBox(width: 8),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5C46).withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (activeFoundation.currentUserRole ?? 'viewer').toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D5C46),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Kelola Keuangan Yayasan',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF6B7F79),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      drawer: !isDesktop ? _buildMobileDrawer(activeFoundation, isAdmin) : null,
      appBar: AppBar(
        centerTitle: !isDesktop ? true : null,
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
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifikasi',
                    onPressed: _showNotificationCenter,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
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
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Anggota Yayasan',
              onPressed: () => _showFoundationMembersDialog(activeFoundation.name),
            ),
            IconButton(
              icon: const Icon(Icons.account_tree_outlined),
              tooltip: 'Bagan Akun (COA)',
              onPressed: () {
                context.push('/dashboard/coa');
              },
            ),
          ],
          Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(authProvider).profile;
              final avatarUrl = profile?.avatarUrl;
              final initials = profile?.name.isNotEmpty == true 
                  ? profile!.name.substring(0, 1).toUpperCase() 
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
                      _showUserProfileDialog();
                      break;
                    case 'members':
                      _showFoundationMembersDialog(activeFoundation.name);
                      break;
                    case 'coa':
                      context.push('/dashboard/coa');
                      break;
                    case 'switch':
                      ref.read(foundationProvider.notifier).selectFoundation(null);
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
                        const Icon(Icons.person_outline, size: 20, color: Color(0xFF0D5C46)),
                        const SizedBox(width: 8),
                        Text('Profil Saya', style: GoogleFonts.outfit()),
                      ],
                    ),
                  ),
                  if (!isDesktop) ...[
                    PopupMenuItem(
                      value: 'members',
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, size: 20, color: Color(0xFF0D5C46)),
                          const SizedBox(width: 8),
                          Text('Anggota Yayasan', style: GoogleFonts.outfit()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'coa',
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 20, color: Color(0xFF0D5C46)),
                          const SizedBox(width: 8),
                          Text('Bagan Akun (COA)', style: GoogleFonts.outfit()),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz, size: 20, color: Color(0xFF0D5C46)),
                        const SizedBox(width: 8),
                        Text('Ganti Yayasan', style: GoogleFonts.outfit()),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
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
      body: Row(
        children: [
          // Sidebar Navigasi untuk Desktop
          if (isDesktop) ...[
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              destinations: railDestinations,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF0D5C46),
                  foregroundColor: Colors.white,
                  child: Text(
                    activeFoundation.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          // Halaman Utama
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: screens[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}
