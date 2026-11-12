import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/main.dart';

void main() {
  testWidgets('Raqmify app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RaqmifyApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(RaqmifyApp), findsOneWidget);
  });
}
