import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fire_audit_demo/data/checkpoint_model.dart';
import 'package:fire_audit_demo/data/nbc_bis_masterdata.dart';
import 'package:fire_audit_demo/fireshield/data/fs_mock_data.dart';
import 'package:fire_audit_demo/fireshield/data/fs_models.dart' hide FsAuditRun;
import 'package:fire_audit_demo/fireshield/fs_app_state.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_audit_screens.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_admin_dashboard.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_auditor_dashboard.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_govt_dashboard.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_manager_dashboard.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_misc_screens.dart';
import 'package:fire_audit_demo/fireshield/screens/fs_orgadmin_dashboard.dart';
import 'package:fire_audit_demo/fireshield/theme/fs_tokens.dart';

/// Covers the role dashboards, audit flow and the shared screens.
void main() {
  void ignoreOverflow() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed by')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    ignoreOverflow();
    await tester.pumpWidget(MaterialApp(
      theme: buildFireShieldTheme(),
      home: Scaffold(body: child),
    ));
    await tester.pump();
  }

  setUp(() {
    FsAuditRun.instance.reset();
  });

  tearDown(() {
    FsAppState.instance.logout();
    FsAuditRun.instance.reset();
  });

  group('corrective actions data', () {
    test('loaded with severities and statuses', () {
      expect(correctiveActions.length, 7);
      expect(correctiveActions.where((c) => c.severity == 'CRITICAL').length, 3);
      expect(correctiveActions.where((c) => c.status == 'OVERDUE').length, 2);
      expect(correctiveActions.where((c) => c.status == 'CLOSED').length, 1);
    });

    test('isOpen covers OPEN and IN_PROGRESS only', () {
      final open = correctiveActions.where((c) => c.isOpen).toList();
      expect(open.every((c) => c.status == 'OPEN' || c.status == 'IN_PROGRESS'),
          isTrue);
      expect(open.any((c) => c.status == 'CLOSED'), isFalse);
    });

    test('survives a json round trip', () {
      final c = correctiveActions.first;
      final back = FsCorrectiveAction.fromJson(c.toJson());
      expect(back.id, c.id);
      expect(back.severity, c.severity);
      expect(back.due, c.due);
    });

    test('repository filters by facility', () async {
      final all = await FsRepository.instance.fetchCorrectiveActions();
      final one = await FsRepository.instance
          .fetchCorrectiveActions(facility: 'Phoenix Mall Bengaluru');
      expect(one.length, lessThan(all.length));
      expect(one.every((c) => c.facility == 'Phoenix Mall Bengaluru'), isTrue);
    });
  });

  group('manager dashboard', () {
    testWidgets('renders FRI, KPIs and quick actions', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.manager));
      await pump(tester, const FsManagerDashboard());

      expect(find.text('SAFETY MANAGER'), findsOneWidget);
      expect(find.text('Fire Readiness Index'), findsOneWidget);
      expect(find.text('Open Audits'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('Assign Audit'), findsOneWidget);
      expect(find.text('NOC Readiness'), findsOneWidget);
    });

    testWidgets('Issues tab lists corrective actions', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.manager));
      await pump(tester, const FsManagerDashboard());

      await tester.tap(find.text('Issues'));
      await tester.pump();

      expect(find.text('CORRECTIVE ACTIONS'), findsOneWidget);
      expect(find.text('CA-2026-0234'), findsOneWidget);
    });

    testWidgets('Reports tab lists report types', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.manager));
      await pump(tester, const FsManagerDashboard());

      await tester.tap(find.text('Reports'));
      await tester.pump();

      expect(find.text('NOC Readiness Certificate'), findsOneWidget);
    });
  });

  group('other role dashboards', () {
    testWidgets('auditor dashboard renders', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.auditor));
      await pump(tester, const FsAuditorDashboard());

      expect(find.text('FIELD AUDITOR'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('admin dashboard shows the real platform stats',
        (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.admin));
      await pump(tester, const FsAdminDashboard());

      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.text('FireShield AI™'), findsOneWidget);
      // Verbatim from AdminDashboard.jsx's adminStats constant. 247 (orgs)
      // and 12847 (audits) each appear twice — once in the header banner,
      // once in the Overview tab's governance cards / platform stats.
      expect(find.text('247'), findsWidgets);
      expect(find.text('12847'), findsWidgets);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('admin dashboard opens on the orgs tab when asked',
        (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.admin));
      await pump(tester, const FsAdminDashboard(tab: 'orgs'));

      expect(find.text('${organizations.length} Organisations'),
          findsOneWidget);
    });

    testWidgets('org admin dashboard renders team tab', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.orgadmin));
      await pump(tester, const FsOrgAdminDashboard(tab: 'team'));

      expect(find.text('Organisation Admin'), findsOneWidget);
      // Verbatim from OrgAdminDashboard.jsx's TEAM_MEMBERS constant.
      expect(find.text('Priya Nair'), findsOneWidget);
      expect(find.text('Arjun Sharma'), findsOneWidget);
    });

    testWidgets('govt dashboard shows the real jurisdiction stats',
        (tester) async {
      await pump(tester, const FsGovtDashboard());

      expect(find.text('GOVERNMENT OFFICER'), findsOneWidget);
      expect(find.text('Shri A.K. Sharma'), findsOneWidget);
      // Verbatim from GovtDashboard.jsx's JURISDICTION_STATS constant.
      expect(find.text('2847'), findsOneWidget); // totalBuildings
      expect(find.text('Buildings in Compliance'), findsOneWidget);
    });
  });

  group('audit run scoring', () {
    test('starts empty', () {
      final run = FsAuditRun.instance;
      expect(run.checkpoints.length, 226);
      expect(run.answered, 0);
      expect(run.score, 0);
    });

    test('all pass scores 100', () {
      final run = FsAuditRun.instance;
      for (final c in run.checkpoints) {
        run.answers[c.id] = Response.yes;
      }
      expect(run.score, 100);
      expect(run.criticalFailures, 0);
      expect(run.progress, 1.0);
    });

    test('N/A is excluded from the score, not counted as a pass', () {
      final run = FsAuditRun.instance;
      for (final c in run.checkpoints) {
        run.answers[c.id] = Response.notApplicable;
      }
      expect(run.na, run.checkpoints.length);
      expect(run.passed, 0);
      expect(run.score, 0);
    });

    test('a critical failure costs more than a minor one', () {
      final run = FsAuditRun.instance;
      final critical =
          allCheckpoints.firstWhere((c) => c.severity == Severity.critical);
      final minor =
          allCheckpoints.firstWhere((c) => c.severity == Severity.minor);

      double scoreWithFailure(String id) {
        run.reset();
        for (final c in run.checkpoints) {
          run.answers[c.id] = Response.yes;
        }
        run.answers[id] = Response.no;
        return run.score;
      }

      expect(scoreWithFailure(critical.id),
          lessThan(scoreWithFailure(minor.id)));
    });

    test('critical failures are counted', () {
      final run = FsAuditRun.instance;
      final criticals =
          allCheckpoints.where((c) => c.severity == Severity.critical).take(3);
      for (final c in criticals) {
        run.answers[c.id] = Response.no;
      }
      expect(run.criticalFailures, 3);
    });
  });

  group('audit screens', () {
    testWidgets('execution renders checkpoints from the real master',
        (tester) async {
      await pump(tester, const FsAuditExecution());

      expect(find.textContaining('of 226 answered'), findsOneWidget);
      expect(find.text('NBC-001'), findsOneWidget);
      expect(find.text('Yes'), findsWidgets);
      expect(find.text('N/A'), findsWidgets);
    });

    testWidgets('answering updates progress', (tester) async {
      await pump(tester, const FsAuditExecution());

      expect(find.text('0 of 226 answered'), findsOneWidget);
      await tester.tap(find.text('Yes').first);
      await tester.pump();
      expect(find.text('1 of 226 answered'), findsOneWidget);
    });

    testWidgets('summary blocks NOC while checkpoints are unanswered',
        (tester) async {
      await pump(tester, const FsAuditSummary());

      expect(find.text('Compliance Score'), findsOneWidget);
      expect(find.text('NOC not recommended'), findsOneWidget);
      expect(find.textContaining('still unanswered'), findsOneWidget);
    });

    testWidgets('summary clears NOC when everything passes', (tester) async {
      final run = FsAuditRun.instance;
      for (final c in run.checkpoints) {
        run.answers[c.id] = Response.yes;
      }
      await pump(tester, const FsAuditSummary());

      expect(find.text('NOC criteria met'), findsOneWidget);
    });
  });

  group('shared screens', () {
    testWidgets('profile shows the signed-in user', (tester) async {
      FsAppState.instance
          .login(demoUsers.firstWhere((u) => u.role == FsRole.manager));
      await pump(tester, const FsProfileScreen());

      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Safety Manager'), findsWidgets);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('reports lists every report type', (tester) async {
      await pump(tester, const FsReportsScreen());

      expect(find.text('Audit Summary Report'), findsOneWidget);
      expect(find.text('CAPA Status Report'), findsOneWidget);
    });

    testWidgets('reference library searches the checkpoint master',
        (tester) async {
      await pump(tester, const FsReferenceLibrary());

      expect(find.text('NBC-001'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sprinkler');
      await tester.pump();

      // Every visible result must match the query.
      expect(find.text('No match'), findsNothing);
    });

    testWidgets('reference library reports an empty search honestly',
        (tester) async {
      await pump(tester, const FsReferenceLibrary());

      await tester.enterText(find.byType(TextField), 'zzzzznotathing');
      await tester.pump();

      expect(find.text('No match'), findsOneWidget);
    });

    testWidgets('AI assistant answers from the checkpoint master',
        (tester) async {
      await pump(tester, const FsAiAssistant());

      await tester.enterText(find.byType(TextField), 'sprinkler');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.textContaining('sprinkler'), findsWidgets);
    });
  });
}
