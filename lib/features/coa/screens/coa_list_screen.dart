import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/components/app_modal.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/components/empty_state_view.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../models/coa_model.dart';
import '../providers/coa_provider.dart';

class CoaListScreen extends ConsumerStatefulWidget {
  const CoaListScreen({super.key});

  @override
  ConsumerState<CoaListScreen> createState() => _CoaListScreenState();
}

class _CoaListScreenState extends ConsumerState<CoaListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _categories = const [
    {'key': 'asset', 'label': 'Aset (1xxx)'},
    {'key': 'liability', 'label': 'Liabilitas (2xxx)'},
    {'key': 'net_asset', 'label': 'Aset Neto (3xxx)'},
    {'key': 'revenue', 'label': 'Penerimaan (4xxx)'},
    {'key': 'expense', 'label': 'Beban (5xxx)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditAccountDialog([CoaModel? account]) {
    final isEdit = account != null;
    final codeController = TextEditingController(text: account?.code ?? '');
    final nameController = TextEditingController(text: account?.name ?? '');
    String selectedCategory = account?.category ?? _categories[_tabController.index]['key']!;
    bool isActive = account?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    AppModal.show<void>(
      context: context,
      title: Text(isEdit ? 'Ubah Akun' : 'Tambah Akun Baru'),
      subtitle: isEdit ? 'Edit rincian data Kode Akun (COA)' : 'Buat Kode Akun (COA) baru untuk pembukuan',
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown Kategori
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Akun',
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['key'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: isEdit
                      ? null // Kategori tidak boleh diubah saat edit untuk keamanan data
                      : (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                // Input Kode Akun
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Akun',
                    hintText: 'Contoh: 1115',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode akun tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Kode akun harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Input Nama Akun
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Akun',
                    hintText: 'Contoh: Kas Kecil',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama akun tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Switch Aktif/Nonaktif (Hanya muncul saat edit)
                if (isEdit)
                  SwitchListTile(
                    title: Text(
                      'Status Akun Aktif',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    value: isActive,
                    activeThumbColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isActive = val;
                      });
                    },
                  ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Batal',
                      style: AppButtonStyle.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: isEdit ? 'Simpan' : 'Tambah',
                      style: AppButtonStyle.primary,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final notifier = ref.read(coaProvider.notifier);
                          bool success;

                          if (isEdit) {
                            success = await notifier.updateCoa(
                              id: account.id,
                              code: codeController.text.trim(),
                              name: nameController.text.trim(),
                              category: selectedCategory,
                              isActive: isActive,
                            );
                          } else {
                            success = await notifier.addCoa(
                              code: codeController.text.trim(),
                              name: nameController.text.trim(),
                              category: selectedCategory,
                            );
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (!success) {
                            final error = ref.read(coaProvider).errorMessage ?? 'Gagal memproses akun.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: AppTheme.colorError),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Akun berhasil diperbarui' : 'Akun baru berhasil ditambahkan'),
                                backgroundColor: AppTheme.colorSuccess,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteAccount(CoaModel account) {
    final showCoaCode = ref.read(showCoaCodeProvider);
    final accountText = showCoaCode ? "${account.code} - ${account.name}" : account.name;

    AppModal.show<void>(
      context: context,
      title: const Text('Hapus Akun'),
      subtitle: 'Tindakan ini tidak dapat dibatalkan',
      content: Text(
        'Apakah Anda yakin ingin menghapus akun "$accountText"? Tindakan ini tidak dapat dibatalkan.',
        style: GoogleFonts.inter(),
      ),
      actions: [
        AppButton(
          text: 'Batal',
          style: AppButtonStyle.outline,
          onPressed: () => Navigator.pop(context),
        ),
        AppButton(
          text: 'Hapus',
          style: AppButtonStyle.secondary, // Accent color
          onPressed: () async {
            final success = await ref.read(coaProvider.notifier).deleteCoa(account.id);
            if (!mounted) return;
            Navigator.pop(context);
            if (!success) {
              final error = ref.read(coaProvider).errorMessage ?? 'Gagal menghapus akun.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: AppTheme.colorError),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akun berhasil dihapus'),
                  backgroundColor: AppTheme.colorSuccess,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final coaState = ref.watch(coaProvider);
    final showCoaCode = ref.watch(showCoaCodeProvider);

    final userRole = activeFoundation?.currentUserRole;
    final isAuthorized = userRole == 'admin' || userRole == 'treasurer';
    final isAdmin = userRole == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagan Akun (COA)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
            Text(
              'Standar Keuangan ISAK 35 - ${activeFoundation?.name ?? ""}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                'Tampilkan Kode',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: showCoaCode,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) {
                  ref.read(showCoaCodeProvider.notifier).toggle(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _categories.map((cat) => Tab(text: cat['label'])).toList(),
        ),
      ),
      body: coaState.isLoading && coaState.coaList.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : coaState.errorMessage != null && coaState.coaList.isEmpty
              ? Center(
                  child: Text(
                    coaState.errorMessage!,
                    style: GoogleFonts.inter(color: AppTheme.colorError),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _categories.map((cat) {
                    final categoryAccounts = coaState.coaList
                        .where((acc) => acc.category == cat['key'])
                        .toList();

                    if (categoryAccounts.isEmpty) {
                      return Center(
                        child: EmptyStateView(
                          icon: Icons.account_tree_outlined,
                          title: 'Belum ada akun di kategori ini',
                          description: 'Tambahkan bagan Kode Akun (COA) untuk kategori ini.',
                          actionLabel: isAuthorized ? 'Tambah Akun Baru' : null,
                          onActionPressed: isAuthorized ? () => _showAddEditAccountDialog() : null,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        if (activeFoundation != null) {
                          await ref.read(coaProvider.notifier).loadCoa(activeFoundation.id);
                        }
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: categoryAccounts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final account = categoryAccounts[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: showCoaCode
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withAlpha(18),
                                      borderRadius: AppRadius.radiusSm,
                                    ),
                                    child: Text(
                                      account.code,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : null,
                            title: Text(
                              account.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Unified StatusBadge status
                                StatusBadge(
                                  status: account.isActive ? 'approved' : 'rejected',
                                  label: account.isActive ? 'AKTIF' : 'NONAKTIF',
                                ),
                                const SizedBox(width: 8),
                                // Edit & Delete Actions (Hanya untuk Admin/Bendahara)
                                if (isAuthorized)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFFEF6C00)),
                                    onPressed: () => _showAddEditAccountDialog(account),
                                  ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                                    onPressed: () => _confirmDeleteAccount(account),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: isAuthorized
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              onPressed: () => _showAddEditAccountDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
