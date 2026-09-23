import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_audit_demo/fireshield/data/fs_mock_data.dart';
import 'package:fire_audit_demo/fireshield/data/fs_models.dart';
import 'package:fire_audit_demo/fireshield/fs_app_state.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_login_screen.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_tour_screen.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_welcome_screen.dart';
import 'package:fire_audit_demo/fireshield/theme/fs_tokens.dart';
import 'package:fire_audit_demo/fireshield/widgets/fs_bottom_nav.dart';
import 'package:fire_audit_demo/fireshield/widgets/fs_ui.dart';

/// Verifies the Flutter port against the PWA it was ported from.
void main() {
  /// flutter_test's placeholder font measures every glyph at fontSize width,
  /// so text-heavy rows report overflows that do not occur on a real device.
  void ignoreOverflow() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed by')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    ignoreOverflow();
    await tester.pumpWidget(MaterialApp(
      theme: buildFireShieldTheme(),
      home: child,
    ));
    await tester.pump();
  }

  group('design tokens', () {
    test('match tailwind.config.js', () {
      expect(FsColors.primary, const Color(0xFFD32F2F));
      expect(FsColors.primaryDark, const Color(0xFFB71C1C));
      expect(FsColors.eyYellow, const Color(0xFFFFE600));
      expect(FsColors.success, const Color(0xFF2E7D32));
      expect(FsColors.warning, const Color(0xFFF57F17));
      expect(FsColors.danger, const Color(0xFFC62828));
      expect(FsColors.info, const Color(0xFF01579B));
      expect(FsColors.bg, const Color(0xFFF5F6FA));
      expect(FsColors.border, const Color(0xFFE5E7EB));
      expect(FsColors.muted, const Color(0xFF6B7280));
      expect(FsColors.subtle, const Color(0xFF9CA3AF));
    });

    test('radii match the tailwind scale', () {
      expect(FsRadius.xl2, 16.0);
      expect(FsRadius.xl3, 24.0);
      expect(FsRadius.xl4, 32.0);
    });
  });

  group('models and repository', () {
    test('demo users cover all four PWA roles', () {
      expect(demoUsers.length, 4);
      expect(
        demoUsers.map((u) => u.role).toSet(),
        {FsRole.admin, FsRole.manager, FsRole.auditor, FsRole.orgadmin},
      );
    });

    test('role keys match the PWA route segments', () {
      expect(FsRole.admin.key, 'admin');
      expect(FsRole.orgadmin.key, 'orgadmin');
      expect(FsRole.manager.key, 'manager');
      expect(FsRole.auditor.key, 'auditor');
      expect(FsRoleInfo.fromKey('orgadmin'), FsRole.orgadmin);
      // Unknown keys must not crash — the PWA defaults to auditor tabs.
      expect(FsRoleInfo.fromKey('nonsense'), FsRole.auditor);
    });

    test('user survives a json round trip', () {
      final u = demoUsers.first;
      final back = FsUser.fromJson(u.toJson());
      expect(back.id, u.id);
      expect(back.role, u.role);
      expect(back.email, u.email);
    });

    test('audit progress is derived from done/total', () {
      final a = allOrgAudits.firstWhere((x) => x.id == 'A001');
      expect(a.total, 148);
      expect(a.done, 64);
      expect(a.progress, closeTo(43.24, 0.01));
    });

    test('signIn resolves a known email and rejects an unknown one', () async {
      final ok = await FsRepository.instance
          .signIn(email: 'priya@phoenix.com', password: 'demo123');
      expect(ok, isNotNull);
      expect(ok!.role, FsRole.manager);

      final bad = await FsRepository.instance
          .signIn(email: 'nobody@nowhere.com', password: 'x');
      expect(bad, isNull);
    });

    test('facilities filter by organisation', () async {
      final all = await FsRepository.instance.fetchFacilities();
      final phoenix =
          await FsRepository.instance.fetchFacilities(org: 'Phoenix Group');
      expect(phoenix.length, lessThan(all.length));
      expect(phoenix.every((f) => f.org == 'Phoenix Group'), isTrue);
    });
  });

  group('app state', () {
    tearDown(FsAppState.instance.logout);

    test('login sets the role home route', () {
      final state = FsAppState.instance;
      expect(state.isAuthenticated, isFalse);
      expect(state.homeRoute, '/login');

      state.login(demoUsers.firstWhere((u) => u.role == FsRole.manager));
      expect(state.isAuthenticated, isTrue);
      expect(state.homeRoute, '/manager');

      state.logout();
      expect(state.isAuthenticated, isFalse);
    });
  });

  group('bottom nav', () {
    test('every role has five tabs, matching the PWA', () {
      for (final entry in fsNavTabs.entries) {
        expect(entry.value.length, 5, reason: '${entry.key} tab count');
      }
      expect(fsNavTabs[FsRole.manager]!.map((t) => t.label).toList(),
          ['Dashboard', 'Audits', 'Reference', 'Reports', 'Profile']);
      expect(fsNavTabs[FsRole.orgadmin]!.map((t) => t.path).toList(), [
        '/orgadmin',
        '/orgadmin/facilities',
        '/orgadmin/team',
        '/orgadmin/audits',
        '/profile',
      ]);
    });
  });

  group('ui components', () {
    testWidgets('StatusBadge maps PWA statuses to labels', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: Column(
            children: [
              StatusBadge(status: 'IN_PROGRESS'),
              StatusBadge(status: 'Valid'),
              StatusBadge(status: 'OVERDUE'),
              StatusBadge(status: 'WEIRD_UNKNOWN'),
            ],
          ),
        ),
      );

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('NOC Valid'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      // Unknown statuses fall through to the raw value, as in the PWA.
      expect(find.text('WEIRD_UNKNOWN'), findsOneWidget);
    });

    testWidgets('ScoreRing colours by band', (tester) async {
      expect(ScoreRing.colorFor(85), FsColors.success);
      expect(ScoreRing.colorFor(65), FsColors.warning);
      expect(ScoreRing.colorFor(40), FsColors.danger);

      await pump(tester, const Scaffold(body: ScoreRing(score: 88)));
      expect(find.text('88%'), findsOneWidget);
    });

    testWidgets('KpiCard renders value, label and sub', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: KpiCard(
            icon: '📋',
            label: 'Open Audits',
            value: '12',
            sub: '+3 this week',
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Open Audits'), findsOneWidget);
      expect(find.text('+3 this week'), findsOneWidget);
    });

    testWidgets('EmptyState renders its copy', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: EmptyState(
            icon: '📭',
            title: 'Nothing here',
            subtitle: 'Try another filter',
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Try another filter'), findsOneWidget);
    });
  });

  group('welcome screen', () {
    testWidgets('renders hero, chips, card and actions', (tester) async {
      await pump(tester, const FsWelcomeScreen());

      expect(find.text('FireShield AI'), findsOneWidget);
      expect(find.text('by EY'), findsOneWidget);
      expect(find.text('Welcome to FireShield AI'), findsOneWidget);
      for (final s in ['NBC 2026', 'IS 2189', 'NABH', 'OISD', 'PESO']) {
        expect(find.text(s), findsWidgets, reason: 'chip $s');
      }
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Take a Tour'), findsOneWidget);
    });
  });

  group('login screen', () {
    testWidgets('quick login lists all four demo roles', (tester) async {
      await pump(tester, const FsLoginScreen());

      expect(find.text('Arjun Mehta'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('DEMO'), findsNWidgets(4));
      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.text('Field Auditor'), findsOneWidget);
    });

    testWidgets('switching to email mode swaps the form in', (tester) async {
      await pump(tester, const FsLoginScreen());

      expect(find.text('Email Address'), findsNothing);

      await tester.tap(find.text('✉️ Email Login'));
      await tester.pump();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Arjun Mehta'), findsNothing);
    });

    testWidgets('empty submit shows a validation error', (tester) async {
      await pump(tester, const FsLoginScreen());
      await tester.tap(find.text('✉️ Email Login'));
      await tester.pump();

      await tester.ensureVisible(find.text('Sign In'));
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter email and password'), findsOneWidget);
    });
  });

  group('tour screen', () {
    test('three role tours, three slides each', () {
      expect(tours.length, 3);
      expect(tours.map((t) => t.key).toList(), ['admin', 'manager', 'auditor']);
      for (final t in tours) {
        expect(t.slides.length, 3, reason: '${t.key} slide count');
      }
    });

    testWidgets('picker lists roles and opens a tour', (tester) async {
      await pump(tester, const FsTourScreen());

      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.text('Safety Manager'), findsOneWidget);
      expect(find.text('Field Auditor'), findsOneWidget);

      await tester.tap(find.text('Safety Manager'));
      await tester.pump();

      expect(find.text('Manage Facilities'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('advancing reaches the final slide', (tester) async {
      await pump(tester, const FsTourScreen());
      await tester.tap(find.text('Field Auditor'));
      await tester.pump();

      expect(find.text('Conduct Audits'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Collect Evidence'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Generate Reports'), findsOneWidget);
      // Last slide swaps the CTA.
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });
}
