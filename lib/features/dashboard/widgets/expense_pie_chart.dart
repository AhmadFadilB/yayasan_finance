import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
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
    Color(0xFF0D5C46), // Primary Emerald
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFFFBC02D), // Yellow
    Color(0xFF8E24AA), // Purple
    Color(0xFFF57C00), // Orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFF43A047), // Green
    Color(0xFFD81B60), // Pink
    Color(0xFF5D4037), // Brown
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
            'Analisis Kategori Pengeluaran',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A2A25),
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
                              centerSpaceRadius: 45,
                              sections: List.generate(sortedCategories.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final entry = sortedCategories[i];
                                final percentage = (entry.value / totalExpense) * 100;
                                final color = _palette[i % _palette.length];
                                final radius = isTouched ? 25.0 : 18.0;

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
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: const Color(0xFF1A2A25),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% (${Formatter.formatRupiah(entry.value)})',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7F79),
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
