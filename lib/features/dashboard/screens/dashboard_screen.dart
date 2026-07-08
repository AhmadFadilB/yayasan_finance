import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../widgets/financial_chart.dart';

enum DashboardFilter { thisMonth, allTime }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardFilter _activeFilter = DashboardFilter.thisMonth;

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final now = DateTime.now();
    final filteredTxs = transactionState.transactions.where((tx) {
      if (tx.status != 'approved') return false;
      if (_activeFilter == DashboardFilter.thisMonth) {
        return tx.transactionDate.year == now.year && tx.transactionDate.month == now.month;
      }
      return true; // all time
    }).toList();

    // Hitung total ringkasan keuangan
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in filteredTxs) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final double netBalance = totalIncome - totalExpense;

    // Ambil maksimal 5 transaksi terakhir untuk ringkasan di dashboard
    final recentTxs = filteredTxs.take(5).toList();

    return Scaffold(
      body: transactionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Trigger reload
                final activeF = ref.read(transactionProvider.notifier);
                // Provider otomatis reload ketika active foundation diubah/dimuat ulang,
                // tapi kita juga bisa paksa reload dengan memicu loadTransactions.
                final foundationState = ref.read(foundationProvider);
                if (foundationState.activeFoundation != null) {
                  await activeF.loadTransactions(foundationState.activeFoundation!.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ringkasan Keuangan',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A2A25),
                          ),
                        ),
                        SegmentedButton<DashboardFilter>(
                          segments: const [
                            ButtonSegment(
                              value: DashboardFilter.thisMonth,
                              label: Text('Bulan Ini'),
                              icon: Icon(Icons.calendar_today_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: DashboardFilter.allTime,
                              label: Text('Semua Waktu'),
                              icon: Icon(Icons.all_inclusive, size: 16),
                            ),
                          ],
                          selected: {_activeFilter},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _activeFilter = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cards Panel (Responsive Layout)
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Saldo Utama',
                                  amount: netBalance,
                                  color: const Color(0xFF0D5C46),
                                  icon: Icons.account_balance_wallet_outlined,
                                  isHighlight: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Total Pemasukan',
                                  amount: totalIncome,
                                  color: const Color(0xFF1E8267),
                                  icon: Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Total Pengeluaran',
                                  amount: totalExpense,
                                  color: const Color(0xFFE53935),
                                  icon: Icons.trending_down,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFinanceCard(
                                title: 'Saldo Utama',
                                amount: netBalance,
                                color: const Color(0xFF0D5C46),
                                icon: Icons.account_balance_wallet_outlined,
                                isHighlight: true,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFinanceCard(
                                      title: 'Pemasukan',
                                      amount: totalIncome,
                                      color: const Color(0xFF1E8267),
                                      icon: Icons.trending_up,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFinanceCard(
                                      title: 'Pengeluaran',
                                      amount: totalExpense,
                                      color: const Color(0xFFE53935),
                                      icon: Icons.trending_down,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // Chart & Recent Transactions (Responsive Row/Column)
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: FinancialChart(
                                  totalIncome: totalIncome,
                                  totalExpense: totalExpense,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildRecentTransactionsList(recentTxs),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FinancialChart(
                                totalIncome: totalIncome,
                                totalExpense: totalExpense,
                              ),
                              const SizedBox(height: 24),
                              _buildRecentTransactionsList(recentTxs),
                            ],
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFinanceCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool isHighlight = false,
  }) {
    final formatVal = Formatter.formatRupiah(amount);

    return Card(
      elevation: isHighlight ? 4 : 0,
      shadowColor: isHighlight ? color.withAlpha(51) : Colors.transparent,
      color: isHighlight ? color : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isHighlight ? Colors.white.withAlpha(38) : color.withAlpha(26),
              foregroundColor: isHighlight ? Colors.white : color,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isHighlight ? Colors.white70 : const Color(0xFF6B7F79),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatVal,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isHighlight ? Colors.white : const Color(0xFF1A2A25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(List<dynamic> recentTxs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(26), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaksi Terbaru',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A2A25),
            ),
          ),
          const SizedBox(height: 16),
          if (recentTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Belum ada transaksi.',
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else ...[
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentTxs.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.withAlpha(26)),
              itemBuilder: (context, index) {
                final tx = recentTxs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: tx.isIncome ? const Color(0xFF0D5C46).withAlpha(18) : const Color(0xFFE53935).withAlpha(18),
                        foregroundColor: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                        child: Icon(
                          tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description?.isNotEmpty == true ? tx.description! : tx.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2A25),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  Formatter.formatTanggalPendek(tx.transactionDate),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7F79),
                                  ),
                                ),
                                if (tx.projectName != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(26),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx.projectName!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tx.isIncome ? '+' : '-'}${Formatter.formatRupiah(tx.amount)}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tx.isIncome ? const Color(0xFF0D5C46) : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
