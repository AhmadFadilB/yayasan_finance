import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../transactions/models/transaction_model.dart';

class ExpensePieChart extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ExpensePieChart({
    super.key,
    required this.transactions,
  });

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  final List<Color> _palette = const [
    AppTheme.primaryColor,       // Dark #0B1F16
    AppTheme.secondaryColor,     // Amber Gold #C9972B
    AppTheme.chartSuccessMuted,  // Muted Forest #265835
    AppTheme.chartErrorMuted,    // Muted Brick #7A2E29
    Color(0xFF3B4A54),           // Slate Gray
    Color(0xFF5C6B73),           // Muted Pewter
    Color(0xFF4A3E56),           // Muted Eggplant
    Color(0xFF6B5B45),           // Muted Bronze
    Color(0xFF2C4C5E),           // Muted Deep Blue
    Color(0xFF475569),           // Muted Charcoal
  ];

  @override
  Widget build(BuildContext context) {
    // Ambil transaksi pengeluaran yang disetujui saja
    final expenses = widget.transactions
        .where((tx) => !tx.isIncome && tx.status == 'approved')
        .toList();

    // Hitung total pengeluaran
    double totalExpense = 0;
    final Map<String, double> categoryMap = {};

    for (var tx in expenses) {
      totalExpense += tx.amount;
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }

    // Urutkan kategori berdasarkan pengeluaran terbesar
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Kategori Pengeluaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          totalExpense == 0
              ? SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Tidak ada data pengeluaran untuk ditampilkan.',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // Doughnut Chart
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 0,
                              sections: List.generate(sortedCategories.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final entry = sortedCategories[i];
                                final percentage = (entry.value / totalExpense) * 100;
                                final color = _palette[i % _palette.length];
                                final radius = isTouched ? 85.0 : 75.0;

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  radius: radius,
                                  title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                                  titleStyle: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Legend List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, i) {
                            final entry = sortedCategories[i];
                            final percentage = (entry.value / totalExpense) * 100;
                            final color = _palette[i % _palette.length];
                            final isSelected = i == _touchedIndex;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withAlpha(20)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% (${Formatter.formatRupiah(entry.value)})',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }
}
