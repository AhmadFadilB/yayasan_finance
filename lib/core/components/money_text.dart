import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/formatter.dart';
import '../theme/app_theme.dart';

enum MoneyTextStyleType {
  debit,
  credit,
  neutral,
}

class MoneyText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final MoneyTextStyleType styleType;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.amount,
    this.fontSize = 15.0,
    this.fontWeight = FontWeight.w600,
    this.styleType = MoneyTextStyleType.neutral,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String sign = '';

    switch (styleType) {
      case MoneyTextStyleType.debit:
        color = AppTheme.colorSuccess;
        if (showSign && amount > 0) sign = '+ ';
        break;
      case MoneyTextStyleType.credit:
        color = AppTheme.colorError;
        if (showSign && amount > 0) sign = '- ';
        break;
      case MoneyTextStyleType.neutral:
        color = AppTheme.textDark;
        break;
    }

    final formatted = Formatter.formatRupiah(amount);
    // Standard format is "RpXX.XXX.XXX". Let's insert a space after Rp: "Rp XX.XXX.XXX" for premium look
    final prettyFormatted = formatted.startsWith('Rp') 
        ? 'Rp ${formatted.substring(2)}' 
        : formatted;

    return Text(
      '$sign$prettyFormatted',
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFeatures: const [
          FontFeature.tabularFigures(),
        ],
      ),
    );
  }
}
