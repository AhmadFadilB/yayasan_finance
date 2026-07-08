import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../foundations/widgets/add_member_dialog.dart';
import '../../projects/screens/project_list_screen.dart';
import '../../reports/screens/report_screen.dart';
import '../../transactions/screens/transaction_list_screen.dart';
import '../../audit_logs/screens/audit_log_screen.dart';
import '../../transactions/screens/approval_list_screen.dart';
import '../../coa/screens/coa_list_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

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
      const ProjectListScreen(),
      const TransactionListScreen(),
      if (isAdmin) const ApprovalListScreen(),
      const ReportScreen(),
      const AuditLogScreen(),
    ];

    final navigationDestinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: Colors.white),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business, color: Colors.white),
        label: 'Proyek',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
        label: 'Transaksi',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.rule_outlined),
          selectedIcon: Icon(Icons.rule, color: Colors.white),
          label: 'Persetujuan',
        ),
      NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics, color: Colors.white),
        label: 'Laporan',
      ),
      NavigationDestination(
        icon: Icon(Icons.history_toggle_off_outlined),
        selectedIcon: Icon(Icons.history_toggle_off, color: Colors.white),
        label: 'Log Audit',
      ),
    ];

    final railDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
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
      appBar: AppBar(
        title: buildAppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Anggota Yayasan',
            onPressed: () => _showFoundationMembersDialog(activeFoundation.name),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Bagan Akun (COA)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoaListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Ganti Yayasan',
            onPressed: () {
              // Mengembalikan seleksi ke null agar memicu tampilan pemilihan yayasan
              ref.read(foundationProvider.notifier).selectFoundation(null);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
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
      // Bottom Navigation untuk Mobile
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: navigationDestinations,
            )
          : null,
    );
  }
}
