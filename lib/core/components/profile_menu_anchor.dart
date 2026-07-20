import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/foundations/providers/foundation_provider.dart';
import '../../features/auth/widgets/user_profile_dialog.dart';
import '../theme/app_theme.dart';
import '../theme/ui_constants.dart';
import '../../features/foundations/widgets/foundation_members_dialog.dart';

class ProfileMenuAnchor extends ConsumerStatefulWidget {
  final Widget child;

  const ProfileMenuAnchor({super.key, required this.child});

  @override
  ConsumerState<ProfileMenuAnchor> createState() => _ProfileMenuAnchorState();
}

class _ProfileMenuAnchorState extends ConsumerState<ProfileMenuAnchor> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final profile = authState.profile;

    final isDesktop = MediaQuery.of(context).size.width > 800;

    bool showGoToDashboard = false;
    if (activeFoundation != null) {
      try {
        final path = GoRouterState.of(context).uri.path;
        showGoToDashboard = path != '/dashboard';
      } catch (_) {
        try {
          final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
          showGoToDashboard = path != '/dashboard';
        } catch (_) {}
      }
    }

    if (!authState.isAuthenticated) {
      return MenuAnchor(
        controller: _menuController,
        alignmentOffset: const Offset(0, 8),
        style: MenuStyle(
          elevation: WidgetStateProperty.all(12),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
              side: const BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          backgroundColor: WidgetStateProperty.all(Colors.white),
          shadowColor: WidgetStateProperty.all(Colors.black.withAlpha(20)),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        menuChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              'Belum Masuk',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildMenuItem(
            icon: Icons.login,
            label: 'Login',
            onTap: () {
              _menuController.close();
              context.push('/login');
            },
          ),
        ],
        builder: (context, controller, _) {
          return GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: widget.child,
            ),
          );
        },
      );
    }

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        elevation: WidgetStateProperty.all(12),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        backgroundColor: WidgetStateProperty.all(Colors.white),
        shadowColor: WidgetStateProperty.all(Colors.black.withAlpha(20)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      menuChildren: [
        // Header: User Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? 'Akun Saya',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontSize: 14,
                ),
              ),
              if (activeFoundation != null) ...[
                const SizedBox(height: 2),
                Text(
                  activeFoundation.name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        
        // Edit Profil
        _buildMenuItem(
          icon: Icons.person_outline,
          label: 'Edit Profil',
          onTap: () {
            _menuController.close();
            showDialog(
              context: context,
              builder: (_) => const UserProfileDialog(),
            );
          },
        ),

        // Anggota & COA (Mobile Only, if Active Foundation is selected)
        if (!isDesktop && activeFoundation != null) ...[
          _buildMenuItem(
            icon: Icons.people_outline,
            label: 'Anggota Yayasan',
            onTap: () {
              _menuController.close();
              FoundationMembersDialog.show(context, activeFoundation.name);
            },
          ),
          _buildMenuItem(
            icon: Icons.account_tree_outlined,
            label: 'Bagan Akun (COA)',
            onTap: () {
              _menuController.close();
              context.push('/dashboard/coa');
            },
          ),
        ],

        // Pilih / Ganti Yayasan
        _buildMenuItem(
          icon: Icons.swap_horiz,
          label: activeFoundation != null ? 'Ganti Yayasan' : 'Pilih Yayasan',
          onTap: () {
            _menuController.close();
            if (activeFoundation != null) {
              ref.read(foundationProvider.notifier).selectFoundation(null);
            } else {
              context.go('/select-foundation');
            }
          },
        ),

        // Ke Dasbor (if not inside dashboard but active foundation exists)
        if (showGoToDashboard)
          _buildMenuItem(
            icon: Icons.dashboard_outlined,
            label: 'Ke Dasbor',
            onTap: () {
              _menuController.close();
              context.go('/dashboard');
            },
          ),

        const Divider(height: 1, color: AppColors.divider),
        
        _buildMenuItem(
          icon: Icons.logout,
          label: 'Logout',
          color: AppTheme.colorError,
          onTap: () {
            _menuController.close();
            context.go('/');
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
      builder: (context, controller, _) {
        return GestureDetector(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: widget.child,
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return _HoverMenuItem(
      icon: icon,
      label: label,
      onTap: onTap,
      color: color,
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _HoverMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDestructive = widget.color == AppTheme.colorError;
    final highlightColor = isDestructive 
        ? AppTheme.colorError 
        : AppTheme.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: 220, // fixed width for popup
          color: _isHovered 
              ? (isDestructive ? AppTheme.colorError.withAlpha(12) : AppTheme.primaryColor.withAlpha(12)) 
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                widget.icon, 
                size: 18, 
                color: _isHovered ? highlightColor : AppTheme.textLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _isHovered ? highlightColor : AppTheme.textDark,
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
