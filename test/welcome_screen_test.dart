import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_audit_demo/screens/welcome/welcome_screen.dart';

/// Verifies the welcome screen against the live PWA page it was ported from
/// (https://pwaapp-ochre.vercel.app/welcome) — content, tokens and actions.
void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The placeholder test font measures every glyph at fontSize width, so
    // text-heavy rows report overflows that do not happen on a real device.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed by')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pump();
  }

  testWidgets('renders the EY header and hero copy', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('EY'), findsOneWidget);
    expect(find.text('Assurance · Tax · Strategy · Transactions'), findsOneWidget);
    expect(find.text('FireShield AI'), findsOneWidget);
    expect(find.text('by EY'), findsOneWidget);
    expect(find.text('Next-Generation Fire Audit Readiness Platform'),
        findsOneWidget);
  });

  testWidgets('shows all eight standard chips', (tester) async {
    await pumpWelcome(tester);

    for (final s in [
      'NBC 2026',
      'IS 2189',
      'NABH',
      'OISD',
      'PESO',
      'IS 2190',
      'IS 3844',
      'IS 15105',
    ]) {
      expect(find.text(s), findsWidgets, reason: 'missing chip $s');
    }
  });

  testWidgets('shows the welcome card and its three feature tiles',
      (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Welcome to FireShield AI'), findsOneWidget);
    expect(find.text('Digital Audits'), findsOneWidget);
    expect(find.text('Floor-wise & Room-wise'), findsOneWidget);
    expect(find.text('NOC Ready'), findsOneWidget);
    expect(find.text('Regulatory Compliant'), findsOneWidget);
    expect(find.text('Part 4 Compliant'), findsOneWidget);
  });

  testWidgets('shows both actions and the footer', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Take a Tour'), findsOneWidget);
    expect(
      find.text('Powered by EY · Compliant with NBC 2026 · BIS · OISD · PESO'),
      findsOneWidget,
    );
  });

  testWidgets('Take a Tour opens the tour sheet', (tester) async {
    await pumpWelcome(tester);

    // The button sits below the fold at this viewport, so scroll to it first
    // or the tap lands on nothing.
    await tester.ensureVisible(find.text('Take a Tour'));
    await tester.pump();

    // The logo ping animation repeats forever, so the tree never settles —
    // pump fixed durations instead of using pumpAndSettle.
    await tester.tap(find.text('Take a Tour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('How FireShield works'), findsOneWidget);
    expect(find.text('Classify the building'), findsOneWidget);
    expect(find.text('Close the CAPAs'), findsOneWidget);

    await tester.ensureVisible(find.text('Got it'));
    await tester.pump();
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('How FireShield works'), findsNothing);
  });

  testWidgets('uses the EY yellow on the primary action', (tester) async {
    await pumpWelcome(tester);

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Get Started'),
        matching: find.byType(ElevatedButton),
      ),
    );
    final bg = button.style?.backgroundColor?.resolve({});

    expect(bg, EyWelcome.eyYellow);
    expect(EyWelcome.eyYellow, const Color(0xFFFACC15));
    expect(EyWelcome.ink, const Color(0xFF111827));
  });
}
