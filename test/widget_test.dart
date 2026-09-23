// Smoke test for the app shell.
//
// Replaces the stock Flutter counter template test, which looked for a
// counter this app never had and so always failed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_audit_demo/main.dart';

void main() {
  testWidgets('app boots and reaches the login screen',
      (WidgetTester tester) async {
    // This is a mobile PWA — _MobileFrame renders the child directly below
    // 430px and wraps it in a phone frame above that.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // flutter_test swaps in a placeholder font where every glyph is fontSize
    // wide, so text-heavy rows measure far wider than on a real device and
    // report overflows that do not exist outside the harness. Ignore those,
    // but let every other error fail the test.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed by')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.pumpWidget(const FireAuditDemoApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    // Splash auto-redirects to /login after 3s. Let that timer fire, or the
    // test framework fails the test for leaving it pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // "Sign In" appears twice on this screen — as the heading and the button.
    expect(find.text('Sign In'), findsWidgets);
  });
}
