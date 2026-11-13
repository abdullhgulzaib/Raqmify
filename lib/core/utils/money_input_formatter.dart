import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter enforcing at most 2 decimal places, live thousands separators,
/// sensible maximum ceiling, without cursor jumping (U6).
class MoneyInputFormatter extends TextInputFormatter {
  final double maxAmount;
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  MoneyInputFormatter({this.maxAmount = 100000000.0});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Clean input: only digits and a single decimal point
    String text = newValue.text.replaceAll(',', '').replaceAll('Rs', '').trim();
    if (text.startsWith('.')) {
      text = '0$text';
    }

    final parts = text.split('.');
    if (parts.length > 2) {
      // More than one dot: discard
      return oldValue;
    }

    String integerPart = parts[0].replaceAll(RegExp(r'\D'), '');
    String decimalPart = parts.length > 1 ? parts[1].replaceAll(RegExp(r'\D'), '') : '';

    // Enforce at most 2 decimals
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    if (integerPart.isEmpty && decimalPart.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final rawNum = double.tryParse('$integerPart${decimalPart.isNotEmpty ? '.$decimalPart' : ''}') ?? 0.0;
    if (rawNum > maxAmount) {
      return oldValue;
    }

    String formattedInteger = integerPart.isNotEmpty
        ? _formatter.format(int.parse(integerPart))
        : '0';

    String resultText;
    if (parts.length > 1) {
      resultText = '$formattedInteger.$decimalPart';
    } else {
      resultText = formattedInteger;
    }

    // Maintain cursor position relative to end
    int cursorOffset = resultText.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      final charsFromEnd = newValue.text.length - newValue.selection.baseOffset;
      cursorOffset = (resultText.length - charsFromEnd).clamp(0, resultText.length);
    }

    return TextEditingValue(
      text: resultText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  /// Parses sanitized double from formatted string
  static double parseDouble(String text) {
    final clean = text.replaceAll(',', '').replaceAll('Rs', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }
}
