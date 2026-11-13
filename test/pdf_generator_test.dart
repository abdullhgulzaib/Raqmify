import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:raqmify/core/utils/pdf_generator.dart';
import 'package:raqmify/models/expense_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfStatementGenerator generates statement with Urdu title and past-month days (F4)', () async {
    final expenses = [
      ExpenseModel(
        id: 'urdu_1',
        title: 'ہاسٹل کرایہ اور انٹرنیٹ', // Urdu: Hostel rent and internet
        amount: 8500.0,
        category: 'Housing',
        date: DateTime(2026, 10, 15),
        paymentMethod: 'Bank Transfer',
      ),
      ExpenseModel(
        id: 'urdu_2',
        title: 'کھانا اور راشن', // Urdu: Food and ration
        amount: 2540.0,
        category: 'Food',
        date: DateTime(2026, 10, 20),
        paymentMethod: 'Easypaisa',
      ),
    ];

    pw.Font? urduFont;
    final urduFile = File('assets/fonts/NotoSansArabic.ttf');
    if (urduFile.existsSync()) {
      urduFont = pw.Font.ttf(urduFile.readAsBytesSync().buffer.asByteData());
    }

    // Testing a past month (October 2026, which has 31 days)
    final pastMonth = DateTime(2026, 10, 1);
    final pdfBytes = await PdfStatementGenerator.generateMonthlyStatement(
      userName: 'Rana Abdullah',
      userEmail: 'rana@hostel.edu.pk',
      expenses: expenses,
      periodName: 'October 2026',
      statementPeriod: pastMonth,
      customBaseFont: urduFont ?? pw.Font.helvetica(),
      customBoldFont: urduFont ?? pw.Font.helveticaBold(),
      customFontFallback: urduFont != null ? [urduFont] : null,
    );

    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(1000));
    final header = String.fromCharCodes(pdfBytes.take(4));
    expect(header, '%PDF');
  });
}
