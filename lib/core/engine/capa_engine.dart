/// CAPA — Corrective and Preventive Action.
///
/// Every failed checkpoint raises a CAPA. Severity sets the due window
/// (critical 7 days, major 30, minor 90) and the escalation level rises as
/// the due date passes.
library;

import '../../data/checkpoint_model.dart';
import '../../data/occupancy_taxonomy.dart';

enum CapaStatus { open, inProgress, submitted, verified, closed, rejected }

extension CapaStatusInfo on CapaStatus {
  String get label => switch (this) {
        CapaStatus.open => 'Open',
        CapaStatus.inProgress => 'In progress',
        CapaStatus.submitted => 'Submitted for review',
        CapaStatus.verified => 'Verified',
        CapaStatus.closed => 'Closed',
        CapaStatus.rejected => 'Rejected',
      };

  bool get isOpen =>
      this == CapaStatus.open ||
      this == CapaStatus.inProgress ||
      this == CapaStatus.rejected;

  /// Statuses that stop the overdue clock.
  bool get stopsClock =>
      this == CapaStatus.closed ||
      this == CapaStatus.verified ||
      this == CapaStatus.submitted;
}

enum EscalationLevel { none, supervisor, management, authority }

extension EscalationInfo on EscalationLevel {
  String get label => switch (this) {
        EscalationLevel.none => 'On track',
        EscalationLevel.supervisor => 'Supervisor notified',
        EscalationLevel.management => 'Management escalation',
        EscalationLevel.authority => 'Authority notification due',
      };
}

class CapaAction {
  final String id;

  /// Checkpoint this CAPA was raised against.
  final String checkpointId;
  final String title;

  /// What was found — the auditor's remark, or the checkpoint description.
  final String finding;

  /// Corrective action: fix this instance.
  final String corrective;

  /// Preventive action: stop it recurring.
  final String preventive;

  final Severity severity;
  final String category;
  final String standardRef;
  final CapaStatus status;
  final DateTime raisedOn;
  final DateTime dueOn;
  final String owner;
  final List<String> evidenceRefs;

  const CapaAction({
    required this.id,
    required this.checkpointId,
    required this.title,
    required this.finding,
    required this.corrective,
    required this.preventive,
    required this.severity,
    required this.category,
    required this.standardRef,
    required this.status,
    required this.raisedOn,
    required this.dueOn,
    this.owner = 'Unassigned',
    this.evidenceRefs = const [],
  });

  /// Negative once past due.
  int daysRemaining(DateTime now) => dueOn.difference(_dateOnly(now)).inDays;

  bool isOverdue(DateTime now) =>
      !status.stopsClock && daysRemaining(now) < 0;

  int overdueDays(DateTime now) {
    final d = daysRemaining(now);
    return d < 0 ? -d : 0;
  }

  /// Escalation rises with how far past due the action is. Critical items
  /// escalate a step faster because their window is only a week.
  EscalationLevel escalation(DateTime now) {
    if (status.stopsClock) return EscalationLevel.none;
    final over = overdueDays(now);
    if (over <= 0) return EscalationLevel.none;

    final fast = severity == Severity.critical;
    if (over <= (fast ? 2 : 7)) return EscalationLevel.supervisor;
    if (over <= (fast ? 7 : 30)) return EscalationLevel.management;
    return EscalationLevel.authority;
  }

  CapaAction copyWith({
    CapaStatus? status,
    String? owner,
    String? corrective,
    String? preventive,
    List<String>? evidenceRefs,
  }) =>
      CapaAction(
        id: id,
        checkpointId: checkpointId,
        title: title,
        finding: finding,
        corrective: corrective ?? this.corrective,
        preventive: preventive ?? this.preventive,
        severity: severity,
        category: category,
        standardRef: standardRef,
        status: status ?? this.status,
        raisedOn: raisedOn,
        dueOn: dueOn,
        owner: owner ?? this.owner,
        evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      );

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class CapaEngine {
  const CapaEngine._();

  /// Raises one CAPA per failed checkpoint.
  static List<CapaAction> raiseFrom({
    required List<Checkpoint> failed,
    required Map<String, CheckpointAnswer> answers,
    required BuildingType buildingType,
    DateTime? raisedOn,
  }) {
    final now = CapaAction._dateOnly(raisedOn ?? DateTime.now());
    final actions = <CapaAction>[];

    for (var i = 0; i < failed.length; i++) {
      final c = failed[i];
      final answer = answers[c.id];
      final remark = (answer?.remarks ?? '').trim();

      actions.add(CapaAction(
        id: 'CAPA-${(i + 1).toString().padLeft(3, '0')}',
        checkpointId: c.id,
        title: c.title,
        finding: remark.isEmpty ? c.description : remark,
        corrective: _corrective(c),
        preventive: _preventive(c),
        severity: c.severity,
        category: c.category,
        standardRef: c.standardLabel,
        status: CapaStatus.open,
        raisedOn: now,
        dueOn: now.add(Duration(days: c.severity.capaDueDays)),
        owner: _defaultOwner(c, buildingType),
        evidenceRefs: answer?.evidenceRefs ?? const [],
      ));
    }

    // Soonest due first, then worst severity.
    actions.sort((a, b) {
      final d = a.dueOn.compareTo(b.dueOn);
      return d != 0 ? d : b.severity.weight.compareTo(a.severity.weight);
    });
    return actions;
  }

  static String _corrective(Checkpoint c) =>
      'Rectify: ${c.title.toLowerCase()}. Restore compliance with ${c.standardLabel} '
      'and capture ${c.evidence.toLowerCase()} as closure proof.';

  static String _preventive(Checkpoint c) => switch (c.severity) {
        Severity.critical =>
          'Add to weekly inspection round. Assign a named owner and log every check.',
        Severity.major =>
          'Add to monthly preventive maintenance schedule with sign-off.',
        Severity.minor =>
          'Cover in the next quarterly review and update the site checklist.',
      };

  /// Routes the action to whoever normally owns that system on site.
  static String _defaultOwner(Checkpoint c, BuildingType type) {
    final cat = c.category.toLowerCase();
    if (cat.contains('escape') || cat.contains('emergency')) {
      return 'Safety Manager';
    }
    if (cat.contains('electrical') || cat.contains('hvac') || cat.contains('lift')) {
      return 'Facility Engineer';
    }
    if (cat.contains('pump') ||
        cat.contains('fighting') ||
        cat.contains('detection') ||
        c.source == CheckpointSource.bis) {
      return 'Fire Systems Technician';
    }
    if (cat.contains('construction') || cat.contains('characteristics')) {
      return 'Projects Team';
    }
    return 'Safety Manager';
  }

  // ─── Roll-ups for the tracker ──────────────────────────────────────────

  static int openCount(List<CapaAction> a) =>
      a.where((x) => x.status.isOpen).length;

  static int overdueCount(List<CapaAction> a, DateTime now) =>
      a.where((x) => x.isOverdue(now)).length;

  static int closedCount(List<CapaAction> a) =>
      a.where((x) => x.status == CapaStatus.closed).length;

  /// Share of actions closed, 0–1.
  static double closureRate(List<CapaAction> a) =>
      a.isEmpty ? 1 : closedCount(a) / a.length;

  static List<CapaAction> needingEscalation(
          List<CapaAction> a, DateTime now) =>
      a
          .where((x) => x.escalation(now) != EscalationLevel.none)
          .toList()
        ..sort((x, y) =>
            y.escalation(now).index.compareTo(x.escalation(now).index));
}
