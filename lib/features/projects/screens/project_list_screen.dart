import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/project_form_dialog.dart';
import 'project_detail_screen.dart';

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
      showDialog(
        context: context,
        builder: (_) => ProjectFormDialog(project: project),
      );
    }

    void confirmDeleteProject(String projectId, String projectName) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hapus Proyek'),
            content: Text('Apakah Anda yakin ingin menghapus proyek "$projectName"? Semua kaitan transaksi proyek ini akan di-set menjadi umum (tidak terikat proyek).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  final success = await ref.read(projectProvider.notifier).deleteProject(projectId);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proyek berhasil dihapus!')),
                    );
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }

    Widget buildStatusBadge(String status) {
      Color bg;
      Color fg;
      String text;

      switch (status) {
        case 'active':
          bg = const Color(0xFF0D5C46).withAlpha(26);
          fg = const Color(0xFF0D5C46);
          text = 'BERJALAN';
          break;
        case 'completed':
          bg = Colors.blue.withAlpha(26);
          fg = Colors.blue[800]!;
          text = 'SELESAI';
          break;
        case 'planned':
        default:
          bg = Colors.orange.withAlpha(26);
          fg = Colors.orange[800]!;
          text = 'DIRENCANAKAN';
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      );
    }

    Widget buildProjectCard(dynamic project) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(project: project),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bagian Atas: Judul & Badge & Menu Edit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A2A25),
                            ),
                          ),
                          const SizedBox(height: 4),
                          buildStatusBadge(project.status),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            showProjectForm(project: project);
                          } else if (value == 'delete') {
                            confirmDeleteProject(project.id, project.name);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Ubah'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Tengah: Deskripsi singkat
                Expanded(
                  child: Text(
                    project.description ?? 'Tidak ada deskripsi',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF6B7F79),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bawah: Laporan Keuangan Proyek
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemasukan',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          Formatter.formatRupiah(project.totalIncome),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0D5C46),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Pengeluaran',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          Formatter.formatRupiah(project.totalExpense),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Sisa',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A2A25)),
                    ),
                    Text(
                      Formatter.formatRupiah(project.balance),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: project.balance >= 0 ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: projectState.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proyek Yayasan',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            Text(
                              'Kelola program kerja dan pantau anggarannya.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF6B7F79),
                              ),
                            ),
                          ],
                        ),
                        if (isAdmin)
                          ElevatedButton.icon(
                            onPressed: () => showProjectForm(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Proyek Baru'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Grid/List Proyek
                    if (projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada proyek terdaftar.',
                                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
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
                          childAspectRatio: isDesktop ? 1.25 : 1.5,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return buildProjectCard(project);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
