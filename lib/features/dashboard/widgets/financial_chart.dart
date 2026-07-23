import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';

class FinancialChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const FinancialChart({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = totalIncome > totalExpense ? totalIncome : totalExpense;
    // Tentukan interval sumbu Y agar tidak bertumpuk
    final double yInterval = maxVal > 0 ? (maxVal / 3) : 100000;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 450;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Perbandingan Keuangan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLegendItem(context, 'Debit', AppTheme.colorSuccess),
                            const SizedBox(width: 12),
                            _buildLegendItem(context, 'Kredit', AppTheme.colorError),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Perbandingan Keuangan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        // Legenda
                        Row(
                          children: [
                            _buildLegendItem(context, 'Debit', AppTheme.colorSuccess),
                            const SizedBox(width: 12),
                            _buildLegendItem(context, 'Kredit', AppTheme.colorError),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: totalIncome == 0 && totalExpense == 0
                ? Center(
                    child: Text(
                      'Tidak ada data transaksi untuk ditampilkan.',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: maxVal * 1.15, // Beri sedikit padding di atas
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF1A2A25),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final String label = groupIndex == 0 ? 'Debit' : 'Kredit';
                            return BarTooltipItem(
                              '$label\n${Formatter.formatRupiah(rod.toY)}',
                              GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              String text = '';
                              if (value == 0) text = 'Pemasukan';
                              if (value == 1) text = 'Pengeluaran';
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                  child: Text(
                                    text,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 80,
                            interval: yInterval,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                Formatter.formatRupiah(value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withAlpha(12),
                          strokeWidth: 0.8,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: totalIncome,
                              color: AppTheme.chartSuccessMuted,
                              width: 32,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalExpense,
                              color: AppTheme.chartErrorMuted,
                              width: 32,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
