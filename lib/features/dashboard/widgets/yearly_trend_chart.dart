import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_card.dart';
import '../../transactions/models/transaction_model.dart';

class YearlyTrendChart extends StatefulWidget {
  final List<TransactionModel> transactions;

  const YearlyTrendChart({
    super.key,
    required this.transactions,
  });

  @override
  State<YearlyTrendChart> createState() => _YearlyTrendChartState();
}

class _YearlyTrendChartState extends State<YearlyTrendChart> {
  late int _selectedYear;
  late List<int> _availableYears;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    
    // Cari tahun-tahun yang tersedia dari riwayat transaksi
    final years = widget.transactions
        .map((tx) => tx.transactionDate.year)
        .toSet()
        .toList();
        
    if (!years.contains(currentYear)) {
      years.add(currentYear);
    }
    years.sort((a, b) => b.compareTo(a)); // Urutkan tahun terbaru di atas
    
    _availableYears = years;
    _selectedYear = currentYear;
  }

  @override
  Widget build(BuildContext context) {
    // Siapkan array data bulanan (1 - 12)
    final List<double> monthlyIncome = List.filled(12, 0.0);
    final List<double> monthlyExpense = List.filled(12, 0.0);

    // Filter transaksi untuk tahun terpilih dan status approved
    final yearTransactions = widget.transactions.where((tx) =>
        tx.transactionDate.year == _selectedYear && tx.status == 'approved');

    for (var tx in yearTransactions) {
      final monthIndex = tx.transactionDate.month - 1; // 0-indexed (Jan = 0)
      if (monthIndex >= 0 && monthIndex < 12) {
        if (tx.isIncome) {
          monthlyIncome[monthIndex] += tx.amount;
        } else {
          monthlyExpense[monthIndex] += tx.amount;
        }
      }
    }

    // Cari nilai tertinggi untuk batas maxY grafik
    double maxVal = 100000; // default min limit
    for (int i = 0; i < 12; i++) {
      if (monthlyIncome[i] > maxVal) maxVal = monthlyIncome[i];
      if (monthlyExpense[i] > maxVal) maxVal = monthlyExpense[i];
    }
    final double yInterval = maxVal > 0 ? (maxVal / 5) : 100000;

    final monthLabels = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Keuangan Bulanan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox(),
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                items: _availableYears.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text('Tahun $year'),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _selectedYear = year;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Debit', AppTheme.colorSuccess),
              const SizedBox(width: 16),
              _buildLegendItem('Kredit', AppTheme.colorError),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 12) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              monthLabels[idx],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 75,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          Formatter.formatRupiah(value),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: maxVal * 1.15,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A2A25),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isIncome ? 'Debit' : 'Kredit'}\n${Formatter.formatRupiah(spot.y)}',
                          GoogleFonts.inter(
                            color: isIncome ? AppTheme.colorSuccess : AppTheme.colorError,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Line Pemasukan (Green)
                  LineChartBarData(
                    spots: List.generate(12, (i) => FlSpot(i.toDouble(), monthlyIncome[i])),
                    isCurved: false,
                    color: AppTheme.colorSuccess,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AppTheme.colorSuccess,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.colorSuccess.withAlpha(20),
                    ),
                  ),
                  // Line Pengeluaran (Red)
                  LineChartBarData(
                    spots: List.generate(12, (i) => FlSpot(i.toDouble(), monthlyExpense[i])),
                    isCurved: false,
                    color: AppTheme.colorError,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: AppTheme.colorError,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.colorError.withAlpha(15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
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
