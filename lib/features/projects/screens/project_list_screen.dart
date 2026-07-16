import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/components/empty_state_view.dart';
import 'package:go_router/go_router.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../providers/project_provider.dart';
import 'project_detail_screen.dart';
import '../widgets/project_card.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsWithFinanceProvider);
    final projectState = ref.watch(projectProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final isAdmin = activeFoundation?.currentUserRole == 'admin';
    
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    void showProjectForm({dynamic project}) {
      if (project == null) {
        context.push('/proyek/tambah');
      } else {
        context.push('/proyek/${project.id}/edit');
      }
    }

    void confirmDeleteProject(String projectId, String projectName) {
      AppModal.show(
        context: context,
        title: const Text('Hapus Proyek'),
        subtitle: 'Tindakan ini tidak dapat dibatalkan',
        content: Text('Apakah Anda yakin ingin menghapus proyek "$projectName"? Semua kaitan transaksi proyek ini akan di-set menjadi umum (tidak terikat proyek).'),
        actions: [
          AppButton(
            text: 'Batal',
            style: AppButtonStyle.outline,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Hapus',
            style: AppButtonStyle.secondary, // Accent style
            onPressed: () async {
              final success = await ref.read(projectProvider.notifier).deleteProject(projectId);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proyek berhasil dihapus'),
                    backgroundColor: AppTheme.colorSuccess,
                  ),
                );
              }
            },
          ),
        ],
      );
    }



    // buildProjectCard removed and replaced with generic ProjectCard widget

    return Scaffold(
      body: projectState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: () async {
                if (activeFoundation != null) {
                  await ref.read(projectProvider.notifier).loadProjects(activeFoundation.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header daftar proyek & button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proyek Yayasan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Kelola program kerja dan pantau anggarannya.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          AppButton(
                            text: 'Proyek Baru',
                            icon: Icons.add,
                            height: 40,
                            onPressed: () => showProjectForm(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grid/List Proyek
                    if (projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: EmptyStateView(
                          icon: Icons.business_outlined,
                          title: 'Belum ada proyek terdaftar',
                          description: 'Mulai buat proyek program kerja baru untuk mengelola donasi.',
                          actionLabel: isAdmin ? 'Buat Proyek Baru' : null,
                          onActionPressed: isAdmin ? () => showProjectForm() : null,
                        ),
                      )
                    else
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 380,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return ProjectCard(
                            id: project.id,
                            name: project.name,
                            description: project.description,
                            coverImageUrl: project.coverImageUrl,
                            isPublic: project.isPublic,
                            status: project.status,
                            foundationName: activeFoundation?.name ?? '',
                            targetAmount: project.targetAmount,
                            totalIncome: project.totalIncome,
                            totalExpense: project.totalExpense,
                            balance: project.balance,
                            isAdmin: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(project: project),
                                ),
                              );
                            },
                            onEdit: () => showProjectForm(project: project),
                            onDelete: () => confirmDeleteProject(project.id, project.name),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
