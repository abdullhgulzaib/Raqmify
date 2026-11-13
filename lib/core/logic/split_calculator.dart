import 'money.dart';

class SplitCalculationException implements Exception {
  final String message;
  const SplitCalculationException(this.message);

  @override
  String toString() => message;
}

/// Pure Dart Split Calculator providing exact integer-paisa division.
/// Eliminates rounding drift and guarantees sum of splits matches total.
class SplitCalculator {
  /// Equal Split (S7)
  /// base = total ~/ n, remainder = total % n.
  /// First [remainder] participants get 1 extra paisa.
  static Map<String, Money> calculateEqualSplit({
    required Money total,
    required List<String> participantIds,
  }) {
    if (participantIds.isEmpty) return {};
    final n = participantIds.length;
    final totalPaisa = total.paisa;
    final base = totalPaisa ~/ n;
    final remainder = totalPaisa % n;

    final result = <String, Money>{};
    for (var i = 0; i < n; i++) {
      final extra = i < remainder ? 1 : 0;
      result[participantIds[i]] = Money.fromPaisa(base + extra);
    }
    return result;
  }

  /// Percentage Split (S7)
  /// Validates percentages sum to 100 (within 0.01 tolerance).
  /// Floors base amounts, distributes leftover paisa deterministically by largest share.
  static Map<String, Money> calculatePercentageSplit({
    required Money total,
    required Map<String, double> percentages,
  }) {
    if (percentages.isEmpty) return {};
    final sumPct = percentages.values.fold(0.0, (a, b) => a + b);
    if ((sumPct - 100.0).abs() > 0.01) {
      throw SplitCalculationException(
        'Percentages must sum to 100% (currently ${sumPct.toStringAsFixed(1)}%)',
      );
    }

    final totalPaisa = total.paisa;
    final allocated = <String, int>{};
    var currentSum = 0;

    for (final entry in percentages.entries) {
      final sharePaisa = ((totalPaisa * entry.value) / 100.0).floor();
      allocated[entry.key] = sharePaisa;
      currentSum += sharePaisa;
    }

    var leftover = totalPaisa - currentSum;
    if (leftover > 0) {
      // Sort deterministically: highest percentage first, then by ID
      final sortedKeys = percentages.keys.toList()
        ..sort((a, b) {
          final comp = percentages[b]!.compareTo(percentages[a]!);
          return comp != 0 ? comp : a.compareTo(b);
        });

      var i = 0;
      while (leftover > 0 && i < sortedKeys.length) {
        final key = sortedKeys[i];
        allocated[key] = (allocated[key] ?? 0) + 1;
        leftover--;
        i++;
      }
    }

    return allocated.map((k, v) => MapEntry(k, Money.fromPaisa(v)));
  }

  /// Custom Split (S7)
  /// Payer share = total - sum(other shares).
  /// If other shares exceed total, throws SplitCalculationException with an inline friendly message.
  static Map<String, Money> calculateCustomSplit({
    required Money total,
    required String payerId,
    required Map<String, Money> nonPayerShares,
  }) {
    var othersTotalPaisa = 0;
    for (final share in nonPayerShares.values) {
      othersTotalPaisa += share.paisa;
    }

    if (othersTotalPaisa > total.paisa) {
      final excess = Money.fromPaisa(othersTotalPaisa - total.paisa);
      throw SplitCalculationException(
        'Participant shares exceed total by ${excess.format()}',
      );
    }

    final payerRemaining = Money.fromPaisa(total.paisa - othersTotalPaisa);
    return {
      payerId: payerRemaining,
      ...nonPayerShares,
    };
  }
}
