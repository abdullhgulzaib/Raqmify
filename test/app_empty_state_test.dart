import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raqmify/core/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState displays icon, title, message and optional action (C2, F5)', (tester) async {
    var actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'You are all settled',
            message: 'No outstanding balances in your groups.',
            actionLabel: 'Refresh',
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('You are all settled'), findsOneWidget);
    expect(find.text('No outstanding balances in your groups.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    expect(actionCalled, isTrue);
  });
}
