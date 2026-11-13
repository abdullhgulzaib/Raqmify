import 'package:intl/intl.dart';

/// Pure Dart Money value type representing currency in integer paisa (1 Rupee = 100 Paisa).
/// Prevents all floating-point rounding errors and fractional rupee drift.
class Money implements Comparable<Money> {
  final int paisa;

  const Money.fromPaisa(this.paisa);

  factory Money.fromRupees(num rupees) {
    return Money.fromPaisa((rupees * 100).round());
  }

  factory Money.zero() => const Money.fromPaisa(0);

  factory Money.parse(dynamic value) {
    if (value == null) return Money.zero();
    if (value is Money) return value;
    if (value is int) {
      // Backend amounts coming from JSON as integers (e.g. 150) are in rupees
      return Money.fromRupees(value);
    }
    if (value is double) {
      return Money.fromRupees(value);
    }
    if (value is String) {
      final sanitized = value.replaceAll(',', '').replaceAll('Rs', '').replaceAll('PKR', '').trim();
      final parsed = double.tryParse(sanitized);
      if (parsed != null) {
        return Money.fromRupees(parsed);
      }
    }
    return Money.zero();
  }

  double get inRupees => paisa / 100.0;
  int get rupeePart => (paisa.abs() ~/ 100) * (paisa < 0 ? -1 : 1);
  int get paisaPart => (paisa % 100).abs();
  bool get hasPaisa => paisaPart != 0;
  bool get isZero => paisa == 0;
  bool get isPositive => paisa > 0;
  bool get isNegative => paisa < 0;

  Money operator +(Money other) => Money.fromPaisa(paisa + other.paisa);
  Money operator -(Money other) => Money.fromPaisa(paisa - other.paisa);
  Money operator *(num factor) => Money.fromPaisa((paisa * factor).round());
  Money operator -() => Money.fromPaisa(-paisa);

  bool operator <(Money other) => paisa < other.paisa;
  bool operator <=(Money other) => paisa <= other.paisa;
  bool operator >(Money other) => paisa > other.paisa;
  bool operator >=(Money other) => paisa >= other.paisa;

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paisa == other.paisa;

  @override
  int get hashCode => paisa.hashCode;

  /// Display string: shows 2 decimal places if paisa exists or forceDecimals is true.
  String format({bool showPrefix = true, bool forceDecimals = false}) {
    final absPaisa = paisa.abs();
    final isNeg = paisa < 0;
    final rupees = absPaisa ~/ 100;
    final cents = absPaisa % 100;

    final formatter = NumberFormat('#,##0', 'en_US');
    final formattedRupees = formatter.format(rupees);

    final String amountStr;
    if (hasPaisa || forceDecimals) {
      amountStr = '$formattedRupees.${cents.toString().padLeft(2, '0')}';
    } else {
      amountStr = formattedRupees;
    }

    if (!showPrefix) {
      return isNeg ? '-$amountStr' : amountStr;
    }
    return isNeg ? '-Rs $amountStr' : 'Rs $amountStr';
  }

  /// Compact formatted output: e.g. 1.5K, 2.4M
  String formatCompact({bool showPrefix = true}) {
    final absRupees = inRupees.abs();
    final isNeg = paisa < 0;
    String formatted;
    if (absRupees >= 1000000) {
      formatted = '${(absRupees / 1000000).toStringAsFixed(1)}M';
    } else if (absRupees >= 1000) {
      formatted = '${(absRupees / 1000).toStringAsFixed(1)}K';
    } else {
      return format(showPrefix: showPrefix);
    }
    return showPrefix ? (isNeg ? '-Rs $formatted' : 'Rs $formatted') : (isNeg ? '-$formatted' : formatted);
  }

  /// JSON serialization: sends double rupee value expected by backend
  num toJson() => inRupees;

  @override
  String toString() => format();
}
