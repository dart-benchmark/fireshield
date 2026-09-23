import 'package:flutter_test/flutter_test.dart';
import 'package:fire_audit_demo/core/engine/capa_engine.dart';
import 'package:fire_audit_demo/core/engine/risk_engine.dart';
import 'package:fire_audit_demo/data/checkpoint_model.dart';
import 'package:fire_audit_demo/data/nbc_bis_masterdata.dart';
import 'package:fire_audit_demo/data/occupancy_taxonomy.dart';

void main() {
  final hospital = OccupancyTaxonomy.byKey('hospital')!;
  final office = OccupancyTaxonomy.byKey('office')!;

  Map<String, CheckpointAnswer> answerAll(
    List<Checkpoint> cps,
    Response r,
  ) =>
      {
        for (final c in cps)
          c.id: CheckpointAnswer(checkpointId: c.id, response: r),
      };

  group('masterdata', () {
    test('carries every checkpoint from the Excel master', () {
      expect(nbcCheckpoints.length, 152);
      expect(bisCheckpoints.length, 74);
      expect(allCheckpoints.length, 226);
    });

    test('checkpoint ids are unique', () {
      final ids = allCheckpoints.map((c) => c.id).toSet();
      expect(ids.length, allCheckpoints.length);
    });
  });

  group('taxonomy', () {
    test('every building type maps to a real subdivision', () {
      for (final b in buildingTypes) {
        expect(OccupancyTaxonomy.subdivision(b.subdivision), isNotNull,
            reason: '${b.key} points at missing ${b.subdivision}');
      }
    });

    test('every subdivision maps to a real group', () {
      for (final s in occupancySubdivisions) {
        expect(OccupancyTaxonomy.group(s.groupCode), isNotNull,
            reason: '${s.code} points at missing group ${s.groupCode}');
      }
    });

    test('unknown key returns null rather than a wrong fallback', () {
      expect(OccupancyTaxonomy.byKey('does_not_exist'), isNull);
    });

    test('search finds by label and by authority', () {
      expect(OccupancyTaxonomy.search('hospital'), isNotEmpty);
      expect(OccupancyTaxonomy.search('AERB'), isNotEmpty);
    });
  });

  group('risk engine', () {
    test('all pass scores 100 and is NOC clear', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final a = RiskEngine.assess(
        buildingType: office,
        checkpoints: cps,
        answers: answerAll(cps, Response.yes),
      );

      expect(a.complianceScore, 100);
      expect(a.riskScore, 0);
      expect(a.level, RiskLevel.low);
      expect(a.nocRecommended, isTrue);
    });

    test('all fail scores 0 and is critical', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final a = RiskEngine.assess(
        buildingType: office,
        checkpoints: cps,
        answers: answerAll(cps, Response.no),
      );

      expect(a.complianceScore, 0);
      expect(a.level, RiskLevel.critical);
      expect(a.nocRecommended, isFalse);
    });

    test('N/A is excluded from scoring, not counted as a pass', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final a = RiskEngine.assess(
        buildingType: office,
        checkpoints: cps,
        answers: answerAll(cps, Response.notApplicable),
      );

      // Nothing scored means no score at all, and definitely not a pass.
      expect(a.complianceScore, 0);
      for (final s in a.sections) {
        expect(s.score, isNull);
      }
    });

    test('unanswered checkpoints block NOC', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final answers = answerAll(cps, Response.yes);
      answers.remove(cps.first.id);

      final a = RiskEngine.assess(
        buildingType: office,
        checkpoints: cps,
        answers: answers,
      );

      expect(a.unanswered, 1);
      expect(a.isComplete, isFalse);
      expect(a.nocRecommended, isFalse);
    });

    test('a single critical failure floors the grade at high', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final critical =
          cps.firstWhere((c) => c.severity == Severity.critical);

      final answers = answerAll(cps, Response.yes);
      answers[critical.id] = CheckpointAnswer(
        checkpointId: critical.id,
        response: Response.no,
      );

      final a = RiskEngine.assess(
        buildingType: office,
        checkpoints: cps,
        answers: answers,
      );

      // Compliance is still very high, but the grade must not read Low.
      expect(a.complianceScore, greaterThan(95));
      expect(a.level, RiskLevel.high);
      expect(a.nocRecommended, isFalse);
      expect(a.nocReason, contains('critical'));
    });

    test('critical failures cost more than minor ones', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final critical = cps.firstWhere((c) => c.severity == Severity.critical);
      final minor = cps.firstWhere((c) => c.severity == Severity.minor);

      double scoreWith(Checkpoint failed) {
        final answers = answerAll(cps, Response.yes);
        answers[failed.id] = CheckpointAnswer(
          checkpointId: failed.id,
          response: Response.no,
        );
        return RiskEngine.assess(
          buildingType: office,
          checkpoints: cps,
          answers: answers,
        ).complianceScore;
      }

      expect(scoreWith(critical), lessThan(scoreWith(minor)));
    });

    test('same answers score riskier for a hospital than an office', () {
      final officeCps =
          OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final hospitalCps =
          OccupancyTaxonomy.checkpointsFor(hospital, allCheckpoints);

      final officeRisk = RiskEngine.assess(
        buildingType: office,
        checkpoints: officeCps,
        answers: answerAll(officeCps, Response.no),
      ).riskScore;

      final hospitalRisk = RiskEngine.assess(
        buildingType: hospital,
        checkpoints: hospitalCps,
        answers: answerAll(hospitalCps, Response.no),
      ).riskScore;

      expect(hospitalRisk, greaterThanOrEqualTo(officeRisk));
      expect(OccupancyTaxonomy.hazardFactor(hospital),
          greaterThan(OccupancyTaxonomy.hazardFactor(office)));
    });
  });

  group('capa engine', () {
    test('raises one action per failed checkpoint', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final answers = answerAll(cps, Response.no);
      final failed = RiskEngine.failedCheckpoints(cps, answers);

      final capa = CapaEngine.raiseFrom(
        failed: failed,
        answers: answers,
        buildingType: office,
      );

      expect(capa.length, failed.length);
      expect(capa.every((c) => c.status == CapaStatus.open), isTrue);
    });

    test('due window follows severity', () {
      final raised = DateTime(2026, 1, 1);
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final answers = answerAll(cps, Response.no);

      final capa = CapaEngine.raiseFrom(
        failed: RiskEngine.failedCheckpoints(cps, answers),
        answers: answers,
        buildingType: office,
        raisedOn: raised,
      );

      for (final c in capa) {
        final days = c.dueOn.difference(raised).inDays;
        expect(days, c.severity.capaDueDays,
            reason: '${c.id} (${c.severity.label}) has the wrong window');
      }
    });

    test('escalation rises the longer an action stays overdue', () {
      final raised = DateTime(2026, 1, 1);
      final capa = CapaAction(
        id: 'CAPA-001',
        checkpointId: 'NBC-011',
        title: 'Exit width below minimum',
        finding: 'Corridor narrower than required',
        corrective: 'Widen corridor',
        preventive: 'Add to weekly round',
        severity: Severity.critical,
        category: 'Means of Escape',
        standardRef: 'NBC 2016 Part 4',
        status: CapaStatus.open,
        raisedOn: raised,
        dueOn: raised.add(const Duration(days: 7)),
      );

      expect(capa.escalation(raised), EscalationLevel.none);
      expect(capa.escalation(DateTime(2026, 1, 9)), EscalationLevel.supervisor);
      expect(capa.escalation(DateTime(2026, 1, 14)), EscalationLevel.management);
      expect(capa.escalation(DateTime(2026, 3, 1)), EscalationLevel.authority);
    });

    test('closing an action stops the overdue clock', () {
      final raised = DateTime(2026, 1, 1);
      final late = DateTime(2026, 6, 1);
      final open = CapaAction(
        id: 'CAPA-002',
        checkpointId: 'NBC-020',
        title: 'Alarm panel fault',
        finding: 'Panel showing fault',
        corrective: 'Repair panel',
        preventive: 'Monthly test',
        severity: Severity.critical,
        category: 'Fire Detection & Alarm',
        standardRef: 'NBC 2016 Part 4',
        status: CapaStatus.open,
        raisedOn: raised,
        dueOn: raised.add(const Duration(days: 7)),
      );

      expect(open.isOverdue(late), isTrue);
      expect(open.copyWith(status: CapaStatus.closed).isOverdue(late), isFalse);
      expect(open.copyWith(status: CapaStatus.closed).escalation(late),
          EscalationLevel.none);
    });

    test('closure rate reflects closed actions', () {
      final cps = OccupancyTaxonomy.checkpointsFor(office, allCheckpoints);
      final answers = answerAll(cps, Response.no);
      var capa = CapaEngine.raiseFrom(
        failed: RiskEngine.failedCheckpoints(cps, answers),
        answers: answers,
        buildingType: office,
      );

      expect(CapaEngine.closureRate(capa), 0);
      capa = capa.map((c) => c.copyWith(status: CapaStatus.closed)).toList();
      expect(CapaEngine.closureRate(capa), 1);
    });
  });
}
