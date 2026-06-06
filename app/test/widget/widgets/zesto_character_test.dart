import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/presentation/widgets/zesto_character.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('renders every expression without error', (tester) async {
    for (final e in ZestoExpression.values) {
      await tester.pumpWidget(
        host(ZestoCharacter(expression: e, animate: false)),
      );
      expect(find.byType(ZestoCharacter), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('exposes a semantic label', (tester) async {
    await tester.pumpWidget(
      host(const ZestoCharacter(animate: false, semanticLabel: 'Zesto')),
    );
    expect(find.bySemanticsLabel('Zesto'), findsOneWidget);
  });

  testWidgets('animate:false renders a static pose (no running animation)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const ZestoCharacter(expression: ZestoExpression.wave, animate: false),
      ),
    );
    // Would time out if a controller were repeating.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('animate:true drives an ongoing animation', (tester) async {
    await tester.pumpWidget(host(const ZestoCharacter(animate: true)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('toggling animate true -> false stops the animation', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ZestoCharacter(animate: true)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(host(const ZestoCharacter(animate: false)));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
