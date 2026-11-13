import '../logic/money.dart';

/// Central currency formatter rewritten on top of the Money value type.
/// Guarantees consistent currency representation, paisa precision, and masked privacy support.
class CurrencyFormatter {
  static String format(
    dynamic amount, {
    bool isMasked = false,
    bool showDecimals = false,
  }) {
    if (isMasked) {
      return 'Rs ••••••';
    }
    final money = amount is Money ? amount : Money.parse(amount);
    return money.format(showPrefix: true, forceDecimals: showDecimals);
  }

  static String formatPlain(dynamic amount) {
    final money = amount is Money ? amount : Money.parse(amount);
    return money.format(showPrefix: false);
  }

  static String formatCompact(dynamic amount, {bool isMasked = false}) {
    if (isMasked) {
      return 'Rs ••••••';
    }
    final money = amount is Money ? amount : Money.parse(amount);
    return money.formatCompact(showPrefix: true);
  }
}
