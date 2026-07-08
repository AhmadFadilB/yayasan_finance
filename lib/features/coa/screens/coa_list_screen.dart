import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Ubah Akun' : 'Tambah Akun Baru',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown Kategori
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Akun',
                          border: OutlineInputBorder(),
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
                          border: OutlineInputBorder(),
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
                          border: OutlineInputBorder(),
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
                            style: GoogleFonts.outfit(fontSize: 14),
                          ),
                          value: isActive,
                          activeColor: const Color(0xFF0D5C46),
                          onChanged: (val) {
                            setDialogState(() {
                              isActive = val;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5C46),
                    foregroundColor: Colors.white,
                  ),
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
                          SnackBar(content: Text(error), backgroundColor: Colors.red),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? 'Akun berhasil diperbarui' : 'Akun baru berhasil ditambahkan'),
                            backgroundColor: const Color(0xFF0D5C46),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(CoaModel account) {
    final showCoaCode = ref.read(showCoaCodeProvider);
    final accountText = showCoaCode ? "${account.code} - ${account.name}" : account.name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Hapus Akun',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun "$accountText"? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final success = await ref.read(coaProvider.notifier).deleteCoa(account.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!success) {
                    final error = ref.read(coaProvider).errorMessage ?? 'Gagal menghapus akun.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Akun berhasil dihapus'),
                        backgroundColor: Color(0xFF0D5C46),
                      ),
                    );
                  }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coaState = ref.watch(coaProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;
    final userRole = activeFoundation?.currentUserRole ?? 'viewer';
    final isAuthorized = userRole == 'admin' || userRole == 'bendahara';
    final isAdmin = userRole == 'admin';
    final showCoaCode = ref.watch(showCoaCodeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bagan Akun (COA)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Standar Keuangan ISAK 35 - ${activeFoundation?.name ?? ""}',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF6B7F79)),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                'Tampilkan Kode',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF455A64)),
              ),
              const SizedBox(width: 4),
              Switch(
                value: showCoaCode,
                activeColor: const Color(0xFF0D5C46),
                onChanged: (val) {
                  ref.read(showCoaCodeProvider.notifier).toggle(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0D5C46),
          unselectedLabelColor: const Color(0xFF455A64),
          indicatorColor: const Color(0xFF0D5C46),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _categories.map((cat) => Tab(text: cat['label'])).toList(),
        ),
      ),
      body: coaState.isLoading && coaState.coaList.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D5C46)))
          : coaState.errorMessage != null && coaState.coaList.isEmpty
              ? Center(
                  child: Text(
                    coaState.errorMessage!,
                    style: GoogleFonts.outfit(color: Colors.red),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_tree_outlined, size: 64, color: Color(0xFFB0BEC5)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada akun di kategori ini.',
                              style: GoogleFonts.outfit(color: const Color(0xFF6B7F79), fontSize: 14),
                            ),
                          ],
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
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final account = categoryAccounts[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: showCoaCode
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D5C46).withAlpha(18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      account.code,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D5C46),
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : null,
                            title: Text(
                              account.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge Status
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: account.isActive
                                        ? Colors.green.withAlpha(20)
                                        : Colors.red.withAlpha(20),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    account.isActive ? 'Aktif' : 'Nonaktif',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: account.isActive ? Colors.green[800] : Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
              backgroundColor: const Color(0xFF0D5C46),
              foregroundColor: Colors.white,
              onPressed: () => _showAddEditAccountDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
