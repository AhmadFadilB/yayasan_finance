import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/components/app_button.dart';
import '../providers/foundation_provider.dart';
import 'add_member_dialog.dart';

class FoundationMembersDialog extends ConsumerWidget {
  final String foundationName;

  const FoundationMembersDialog({super.key, required this.foundationName});

  static void show(BuildContext context, String foundationName) {
    AppModal.show<void>(
      context: context,
      title: Text('Anggota $foundationName'),
      subtitle: 'Kelola hak akses kolaborator yayasan',
      content: FoundationMembersDialog(foundationName: foundationName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(foundationMembersProvider);
    final activeF = ref.read(foundationProvider).activeFoundation;
    final isAdmin = activeF?.currentUserRole == 'admin';

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin) ...[
            AppButton(
              text: 'Tambah Anggota Baru',
              icon: Icons.person_add_alt_1,
              style: AppButtonStyle.primary,
              height: 40,
              onPressed: () {
                Navigator.pop(context); // Close members modal first
                AddMemberDialog.show(context);
              },
            ),
            const SizedBox(height: 16),
          ],
          
          membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Tidak ada anggota terdaftar.')),
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor,
                            backgroundImage: member.avatarUrl != null 
                                ? NetworkImage(member.avatarUrl!) 
                                : null,
                            child: member.avatarUrl == null
                                ? Text(
                                    member.name.isNotEmpty 
                                        ? member.name.substring(0, 1).toUpperCase() 
                                        : '?',
                                    style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(18),
                              borderRadius: AppRadius.radiusPill,
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (e, __) => Center(child: Text('Error: ${e.toString()}')),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Tutup',
                style: AppButtonStyle.outline,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
