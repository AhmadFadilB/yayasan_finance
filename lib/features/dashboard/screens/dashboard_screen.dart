import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../../core/components/money_text.dart';
import '../../foundations/providers/foundation_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../widgets/financial_chart.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/yearly_trend_chart.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 36.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Bar
                    isDesktop
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ringkasan Keuangan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
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
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ringkasan Keuangan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<DashboardFilter>(
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
                              ),
                            ],
                          ),
                    const SizedBox(height: 48),

                    // Cards Panel (Responsive Layout)
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Saldo Utama',
                                  amount: netBalance,
                                  color: AppTheme.primaryColor,
                                  icon: Icons.account_balance_wallet_outlined,
                                  isHighlight: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Total Debit (Masuk)',
                                  amount: totalIncome,
                                  color: AppTheme.colorSuccess,
                                  icon: Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Total Kredit (Keluar)',
                                  amount: totalExpense,
                                  color: AppTheme.colorError,
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
                                color: AppTheme.primaryColor,
                                icon: Icons.account_balance_wallet_outlined,
                                isHighlight: true,
                              ),
                              const SizedBox(height: 24),
                              _buildFinanceCard(
                                title: 'Total Debit (Masuk)',
                                amount: totalIncome,
                                color: AppTheme.colorSuccess,
                                icon: Icons.trending_up,
                              ),
                              const SizedBox(height: 24),
                              _buildFinanceCard(
                                title: 'Total Kredit (Keluar)',
                                amount: totalExpense,
                                color: AppTheme.colorError,
                                icon: Icons.trending_down,
                              ),
                            ],
                          ),
                    const SizedBox(height: 48),

                    // Chart, Pie Chart & Yearly Trend Grid (Responsive Layout)
                    isDesktop
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
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
                                    child: ExpensePieChart(
                                      transactions: transactionState.transactions,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: YearlyTrendChart(
                                      transactions: transactionState.transactions,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildRecentTransactionsList(recentTxs),
                                  ),
                                ],
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
                              const SizedBox(height: 48),
                              ExpensePieChart(
                                transactions: transactionState.transactions,
                              ),
                              const SizedBox(height: 48),
                              YearlyTrendChart(
                                transactions: transactionState.transactions,
                              ),
                              const SizedBox(height: 48),
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
    if (isHighlight) {
      // Hero Card: Saldo Utama (Dark background #0B1F16, Amber badge icon)
      return Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor, // Dark #0B1F16
          borderRadius: AppRadius.radiusMd,
          boxShadow: UIConstants.shadowSoft,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor, // Amber gold badge
                borderRadius: AppRadius.radiusBadge,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MoneyText(
                      amount: amount,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      customColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Standard Metric Card (Total Debit / Total Kredit)
    final isDebit = title.contains('Debit');
    final badgeBgColor = isDebit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final badgeIconColor = isDebit ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final badgeIcon = isDebit ? Icons.north_east_rounded : Icons.south_west_rounded;

    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusMd,
        boxShadow: UIConstants.shadowSoft,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: AppRadius.radiusBadge,
            ),
            child: Center(
              child: Icon(
                badgeIcon,
                color: badgeIconColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MoneyText(
                    amount: amount,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    styleType: isDebit ? MoneyTextStyleType.debit : MoneyTextStyleType.credit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(List<dynamic> recentTxs) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaksi Terbaru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (recentTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Belum ada transaksi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
                ),
              ),
            )
          else ...[
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recentTxs.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFEBEBEB), height: 1),
              itemBuilder: (context, index) {
                final tx = recentTxs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: tx.isIncome 
                            ? AppTheme.colorSuccess.withAlpha(26) 
                            : AppTheme.colorError.withAlpha(26),
                        foregroundColor: tx.isIncome 
                            ? AppTheme.colorSuccess 
                            : AppTheme.colorError,
                        child: Icon(
                          tx.isIncome ? Icons.account_balance_wallet_rounded : Icons.receipt_long_rounded,
                          size: 18,
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  Formatter.formatTanggalPendek(tx.transactionDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (tx.projectName != null)
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 100),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor.withAlpha(26),
                                      borderRadius: AppRadius.radiusPill,
                                    ),
                                    child: Text(
                                      tx.projectName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: AppTheme.secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: tx.amount,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        styleType: tx.isIncome ? MoneyTextStyleType.debit : MoneyTextStyleType.credit,
                        showSign: true,
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
