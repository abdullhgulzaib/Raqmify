import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import 'currency_formatter.dart';

class PdfStatementGenerator {
  static Future<Uint8List> generateMonthlyStatement({
    required String userName,
    required String userEmail,
    required List<ExpenseModel> expenses,
    required String periodName,
  }) async {
    final pdf = pw.Document();

    final totalSpend = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final now = DateTime.now();
    final dailyAvg = totalSpend / (now.day > 0 ? now.day : 1);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Raqmify',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0B3D34'),
                          ),
                        ),
                        pw.Text(
                          'Your money, your control.',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColor.fromHex('#6B7280'),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'MONTHLY STATEMENT',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0B3D34'),
                          ),
                        ),
                        pw.Text(
                          periodName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColor.fromHex('#101817'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColor.fromHex('#0B3D34'), thickness: 1.5),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Account Holder: $userName',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.SizedBox(height: 3),
                        pw.Text('Email: $userEmail',
                            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Generated On: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5F2'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total Spend: ${CurrencyFormatter.format(totalSpend)}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#0B3D34'),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Daily Average: ${CurrencyFormatter.format(dailyAvg)}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Transactions: ${expenses.length}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],
            );
          } else {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Raqmify - $periodName',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Account: $userName',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            );
          }
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Notice: Raqmify retention stores active records for 60 days before archiving.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Text(
            'Itemized Transaction Log (${expenses.length} Records)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0B3D34'),
            ),
          ),
          pw.SizedBox(height: 8),
          if (expenses.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 24),
              child: pw.Center(
                child: pw.Text(
                  'No transactions found for this period.',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 0.6),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0B3D34'),
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F7F8F6')),
              cellHeight: 22,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              headers: ['Date', 'Title', 'Category', 'Method', 'Amount'],
              data: expenses.map((e) {
                return [
                  DateFormat('dd/MM/yyyy').format(e.date),
                  e.title,
                  e.category,
                  e.paymentMethod,
                  CurrencyFormatter.format(e.amount),
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShareStatement({
    required String userName,
    required String userEmail,
    required List<ExpenseModel> expenses,
    required String periodName,
  }) async {
    final pdfBytes = await generateMonthlyStatement(
      userName: userName,
      userEmail: userEmail,
      expenses: expenses,
      periodName: periodName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Raqmify_Statement_${periodName.replaceAll(' ', '_')}.pdf',
    );
  }
}
