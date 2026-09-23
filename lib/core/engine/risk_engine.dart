/// Risk scoring for a fire safety audit.
///
/// Replaces the old flat yes/answered percentage. Three things changed:
///   1. Failures are weighted by severity — a blocked escape route costs more
///      than a missing logbook entry.
///   2. N/A and unanswered are excluded from the denominator instead of
///      being counted as passes.
///   3. A failed critical checkpoint caps the grade regardless of the score,
///      so a building cannot pass on volume of minor compliance.
library;

import '../../data/checkpoint_model.dart';
import '../../data/occupancy_taxonomy.dart';

enum RiskLevel { low, moderate, high, critical }

extension RiskLevelInfo on RiskLevel {
  String get label => switch (this) {
        RiskLevel.low => 'Low',
        RiskLevel.moderate => 'Moderate',
        RiskLevel.high => 'High',
        RiskLevel.critical => 'Critical',
      };

  String get action => switch (this) {
        RiskLevel.low => 'Maintain current controls, re-audit on schedule.',
        RiskLevel.moderate => 'Close open findings before the next cycle.',
        RiskLevel.high => 'Escalate to management, fix critical gaps first.',
        RiskLevel.critical =>
          'Stop-work risk. Notify authority and remediate immediately.',
      };
}

/// Score for one checkpoint category.
class SectionScore {
  final String category;
  final int total;
  final int answered;
  final int passed;
  final int failed;
  final int notApplicable;

  /// Sum of severity weights available in this section.
  final int weightAvailable;

  /// Sum of severity weights earned by passes.
  final int weightEarned;

  /// Failed checkpoints of critical severity.
  final int criticalFailures;

  const SectionScore({
    required this.category,
    required this.total,
    required this.answered,
    required this.passed,
    required this.failed,
    required this.notApplicable,
    required this.weightAvailable,
    required this.weightEarned,
    required this.criticalFailures,
  });

  /// 0–100. Returns null when nothing in the section was answered — that is
  /// different from scoring zero and callers should show it differently.
  double? get score =>
      weightAvailable == 0 ? null : (weightEarned / weightAvailable) * 100;

  double get completion => total == 0 ? 0 : (answered + notApplicable) / total;

  bool get isComplete => answered + notApplicable >= total;
}

/// Whole-audit result.
class RiskAssessment {
  final double complianceScore;
  final double riskScore;
  final RiskLevel level;
  final List<SectionScore> sections;
  final int criticalFailures;
  final int majorFailures;
  final int minorFailures;
  final int unanswered;
  final double hazardFactor;
  final BuildingType buildingType;

  const RiskAssessment({
    required this.complianceScore,
    required this.riskScore,
    required this.level,
    required this.sections,
    required this.criticalFailures,
    required this.majorFailures,
    required this.minorFailures,
    required this.unanswered,
    required this.hazardFactor,
    required this.buildingType,
  });

  int get totalFailures => criticalFailures + majorFailures + minorFailures;

  bool get isComplete => unanswered == 0;

  /// NOC recommendation. Any open critical failure blocks it outright.
  bool get nocRecommended =>
      isComplete && criticalFailures == 0 && complianceScore >= 80;

  String get nocReason {
    if (!isComplete) return '$unanswered checkpoints still unanswered.';
    if (criticalFailures > 0) {
      return '$criticalFailures critical failure(s) must be closed first.';
    }
    if (complianceScore < 80) {
      return 'Compliance ${complianceScore.toStringAsFixed(0)}% is below the 80% threshold.';
    }
    return 'Meets NOC criteria — no critical failures, compliance above 80%.';
  }
}

class RiskEngine {
  const RiskEngine._();

  /// Compliance below this cannot be recommended for NOC.
  static const double nocThreshold = 80;

  static RiskAssessment assess({
    required BuildingType buildingType,
    required List<Checkpoint> checkpoints,
    required Map<String, CheckpointAnswer> answers,
  }) {
    final byCategory = <String, List<Checkpoint>>{};
    for (final c in checkpoints) {
      byCategory.putIfAbsent(c.category, () => []).add(c);
    }

    final sections = <SectionScore>[];
    var criticalFailures = 0;
    var majorFailures = 0;
    var minorFailures = 0;
    var unanswered = 0;
    var totalWeightAvailable = 0;
    var totalWeightEarned = 0;

    for (final entry in byCategory.entries) {
      var passed = 0, failed = 0, na = 0, answered = 0;
      var wAvail = 0, wEarned = 0, critFail = 0;

      for (final c in entry.value) {
        final a = answers[c.id]?.response ?? Response.unanswered;

        switch (a) {
          case Response.notApplicable:
            na++;
          case Response.unanswered:
            unanswered++;
          case Response.yes:
            answered++;
            passed++;
            wAvail += c.severity.weight;
            wEarned += c.severity.weight;
          case Response.no:
            answered++;
            failed++;
            wAvail += c.severity.weight;
            switch (c.severity) {
              case Severity.critical:
                criticalFailures++;
                critFail++;
              case Severity.major:
                majorFailures++;
              case Severity.minor:
                minorFailures++;
            }
        }
      }

      totalWeightAvailable += wAvail;
      totalWeightEarned += wEarned;

      sections.add(SectionScore(
        category: entry.key,
        total: entry.value.length,
        answered: answered,
        passed: passed,
        failed: failed,
        notApplicable: na,
        weightAvailable: wAvail,
        weightEarned: wEarned,
        criticalFailures: critFail,
      ));
    }

    sections.sort((a, b) => a.category.compareTo(b.category));

    final compliance = totalWeightAvailable == 0
        ? 0.0
        : (totalWeightEarned / totalWeightAvailable) * 100;

    final hazard = OccupancyTaxonomy.hazardFactor(buildingType);

    // Residual risk: the compliance gap amplified by how hazardous the
    // occupancy inherently is. Clamped to 100.
    final risk = ((100 - compliance) * hazard).clamp(0.0, 100.0);

    return RiskAssessment(
      complianceScore: compliance,
      riskScore: risk,
      level: _level(risk, criticalFailures),
      sections: sections,
      criticalFailures: criticalFailures,
      majorFailures: majorFailures,
      minorFailures: minorFailures,
      unanswered: unanswered,
      hazardFactor: hazard,
      buildingType: buildingType,
    );
  }

  /// A single critical failure floors the grade at High no matter how good
  /// the arithmetic looks; three or more is Critical on its own.
  static RiskLevel _level(double risk, int criticalFailures) {
    if (criticalFailures >= 3) return RiskLevel.critical;

    final base = switch (risk) {
      < 15 => RiskLevel.low,
      < 35 => RiskLevel.moderate,
      < 60 => RiskLevel.high,
      _ => RiskLevel.critical,
    };

    if (criticalFailures > 0 && base.index < RiskLevel.high.index) {
      return RiskLevel.high;
    }
    return base;
  }

  /// Every failed checkpoint, worst severity first. Feeds the CAPA engine.
  static List<Checkpoint> failedCheckpoints(
    List<Checkpoint> checkpoints,
    Map<String, CheckpointAnswer> answers,
  ) {
    final failed = checkpoints
        .where((c) => answers[c.id]?.response == Response.no)
        .toList();
    failed.sort((a, b) => b.severity.weight.compareTo(a.severity.weight));
    return failed;
  }
}
