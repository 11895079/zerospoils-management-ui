library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/widgets/beta_feedback_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: child,
      ),
    );

void main() {
  group('BetaFeedbackButton', () {
    testWidgets('renders FAB when isActive is true', (tester) async {
      await tester.pumpWidget(_wrap(const BetaFeedbackButton(isActive: true)));
      await tester.pump();

      expect(
        find.byKey(const Key('beta_feedback_fab')),
        findsOneWidget,
        reason: 'FAB should be visible in beta builds',
      );
      expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
    });

    testWidgets('renders nothing when isActive is false', (tester) async {
      await tester.pumpWidget(
        _wrap(const BetaFeedbackButton(isActive: false)),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('beta_feedback_fab')),
        findsNothing,
        reason: 'FAB must be absent from production builds',
      );
    });

    testWidgets('has correct tooltip and icon in active state', (tester) async {
      await tester.pumpWidget(_wrap(const BetaFeedbackButton(isActive: true)));
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byKey(const Key('beta_feedback_fab')),
      );
      expect(fab.tooltip, 'Beta Feedback');
    });
  });
}
