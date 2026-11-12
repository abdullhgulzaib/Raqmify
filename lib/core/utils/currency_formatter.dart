import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat('#,##0', 'en_US');

  static String format(double amount, {bool isMasked = false, bool showDecimals = true}) {
    if (isMasked) {
      return 'Rs ••••••';
    }
    if (showDecimals && amount % 1 != 0) {
      return 'Rs ${_formatter.format(amount)}';
    }
    return 'Rs ${_compactFormatter.format(amount)}';
  }

  static String formatPlain(double amount) {
    if (amount % 1 != 0) {
      return _formatter.format(amount);
    }
    return _compactFormatter.format(amount);
  }
}
