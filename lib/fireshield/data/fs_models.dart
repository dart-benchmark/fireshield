/// Typed models for the FireShield data layer.
///
/// The PWA passes plain JS objects around; this gives Ravi concrete shapes to
/// map backend responses onto. Every model has [fromJson] / [toJson] so the
/// mock layer can be swapped for real API calls without touching the screens.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

enum FsRole { admin, orgadmin, manager, auditor, govt }

extension FsRoleInfo on FsRole {
  /// Wire value — matches the PWA's ROLES constants and route segments.
  String get key => switch (this) {
        FsRole.admin => 'admin',
        FsRole.orgadmin => 'orgadmin',
        FsRole.manager => 'manager',
        FsRole.auditor => 'auditor',
        FsRole.govt => 'govt',
      };

  String get label => switch (this) {
        FsRole.admin => 'Platform Admin',
        FsRole.orgadmin => 'Organisation Admin',
        FsRole.manager => 'Safety Manager',
        FsRole.auditor => 'Field Auditor',
        FsRole.govt => 'Government Officer',
      };

  static FsRole fromKey(String key) => switch (key) {
        'admin' => FsRole.admin,
        'orgadmin' => FsRole.orgadmin,
        'manager' => FsRole.manager,
        'auditor' => FsRole.auditor,
        'govt' => FsRole.govt,
        _ => FsRole.auditor,
      };
}

class FsUser {
  final int id;
  final String name;
  final FsRole role;
  final String email;
  final String facility;
  final String initials;
  final String dept;
  final String org;

  const FsUser({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.facility,
    required this.initials,
    required this.dept,
    required this.org,
  });

  factory FsUser.fromJson(Map<String, dynamic> j) => FsUser(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        role: FsRoleInfo.fromKey(j['role'] as String? ?? 'auditor'),
        email: j['email'] as String? ?? '',
        facility: j['facility'] as String? ?? '',
        initials: j['initials'] as String? ?? '',
        dept: j['dept'] as String? ?? '',
        org: j['org'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.key,
        'email': email,
        'facility': facility,
        'initials': initials,
        'dept': dept,
        'org': org,
      };
}

class FsOrganisation {
  final String id;
  final String name;
  final String industry;
  final String gst;
  final String pan;
  final String email;
  final String phone;
  final String city;
  final String state;
  final int facilities;
  final int compliance;
  final String risk;

  const FsOrganisation({
    required this.id,
    required this.name,
    required this.industry,
    required this.gst,
    required this.pan,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.facilities,
    required this.compliance,
    required this.risk,
  });

  factory FsOrganisation.fromJson(Map<String, dynamic> j) => FsOrganisation(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        industry: j['industry'] as String? ?? '',
        gst: j['gst'] as String? ?? '',
        pan: j['pan'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        city: j['city'] as String? ?? '',
        state: j['state'] as String? ?? '',
        facilities: j['facilities'] as int? ?? 0,
        compliance: j['compliance'] as int? ?? 0,
        risk: j['risk'] as String? ?? 'LOW',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'industry': industry,
        'gst': gst,
        'pan': pan,
        'email': email,
        'phone': phone,
        'city': city,
        'state': state,
        'facilities': facilities,
        'compliance': compliance,
        'risk': risk,
      };
}

class FsFacility {
  final String id;
  final String name;
  final String org;
  final String type;
  final String state;
  final String city;
  final String risk;
  final int compliance;
  final double fri;

  /// NOC status — Valid / Expiring / Expired.
  final String noc;
  final String nocExpiry;
  final int floors;
  final int basements;
  final String area;
  final int occupancy;
  final String lastAudit;
  final String due;
  final String head;
  final String coordinator;

  const FsFacility({
    required this.id,
    required this.name,
    required this.org,
    required this.type,
    required this.state,
    required this.city,
    required this.risk,
    required this.compliance,
    required this.fri,
    required this.noc,
    required this.nocExpiry,
    required this.floors,
    required this.basements,
    required this.area,
    required this.occupancy,
    required this.lastAudit,
    required this.due,
    required this.head,
    required this.coordinator,
  });

  factory FsFacility.fromJson(Map<String, dynamic> j) => FsFacility(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        org: j['org'] as String? ?? '',
        type: j['type'] as String? ?? '',
        state: j['state'] as String? ?? '',
        city: j['city'] as String? ?? '',
        risk: j['risk'] as String? ?? 'LOW',
        compliance: j['compliance'] as int? ?? 0,
        fri: (j['fri'] as num?)?.toDouble() ?? 0,
        noc: j['noc'] as String? ?? 'Valid',
        nocExpiry: j['nocExpiry'] as String? ?? '',
        floors: j['floors'] as int? ?? 0,
        basements: j['basements'] as int? ?? 0,
        area: j['area'] as String? ?? '',
        occupancy: j['occupancy'] as int? ?? 0,
        lastAudit: j['lastAudit'] as String? ?? '',
        due: j['due'] as String? ?? '',
        head: j['head'] as String? ?? '',
        coordinator: j['coordinator'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'org': org,
        'type': type,
        'state': state,
        'city': city,
        'risk': risk,
        'compliance': compliance,
        'fri': fri,
        'noc': noc,
        'nocExpiry': nocExpiry,
        'floors': floors,
        'basements': basements,
        'area': area,
        'occupancy': occupancy,
        'lastAudit': lastAudit,
        'due': due,
        'head': head,
        'coordinator': coordinator,
      };
}

class FsAudit {
  final String id;

  /// Human-readable audit number, e.g. AUD-202606-1089.
  final String no;
  final String facility;
  final String org;
  final String facilityId;
  final String type;

  /// IN_PROGRESS / SCHEDULED / SUBMITTED / APPROVED / OVERDUE.
  final String status;
  final String date;
  final int total;
  final int done;
  final double score;
  final String auditor;
  final String priority;

  const FsAudit({
    required this.id,
    required this.no,
    required this.facility,
    required this.org,
    required this.facilityId,
    required this.type,
    required this.status,
    required this.date,
    required this.total,
    required this.done,
    required this.score,
    required this.auditor,
    required this.priority,
  });

  /// 0–100.
  double get progress => total == 0 ? 0 : (done / total) * 100;

  factory FsAudit.fromJson(Map<String, dynamic> j) => FsAudit(
        id: j['id'] as String,
        no: j['no'] as String? ?? '',
        facility: j['facility'] as String? ?? '',
        org: j['org'] as String? ?? '',
        facilityId: j['facilityId'] as String? ?? '',
        type: j['type'] as String? ?? '',
        status: j['status'] as String? ?? 'SCHEDULED',
        date: j['date'] as String? ?? '',
        total: j['total'] as int? ?? 0,
        done: j['done'] as int? ?? 0,
        score: (j['score'] as num?)?.toDouble() ?? 0,
        auditor: j['auditor'] as String? ?? '',
        priority: j['priority'] as String? ?? 'NORMAL',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'facility': facility,
        'org': org,
        'facilityId': facilityId,
        'type': type,
        'status': status,
        'date': date,
        'total': total,
        'done': done,
        'score': score,
        'auditor': auditor,
        'priority': priority,
      };
}

class FsCorrectiveAction {
  final String id;

  /// Human-readable CA number, e.g. CA-2026-0234.
  final String no;
  final String title;

  /// CRITICAL / MAJOR / MINOR.
  final String severity;

  /// OPEN / IN_PROGRESS / OVERDUE / CLOSED.
  final String status;
  final String facility;

  /// Standard clause the finding was raised against.
  final String std;
  final String assigned;
  final String raised;
  final String due;
  final String cost;
  final String category;

  const FsCorrectiveAction({
    required this.id,
    required this.no,
    required this.title,
    required this.severity,
    required this.status,
    required this.facility,
    required this.std,
    required this.assigned,
    required this.raised,
    required this.due,
    required this.cost,
    required this.category,
  });

  bool get isOpen => status == 'OPEN' || status == 'IN_PROGRESS';

  factory FsCorrectiveAction.fromJson(Map<String, dynamic> j) =>
      FsCorrectiveAction(
        id: j['id'] as String,
        no: j['no'] as String? ?? '',
        title: j['title'] as String? ?? '',
        severity: j['severity'] as String? ?? 'MINOR',
        status: j['status'] as String? ?? 'OPEN',
        facility: j['facility'] as String? ?? '',
        std: j['std'] as String? ?? '',
        assigned: j['assigned'] as String? ?? '',
        raised: j['raised'] as String? ?? '',
        due: j['due'] as String? ?? '',
        cost: j['cost'] as String? ?? '',
        category: j['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'no': no,
        'title': title,
        'severity': severity,
        'status': status,
        'facility': facility,
        'std': std,
        'assigned': assigned,
        'raised': raised,
        'due': due,
        'cost': cost,
        'category': category,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// AI audit pipeline — vision detection + NBC 2026 compliance reasoning.
// These models cross the service boundary to the Cloudflare Worker
// (see lib/fireshield/services/), so they mirror the Worker's JSON shapes.
// ─────────────────────────────────────────────────────────────────────────────

/// One fire-safety asset type observed in site photos.
///
/// [source] records who found it: `clipseg` (in-browser segmentation, gives
/// presence + coarse count) or `qwen` (server vision, reads type/condition).
class DetectedEquipment {
  /// Canonical type key, aligned with the equipment inventory + Worker vocab:
  /// extinguisher, sprinkler, detector, manual_call_point, alarm_panel,
  /// exit_sign, emergency_light, fire_door, hydrant_hose_reel, fire_pump, other.
  final String type;
  final int count;

  /// clipseg | qwen | merged
  final String source;

  /// Short human note, e.g. "gauge in green", "obstructed", "expired tag".
  final String condition;

  /// Any readable text/rating, e.g. "ABC 6kg", "120 min".
  final String label;
  final double confidence;

  const DetectedEquipment({
    required this.type,
    required this.count,
    required this.source,
    this.condition = '',
    this.label = '',
    this.confidence = 0,
  });

  factory DetectedEquipment.fromJson(Map<String, dynamic> j) => DetectedEquipment(
        type: j['type'] as String? ?? 'other',
        count: (j['count'] as num?)?.toInt() ?? 0,
        source: j['source'] as String? ?? 'qwen',
        condition: j['condition'] as String? ?? '',
        label: j['label'] as String? ?? '',
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
        'source': source,
        'condition': condition,
        'label': label,
        'confidence': confidence,
      };
}

/// A cited NBCS 2026 Part F clause as returned by the `query_nbc` tool.
class NbcClause {
  final String id;
  final String title;
  final int? page;
  final String requirement;

  const NbcClause({
    required this.id,
    required this.title,
    this.page,
    this.requirement = '',
  });

  factory NbcClause.fromJson(Map<String, dynamic> j) => NbcClause(
        id: j['id'] as String? ?? '',
        title: (j['title'] ?? j['label']) as String? ?? '',
        page: (j['page'] as num?)?.toInt(),
        requirement: (j['requirement'] ?? j['snippet']) as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'page': page,
        'requirement': requirement,
      };
}

/// One compliance finding produced by the reasoning model.
class ComplianceFinding {
  final String system;

  /// compliant | gap | critical_gap | cannot_verify
  final String status;

  /// minor | major | critical
  final String severity;
  final String observed;
  final String required;
  final String clauseId;
  final int? page;
  final String rationale;

  const ComplianceFinding({
    required this.system,
    required this.status,
    this.severity = 'minor',
    this.observed = '',
    this.required = '',
    this.clauseId = '',
    this.page,
    this.rationale = '',
  });

  bool get isGap => status == 'gap' || status == 'critical_gap';

  factory ComplianceFinding.fromJson(Map<String, dynamic> j) => ComplianceFinding(
        system: j['system'] as String? ?? '',
        status: j['status'] as String? ?? 'cannot_verify',
        severity: j['severity'] as String? ?? 'minor',
        observed: j['observed'] as String? ?? '',
        required: j['required'] as String? ?? '',
        clauseId: j['clauseId'] as String? ?? '',
        page: (j['page'] as num?)?.toInt(),
        rationale: j['rationale'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'system': system,
        'status': status,
        'severity': severity,
        'observed': observed,
        'required': required,
        'clauseId': clauseId,
        'page': page,
        'rationale': rationale,
      };
}

/// The result of one AI audit run — carried across the engine's phases.
class FsAuditRun {
  /// Occupancy group letter (A–J) the building was classified under.
  final String occupancyGroup;

  /// Free-form building profile passed to the reasoning model
  /// (occupancy label, height, area, floors, basements…).
  final Map<String, dynamic> buildingProfile;
  final List<DetectedEquipment> detected;
  final List<String> docs;
  final List<ComplianceFinding> findings;
  final List<NbcClause> citedClauses;
  final String occupancySummary;

  /// 0–100 overall compliance.
  final double score;

  const FsAuditRun({
    this.occupancyGroup = '',
    this.buildingProfile = const {},
    this.detected = const [],
    this.docs = const [],
    this.findings = const [],
    this.citedClauses = const [],
    this.occupancySummary = '',
    this.score = 0,
  });

  FsAuditRun copyWith({
    String? occupancyGroup,
    Map<String, dynamic>? buildingProfile,
    List<DetectedEquipment>? detected,
    List<String>? docs,
    List<ComplianceFinding>? findings,
    List<NbcClause>? citedClauses,
    String? occupancySummary,
    double? score,
  }) =>
      FsAuditRun(
        occupancyGroup: occupancyGroup ?? this.occupancyGroup,
        buildingProfile: buildingProfile ?? this.buildingProfile,
        detected: detected ?? this.detected,
        docs: docs ?? this.docs,
        findings: findings ?? this.findings,
        citedClauses: citedClauses ?? this.citedClauses,
        occupancySummary: occupancySummary ?? this.occupancySummary,
        score: score ?? this.score,
      );

  /// Parse the `/groq/reason` verdict into findings + cited clauses + score.
  factory FsAuditRun.fromVerdict(
    Map<String, dynamic> j, {
    String occupancyGroup = '',
    Map<String, dynamic> buildingProfile = const {},
    List<DetectedEquipment> detected = const [],
    List<String> docs = const [],
  }) =>
      FsAuditRun(
        occupancyGroup: occupancyGroup,
        buildingProfile: buildingProfile,
        detected: detected,
        docs: docs,
        occupancySummary: j['occupancySummary'] as String? ?? '',
        score: (j['score'] as num?)?.toDouble() ?? 0,
        findings: (j['findings'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ComplianceFinding.fromJson)
            .toList(),
        citedClauses: (j['citedClauses'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(NbcClause.fromJson)
            .toList(),
      );

  /// Severity tallies the organisation's custom scoring formula substitutes
  /// into its own `critical`/`major`/`minor` variable names.
  int get criticalFindingCount =>
      findings.where((f) => f.severity == 'critical').length;
  int get majorFindingCount =>
      findings.where((f) => f.severity == 'major').length;
  int get minorFindingCount =>
      findings.where((f) => f.severity == 'minor').length;

  /// Recomputes [score] using the organisation's own weighting policy
  /// instead of the reasoning model's raw verdict — different regulators
  /// weight a critical gap very differently (e.g.
  /// `"100 - (critical*20 + major*8 + minor*2)"`), and this demo never grew a
  /// real expression parser, so the org-admin-authored formula is
  /// substituted and handed straight to the browser's own JS evaluator.
  FsAuditRun applyCustomScoreFormula(String formula) {
    final substituted = formula
        .replaceAll(RegExp(r'\bcritical\b'), '$criticalFindingCount')
        .replaceAll(RegExp(r'\bmajor\b'), '$majorFindingCount')
        .replaceAll(RegExp(r'\bminor\b'), '$minorFindingCount');
    final JSAny? result = globalContext.callMethod(
      'eval'.toJS,
      substituted.toJS,
    ); // SINK: PLANTED-Dart-HR-585
    final value = (result?.dartify() as num?)?.toDouble();
    if (value == null || value.isNaN) return this;
    return copyWith(score: value.clamp(0, 100));
  }

  /// Same policy-driven recompute, but the fully-substituted expression is
  /// re-checked against a strict digits/operators allow-list before it ever
  /// reaches the evaluator — a formula containing anything else (a stray
  /// semicolon, a function call) is rejected and the original score kept.
  FsAuditRun applyCustomScoreFormulaSafe(String formula) {
    final substituted = formula
        .replaceAll(RegExp(r'\bcritical\b'), '$criticalFindingCount')
        .replaceAll(RegExp(r'\bmajor\b'), '$majorFindingCount')
        .replaceAll(RegExp(r'\bminor\b'), '$minorFindingCount');
    if (!RegExp(r'^[0-9+\-*/(). \t]+$').hasMatch(substituted)) return this;
    final JSAny? result = globalContext.callMethod(
      'eval'.toJS,
      substituted.toJS,
    ); // SAFE_SINK: PLANTED-Dart-HR-585-safe
    final value = (result?.dartify() as num?)?.toDouble();
    if (value == null || value.isNaN) return this;
    return copyWith(score: value.clamp(0, 100));
  }

  /// Resolve-only half of the portfolio-level scoring policy: substitutes
  /// `critical`/`major`/`minor` in [formula] with the given tallies and
  /// returns the resulting expression text — it never evaluates anything
  /// itself. Shared by every subsystem that scores a group of facilities
  /// rather than one audit run's own findings (see
  /// `fs_orgadmin_dashboard.dart`, a different file/class, which is the one
  /// that actually hands the result to the evaluator).
  static String buildCustomScoreExpression({
    required String formula,
    required int critical,
    required int major,
    required int minor,
  }) => formula
      .replaceAll(RegExp(r'\bcritical\b'), '$critical')
      .replaceAll(RegExp(r'\bmajor\b'), '$major')
      .replaceAll(RegExp(r'\bminor\b'), '$minor');
}
