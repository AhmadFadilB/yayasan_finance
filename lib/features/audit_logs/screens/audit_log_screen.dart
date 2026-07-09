import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/formatter.dart';
import '../models/audit_log_model.dart';
import '../providers/audit_log_provider.dart';
import '../../foundations/providers/foundation_provider.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _selectedTable = 'Semua';
  String _selectedAction = 'Semua';
  final Map<String, bool> _expandedLogs = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeFoundation = ref.read(foundationProvider).activeFoundation;
      if (activeFoundation != null) {
        ref.read(auditLogProvider.notifier).loadLogs(activeFoundation.id);
      }
    });
  }

  final List<String> _tableFilters = const [
    'Semua',
    'Transaksi',
    'Proyek',
    'Anggota',
    'Yayasan'
  ];

  final List<String> _actionFilters = const [
    'Semua',
    'Tambah',
    'Ubah',
    'Hapus'
  ];

  String _mapFilterToDbTable(String filter) {
    switch (filter) {
      case 'Transaksi':
        return 'transactions';
      case 'Proyek':
        return 'projects';
      case 'Anggota':
        return 'foundation_members';
      case 'Yayasan':
        return 'foundations';
      default:
        return '';
    }
  }

  String _mapFilterToDbAction(String filter) {
    switch (filter) {
      case 'Tambah':
        return 'INSERT';
      case 'Ubah':
        return 'UPDATE';
      case 'Hapus':
        return 'DELETE';
      default:
        return '';
    }
  }

  String _getFriendlyTableName(String tableName) {
    switch (tableName) {
      case 'transactions':
        return 'Transaksi';
      case 'projects':
        return 'Proyek';
      case 'foundation_members':
        return 'Anggota';
      case 'foundations':
        return 'Yayasan';
      default:
        return tableName;
    }
  }

  String _getFriendlyAction(String action) {
    switch (action) {
      case 'INSERT':
        return 'Menambahkan';
      case 'UPDATE':
        return 'Mengubah';
      case 'DELETE':
        return 'Menghapus';
      default:
        return action;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'INSERT':
        return const Color(0xFF2E7D32); // Green
      case 'UPDATE':
        return const Color(0xFFEF6C00); // Orange
      case 'DELETE':
        return const Color(0xFFC62828); // Red
      default:
        return const Color(0xFF455A64);
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'INSERT':
        return Icons.add_circle_outline;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  bool _isSystemField(String key) {
    const systemFields = {
      'id',
      'foundation_id',
      'created_at',
      'updated_at',
      'created_by',
      'account_id',
      'project_id',
      'user_id',
      'approved_by',
      'approved_at',
      'receipt_url',
    };
    return systemFields.contains(key);
  }

  String _getFriendlyFieldName(String key) {
    switch (key) {
      case 'amount':
        return 'Nominal';
      case 'category':
        return 'Kategori';
      case 'type':
        return 'Tipe';
      case 'description':
        return 'Deskripsi';
      case 'name':
        return 'Nama';
      case 'status':
        return 'Status';
      case 'role':
        return 'Peran';
      case 'start_date':
        return 'Tanggal Mulai';
      case 'end_date':
        return 'Tanggal Selesai';
      case 'transaction_date':
        return 'Tanggal Transaksi';
      default:
        final String readable = key.replaceAll('_', ' ');
        if (readable.isEmpty) return key;
        return readable[0].toUpperCase() + readable.substring(1);
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    if (value == null) return '-';
    if (key == 'amount') {
      try {
        final numVal = num.parse(value.toString());
        return Formatter.formatRupiah(numVal);
      } catch (_) {
        return value.toString();
      }
    }
    if (key == 'type') {
      if (value.toString() == 'income') return 'Pemasukan';
      if (value.toString() == 'expense') return 'Pengeluaran';
      return value.toString();
    }
    if (key == 'status') {
      switch (value.toString()) {
        case 'active':
          return 'Aktif';
        case 'completed':
          return 'Selesai';
        case 'planned':
          return 'Direncanakan';
        case 'pending':
          return 'Tertunda';
        case 'approved':
          return 'Disetujui';
        case 'rejected':
          return 'Ditolak';
        default:
          return value.toString();
      }
    }
    if (key == 'role') {
      switch (value.toString()) {
        case 'admin':
          return 'Pimpinan';
        case 'bendahara':
          return 'Bendahara';
        case 'viewer':
          return 'Viewer / Pengawas';
        default:
          return value.toString();
      }
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditLogProvider);
    final activeFoundation = ref.watch(foundationProvider).activeFoundation;

    // Filter data di memori agar cepat
    List<AuditLog> filteredLogs = auditState.logs;

    if (_selectedTable != 'Semua') {
      final dbTable = _mapFilterToDbTable(_selectedTable);
      filteredLogs = filteredLogs.where((log) => log.tableName == dbTable).toList();
    }

    if (_selectedAction != 'Semua') {
      final dbAction = _mapFilterToDbAction(_selectedAction);
      filteredLogs = filteredLogs.where((log) => log.action == dbAction).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: RefreshIndicator(
        onRefresh: () async {
          if (activeFoundation != null) {
            await ref.read(auditLogProvider.notifier).loadLogs(activeFoundation.id);
          }
        },
        child: CustomScrollView(
          slivers: [
            // Header Layar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Audit Aktivitas',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2A25),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Riwayat lengkap perubahan data di yayasan ini.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF6B7F79),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter Berdasarkan Modul / Tabel
                    Text(
                      'Modul Data',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B7F79),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tableFilters.map((filter) {
                          final isSelected = _selectedTable == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0D5C46).withAlpha(38),
                              checkmarkColor: const Color(0xFF0D5C46),
                              labelStyle: GoogleFonts.outfit(
                                color: isSelected ? const Color(0xFF0D5C46) : const Color(0xFF455A64),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTable = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter Berdasarkan Aksi
                    Text(
                      'Tindakan',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B7F79),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _actionFilters.map((filter) {
                          final isSelected = _selectedAction == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0D5C46).withAlpha(38),
                              checkmarkColor: const Color(0xFF0D5C46),
                              labelStyle: GoogleFonts.outfit(
                                color: isSelected ? const Color(0xFF0D5C46) : const Color(0xFF455A64),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedAction = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
            ),

            // Konten Log
            if (auditState.isLoading && auditState.logs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0D5C46),
                  ),
                ),
              )
            else if (auditState.errorMessage != null && auditState.logs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    auditState.errorMessage!,
                    style: GoogleFonts.outfit(color: Colors.red),
                  ),
                ),
              )
            else if (filteredLogs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history_toggle_off,
                        size: 64,
                        color: Color(0xFFB0BEC5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada riwayat aktivitas.',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7F79),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = filteredLogs[index];
                    final isExpanded = _expandedLogs[log.id] ?? false;
                    final actionColor = _getActionColor(log.action);
                    final actionIcon = _getActionIcon(log.action);
                    final dateStr = Formatter.formatTanggal(log.createdAt);
                    final timeStr = DateFormat('HH:mm').format(log.createdAt);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.withAlpha(38)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: actionColor.withAlpha(26),
                                child: Icon(actionIcon, color: actionColor),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    _getFriendlyAction(log.action),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: actionColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getFriendlyTableName(log.tableName),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A2A25),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7F79)),
                                      const SizedBox(width: 4),
                                      Text(
                                        log.performedByName ?? 'Sistem',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: const Color(0xFF37474F),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF6B7F79)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$dateStr pukul $timeStr',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF6B7F79),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: const Color(0xFF6B7F79),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _expandedLogs[log.id] = !isExpanded;
                                  });
                                },
                              ),
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildLogDetails(log),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filteredLogs.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogDetails(AuditLog log) {
    if (log.action == 'INSERT' && log.newValues != null) {
      return _buildValuesList(log.newValues!, 'Detail Data Baru:');
    } else if (log.action == 'DELETE' && log.oldValues != null) {
      return _buildValuesList(log.oldValues!, 'Detail Data Terhapus:');
    } else if (log.action == 'UPDATE' && log.oldValues != null && log.newValues != null) {
      return _buildChangesComparison(log);
    }
    return const SizedBox.shrink();
  }

  Widget _buildValuesList(Map<String, dynamic> values, String title) {
    // Filter internal columns
    final filteredKeys = values.keys.where((k) => !_isSystemField(k)).toList();

    if (filteredKeys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: const Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(120),
            1: FlexColumnWidth(),
          },
          children: filteredKeys.map((key) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    _getFriendlyFieldName(key),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B7F79),
                      fontSize: 12,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    _formatFieldValue(key, values[key]),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A2A25),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChangesComparison(AuditLog log) {
    final oldMap = log.oldValues!;
    final newMap = log.newValues!;
    final changedKeys = <String>[];

    for (var key in newMap.keys) {
      if (_isSystemField(key)) {
        continue;
      }
      final oldVal = oldMap[key];
      final newVal = newMap[key];
      // Bandingkan representasi string
      if (oldVal.toString() != newVal.toString()) {
        changedKeys.add(key);
      }
    }

    if (changedKeys.isEmpty) {
      return Text(
        'Tidak ada perubahan field utama.',
        style: GoogleFonts.outfit(
          fontStyle: FontStyle.italic,
          fontSize: 12,
          color: const Color(0xFF6B7F79),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Perubahan:',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: const Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FlexColumnWidth(),
          },
          children: changedKeys.map((key) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    _getFriendlyFieldName(key),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B7F79),
                      fontSize: 12,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatFieldValue(key, oldMap[key]),
                          style: GoogleFonts.outfit(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFF6B7F79)),
                      ),
                      Expanded(
                        child: Text(
                          _formatFieldValue(key, newMap[key]),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
