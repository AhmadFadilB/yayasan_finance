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
                padding: const EdgeInsets.all(24.0),
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
                                style: Theme.of(context).textTheme.headlineMedium,
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
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 12),
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
                                  title: 'Total Debit (Masuk)',
                                  amount: totalIncome,
                                  color: const Color(0xFF1E8267),
                                  icon: Icons.trending_up,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildFinanceCard(
                                  title: 'Total Kredit (Keluar)',
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
                              _buildFinanceCard(
                                title: 'Total Debit (Masuk)',
                                amount: totalIncome,
                                color: const Color(0xFF1E8267),
                                icon: Icons.trending_up,
                              ),
                              const SizedBox(height: 16),
                              _buildFinanceCard(
                                title: 'Total Kredit (Keluar)',
                                amount: totalExpense,
                                color: const Color(0xFFE53935),
                                icon: Icons.trending_down,
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),

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
                              const SizedBox(height: 24),
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
                              const SizedBox(height: 24),
                              ExpensePieChart(
                                transactions: transactionState.transactions,
                              ),
                              const SizedBox(height: 24),
                              YearlyTrendChart(
                                transactions: transactionState.transactions,
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
    return AppCard(
      color: isHighlight ? AppTheme.primaryColor : Colors.white,
      hasBorder: !isHighlight,
      hasShadow: isHighlight,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isHighlight ? Colors.white70 : AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isHighlight 
                      ? Text(
                          Formatter.formatRupiah(amount).replaceAll('Rp', 'Rp '),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        )
                      : MoneyText(
                          amount: amount,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          styleType: title.contains('Debit') 
                              ? MoneyTextStyleType.debit 
                              : (title.contains('Kredit') ? MoneyTextStyleType.credit : MoneyTextStyleType.neutral),
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
            style: Theme.of(context).textTheme.titleLarge,
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
