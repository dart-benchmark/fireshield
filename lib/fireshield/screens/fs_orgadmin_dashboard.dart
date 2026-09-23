/// Port of pwa_app/src/screens/orgadmin/OrgAdminDashboard.jsx (703 lines).
///
/// Data below (PHOENIX_ORG, FACILITIES, TEAM_MEMBERS, RECENT_AUDITS,
/// COMPLIANCE_ACTIONS, NOC_STATUS) is reproduced verbatim from the source
/// file's fallback constants.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../services/fs_offline_roster_cache.dart';
import '../services/fs_score_formula_resolver.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

const _org = (
  name: 'Phoenix Group',
  industry: 'Retail & Commercial',
  gst: '29AACCP1234M1Z5',
  pan: 'AACCP1234M',
  cin: 'U52100KA2001PLC028765',
  nbcGroup: 'F — Mercantile',
  riskCategory: 'C — High Risk',
  state: 'Karnataka',
  nocStatus: 'VALID',
  nocExpiry: '2027-03-31',
);

class _Facility {
  final String id, name, city, state, type, area, noc, nocExpiry, lastAudit;
  final int floors, basements, fri, openFindings, critical;
  const _Facility(this.id, this.name, this.city, this.state, this.type,
      this.area, this.floors, this.basements, this.fri, this.noc,
      this.nocExpiry, this.lastAudit, this.openFindings, this.critical);
}

const _facilities = [
  _Facility('F01', 'Phoenix Marketcity Bengaluru', 'Bengaluru', 'Karnataka', 'Shopping Mall', '750,000 sqft', 4, 3, 82, 'VALID', '27 Mar 2027', '12 Jun 2026', 4, 1),
  _Facility('F02', 'Phoenix Marketcity Pune', 'Pune', 'Maharashtra', 'Shopping Mall', '610,000 sqft', 4, 2, 74, 'VALID', '14 Nov 2026', '02 May 2026', 7, 2),
  _Facility('F03', 'Palladium Mumbai', 'Mumbai', 'Maharashtra', 'Mixed Use', '420,000 sqft', 6, 3, 91, 'VALID', '01 Sep 2027', '28 May 2026', 1, 0),
  _Facility('F04', 'Mall of Asia Bengaluru', 'Bengaluru', 'Karnataka', 'Shopping Mall', '1,200,000 sqft', 5, 4, 67, 'EXPIRING', '30 Jul 2026', '15 Apr 2026', 11, 3),
  _Facility('F05', 'Citadel Indore', 'Indore', 'Madhya Pradesh', 'Shopping Mall', '380,000 sqft', 3, 2, 88, 'VALID', '20 Dec 2026', '05 Jun 2026', 2, 0),
];

class _Team {
  final String name, role, facility, status;
  final int audits;
  const _Team(this.name, this.role, this.facility, this.status, this.audits);
}

const _team = [
  _Team('Arjun Sharma', 'Safety Manager', 'Phoenix Marketcity Bengaluru', 'ACTIVE', 12),
  _Team('Meera Pillai', 'Safety Manager', 'Phoenix Marketcity Pune', 'ACTIVE', 8),
  _Team('Sanjay Reddy', 'Safety Manager', 'Palladium Mumbai', 'ACTIVE', 14),
  _Team('Kavitha Nair', 'Safety Manager', 'Mall of Asia Bengaluru', 'ACTIVE', 6),
  _Team('Rohit Verma', 'Safety Manager', 'Citadel Indore', 'ACTIVE', 9),
  _Team('Priya Nair', 'Auditor', 'All Phoenix Facilities', 'ACTIVE', 31),
  _Team('Vikash Kumar', 'Auditor', 'Phoenix Marketcity Bengaluru', 'ACTIVE', 18),
  _Team('Deepa Rajan', 'Auditor', 'Phoenix Marketcity Pune', 'ACTIVE', 15),
  _Team('Amol Patil', 'Auditor', 'Palladium Mumbai', 'ACTIVE', 22),
  _Team('Sumit Gupta', 'Auditor', 'Mall of Asia Bengaluru', 'ACTIVE', 11),
];

class _RAudit {
  final String no, facility, type, date, auditor, status;
  final int score;
  const _RAudit(this.no, this.facility, this.type, this.date, this.auditor, this.score, this.status);
}

const _recentAudits = [
  _RAudit('PA-BLR-2026-041', 'Phoenix Marketcity Bengaluru', 'Comprehensive NBC Audit', '12 Jun 2026', 'Priya Nair', 82, 'COMPLETED'),
  _RAudit('PA-MUM-2026-039', 'Palladium Mumbai', 'Fire NOC Renewal', '28 May 2026', 'Amol Patil', 91, 'COMPLETED'),
  _RAudit('PA-BLR-2026-038', 'Mall of Asia Bengaluru', 'Quarterly Inspection', '15 Apr 2026', 'Sumit Gupta', 67, 'ACTION REQD'),
  _RAudit('PA-PUN-2026-037', 'Phoenix Marketcity Pune', 'Corrective Action Review', '02 May 2026', 'Deepa Rajan', 74, 'COMPLETED'),
  _RAudit('PA-IDR-2026-036', 'Citadel Indore', 'Comprehensive NBC Audit', '05 Jun 2026', 'Vikash Kumar', 88, 'COMPLETED'),
];

class _CA {
  final String facility, finding, severity, due, assignee, status;
  const _CA(this.facility, this.finding, this.severity, this.due, this.assignee, this.status);
}

const _cas = [
  _CA('Mall of Asia Bengaluru', 'Exit staircase partially obstructed — 3rd floor west wing', 'CRITICAL', '20 Jun 2026', 'Kavitha Nair', 'OVERDUE'),
  _CA('Mall of Asia Bengaluru', 'Sprinkler system — 14 heads blocked by renovation debris', 'CRITICAL', '22 Jun 2026', 'Kavitha Nair', 'IN PROGRESS'),
  _CA('Phoenix Marketcity Pune', 'Emergency lighting — 2 units failed battery test', 'HIGH', '25 Jun 2026', 'Meera Pillai', 'IN PROGRESS'),
  _CA('Phoenix Marketcity Pune', 'Fire NOC expiring in 143 days — renewal process pending', 'HIGH', '14 Nov 2026', 'Meera Pillai', 'PENDING'),
  _CA('Phoenix Marketcity Blr', 'AMC certificate for hydrant system expires Jun 30', 'MEDIUM', '30 Jun 2026', 'Arjun Sharma', 'IN PROGRESS'),
];

Color _friColor(int score) => score >= 85
    ? FsColors.success
    : score >= 70
        ? FsColors.amber700
        : FsColors.danger;

class FsOrgAdminDashboard extends StatefulWidget {
  final String? tab;
  const FsOrgAdminDashboard({super.key, this.tab});

  @override
  State<FsOrgAdminDashboard> createState() => _FsOrgAdminDashboardState();
}

class _FsOrgAdminDashboardState extends State<FsOrgAdminDashboard> {
  static const _tabs = ['Overview', 'Facilities', 'Team', 'Audits'];
  late int _tab = switch (widget.tab) {
    'facilities' => 1,
    'team' => 2,
    'audits' => 3,
    _ => 0,
  };
  _Facility? _facilityDetail;

  late final _formulaCtrl = TextEditingController(
    text: FsAppState.instance.customScoreFormula,
  );
  String? _previewResult;
  String? _applyResult;
  String? _portfolioReport;

  @override
  void dispose() {
    _formulaCtrl.dispose();
    super.dispose();
  }

  void _saveFormula() {
    setState(
      () => FsAppState.instance.setCustomScoreFormula(_formulaCtrl.text),
    );
  }

  int get _portfolioCritical =>
      _facilities.fold<int>(0, (s, f) => s + f.critical);
  int get _portfolioOther =>
      _facilities.fold<int>(0, (s, f) => s + (f.openFindings - f.critical));

  /// Resolved in `FsAuditRun.buildCustomScoreExpression` (fs_models.dart, a
  /// different file/class) and evaluated here — the organisation's raw
  /// formula text, minus its `critical`/`major`/`minor` placeholders,
  /// survives untouched into the evaluated string.
  void _previewPortfolioScore() {
    final formula = _formulaCtrl.text;
    if (formula.trim().isEmpty) return;
    final expr = FsAuditRun.buildCustomScoreExpression(
      formula: formula,
      critical: _portfolioCritical,
      major: 0,
      minor: _portfolioOther,
    );
    final JSAny? result = globalContext.callMethod(
      'eval'.toJS,
      expr.toJS,
    ); // SINK: PLANTED-Dart-HR-587
    setState(() => _previewResult = 'Preview: ${result?.dartify()}');
  }

  void _previewPortfolioScoreSafe() {
    final formula = _formulaCtrl.text;
    if (formula.trim().isEmpty) return;
    final expr = FsAuditRun.buildCustomScoreExpression(
      formula: formula,
      critical: _portfolioCritical,
      major: 0,
      minor: _portfolioOther,
    );
    if (!RegExp(r'^[0-9+\-*/(). \t]+$').hasMatch(expr)) {
      setState(() => _previewResult = 'Preview (safe): formula rejected');
      return;
    }
    final JSAny? result = globalContext.callMethod(
      'eval'.toJS,
      expr.toJS,
    ); // SAFE_SINK: PLANTED-Dart-HR-587-safe
    setState(() => _previewResult = 'Preview (safe): ${result?.dartify()}');
  }

  void _applyFormulaJsEngine() {
    final value = applyPortfolioFormulaViaResolver(
      const JsEvalScoreFormulaResolver(),
      formula: _formulaCtrl.text,
      critical: _portfolioCritical,
      major: 0,
      minor: _portfolioOther,
    );
    setState(
      () => _applyResult = value == null
          ? 'JS engine: no result'
          : 'JS engine result: ${value.toStringAsFixed(1)}',
    );
  }

  void _applyFormulaSafeEngine() {
    final value = applyPortfolioFormulaViaResolverSafe(
      const SafeArithmeticScoreFormulaResolver(),
      formula: _formulaCtrl.text,
      critical: _portfolioCritical,
      major: 0,
      minor: _portfolioOther,
    );
    setState(
      () => _applyResult = value == null
          ? 'Safe engine: no result'
          : 'Safe engine result: ${value.toStringAsFixed(1)}',
    );
  }

  /// Re-scores every facility in the portfolio, one evaluator call per
  /// facility, folding each result into a single running report — a
  /// genuinely different data-flow shape (N facilities, N evaluations, one
  /// accumulated report) from every other action on this screen.
  void _recalculatePortfolio() {
    final formula = _formulaCtrl.text;
    if (formula.trim().isEmpty) return;
    final report = StringBuffer();
    for (final f in _facilities) {
      final expr = FsAuditRun.buildCustomScoreExpression(
        formula: formula,
        critical: f.critical,
        major: 0,
        minor: f.openFindings - f.critical,
      );
      final JSAny? result = globalContext.callMethod(
        'eval'.toJS,
        expr.toJS,
      ); // SINK: PLANTED-Dart-HR-589
      report.writeln('${f.name}: ${result?.dartify()}');
    }
    setState(() => _portfolioReport = report.toString());
  }

  void _recalculatePortfolioSafe() {
    final formula = _formulaCtrl.text;
    if (formula.trim().isEmpty) return;
    final report = StringBuffer();
    for (final f in _facilities) {
      final expr = FsAuditRun.buildCustomScoreExpression(
        formula: formula,
        critical: f.critical,
        major: 0,
        minor: f.openFindings - f.critical,
      );
      if (!RegExp(r'^[0-9+\-*/(). \t]+$').hasMatch(expr)) {
        report.writeln('${f.name}: formula rejected');
        continue;
      }
      final JSAny? result = globalContext.callMethod(
        'eval'.toJS,
        expr.toJS,
      ); // SAFE_SINK: PLANTED-Dart-HR-589-safe
      report.writeln('${f.name}: ${result?.dartify()}');
    }
    setState(() => _portfolioReport = report.toString());
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: switch (_tab) {
                1 => _facilityDetail != null
                    ? _facilityDetailView(_facilityDetail!)
                    : _facilitiesTab(),
                2 => _teamTab(),
                3 => _auditsTab(),
                _ => _overviewTab(),
              },
            ),
          ),
        ],
      );

  Widget _buildHeader() => Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_org.name,
                              style: FsText.tiny.copyWith(
                                  color: FsColors.info,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6)),
                          const Text('Organisation Admin',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: FsColors.gray900)),
                          const Text('Organisation Admin · All Facilities',
                              style: FsText.tiny),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FsColors.roleOrgAdmin,
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child: const Text('VM',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _tab = i;
                          _facilityDetail = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2,
                                color: active
                                    ? FsColors.info
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active ? FsColors.info : FsColors.subtle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );

  // ── Overview ───────────────────────────────────────────────────────────

  List<Widget> _overviewTab() {
    final avgFri =
        (_facilities.fold<int>(0, (s, f) => s + f.fri) / _facilities.length)
            .round();
    final totalFindings = _facilities.fold<int>(0, (s, f) => s + f.openFindings);
    final totalCritical = _facilities.fold<int>(0, (s, f) => s + f.critical);

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF0F2340)],
          ),
          borderRadius: BorderRadius.circular(FsRadius.xl2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ORGANISATION ADMIN',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF93C5FD),
                              fontWeight: FontWeight.w600)),
                      Text(_org.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      Text(_org.industry,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFFBFDBFE))),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FsRadius.xl),
                  ),
                  child: const Text('🏛️', style: TextStyle(fontSize: 22)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  _orgStat('Facilities', '${_facilities.length}'),
                  _orgStat('Avg FRI', '$avgFri%'),
                  _orgStat('NBC Group', 'F'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FsCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: FsColors.gray100,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(FsRadius.xl2)),
              ),
              child: Text('ORGANISATION DETAILS',
                  style: FsText.micro.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
            _orgRow('GST Number', _org.gst),
            _orgRow('PAN Number', _org.pan),
            _orgRow('CIN Number', _org.cin),
            _orgRow('NBC Occupancy Group', _org.nbcGroup),
            _orgRow('Risk Category', _org.riskCategory),
            _orgRow('State', _org.state),
            _orgRow('NOC Status', _org.nocStatus, valueColor: FsColors.success),
            _orgRow('NOC Expiry', _org.nocExpiry, last: true),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FsCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: FsColors.gray100,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(FsRadius.xl2)),
              ),
              child: Text('SCORING POLICY',
                  style: FsText.micro.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Override the default severity weighting for every '
                    'audit and facility in this organisation, e.g. '
                    '"100 - (critical*20 + major*8 + minor*2)".',
                    style: FsText.tiny,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _formulaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Custom compliance formula',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _saveFormula,
                        child: const Text('Save Policy'),
                      ),
                      OutlinedButton(
                        onPressed: _previewPortfolioScore,
                        child: const Text('Preview Portfolio Score'),
                      ),
                      OutlinedButton(
                        onPressed: _previewPortfolioScoreSafe,
                        child: const Text('Preview Portfolio Score (safe)'),
                      ),
                      OutlinedButton(
                        onPressed: _applyFormulaJsEngine,
                        child: const Text('Apply Formula (JS engine)'),
                      ),
                      OutlinedButton(
                        onPressed: _applyFormulaSafeEngine,
                        child: const Text('Apply Formula (safe engine)'),
                      ),
                      OutlinedButton(
                        onPressed: _recalculatePortfolio,
                        child: const Text('Recalculate All Facilities'),
                      ),
                      OutlinedButton(
                        onPressed: _recalculatePortfolioSafe,
                        child: const Text('Recalculate All Facilities (safe)'),
                      ),
                    ],
                  ),
                  if (_previewResult != null) ...[
                    const SizedBox(height: 8),
                    Text(_previewResult!, style: FsText.tiny),
                  ],
                  if (_applyResult != null) ...[
                    const SizedBox(height: 8),
                    Text(_applyResult!, style: FsText.tiny),
                  ],
                  if (_portfolioReport != null) ...[
                    const SizedBox(height: 8),
                    Text(_portfolioReport!, style: FsText.tiny),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: [
          _kpiTile('🏢', '${_facilities.length}', 'Facilities', FsColors.info, FsColors.infoLight),
          _kpiTile('📊', '$avgFri%', 'Avg FRI', FsColors.success, FsColors.successLight),
          _kpiTile('⚠️', '$totalFindings', 'Open Findings', FsColors.amber700, const Color(0xFFFFFBEB)),
          _kpiTile('🚨', '$totalCritical', 'Critical', FsColors.danger, FsColors.dangerLight),
        ],
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Text('⏰', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1 NOC expiring within 60 days',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: FsColors.amber700)),
                  Text(
                      'Mall of Asia Bengaluru — 42 days remaining. Initiate renewal.',
                      style: FsText.tiny),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text('Facility Compliance — FRI Scores', style: FsText.title),
      const SizedBox(height: 8),
      ..._facilities.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FsCard(
              onTap: () => setState(() {
                _facilityDetail = f;
                _tab = 1;
              }),
              child: Row(
                children: [
                  _friGauge(f.fri),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(f.name,
                                    style: FsText.cardTitle,
                                    overflow: TextOverflow.ellipsis)),
                            if (f.critical > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: FsColors.red100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('🚨 ${f.critical}',
                                    style: FsText.micro
                                        .copyWith(color: FsColors.red700)),
                              ),
                          ],
                        ),
                        Text('${f.city} · ${f.type} · ${f.area}',
                            style: FsText.tiny),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                                child: ProgressBar(
                                    value: f.fri.toDouble(),
                                    color: _friColor(f.fri))),
                            const SizedBox(width: 8),
                            StatusBadge(status: f.noc),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
      const SizedBox(height: 6),
      Row(
        children: [
          const Expanded(child: Text('Critical Actions', style: FsText.title)),
          Text('${_cas.length} open',
              style: FsText.small.copyWith(
                  color: FsColors.info, fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 8),
      ..._cas.take(3).map((ca) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatusBadge(status: ca.severity),
                    const SizedBox(width: 6),
                    StatusBadge(status: ca.status.replaceAll(' ', '_')),
                  ]),
                  const SizedBox(height: 4),
                  Text(ca.finding, style: FsText.small),
                  const SizedBox(height: 4),
                  Text('${ca.facility} · Due ${ca.due} · ${ca.assignee}',
                      style: FsText.tiny),
                ],
              ),
            ),
          )),
    ];
  }

  Widget _orgStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 9, color: Color(0xFF93C5FD))),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      );

  Widget _orgRow(String k, String v, {Color? valueColor, bool last = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: FsColors.gray100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: FsText.tiny),
            Text(v,
                style: FsText.tiny.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? FsColors.gray800)),
          ],
        ),
      );

  Widget _kpiTile(String icon, String value, String label, Color fg, Color bg) =>
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FsRadius.xl),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: fg)),
            Text(label,
                textAlign: TextAlign.center,
                style: FsText.micro,
                maxLines: 2),
          ],
        ),
      );

  Widget _friGauge(int score) => SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3,
              backgroundColor: FsColors.gray100,
              valueColor: AlwaysStoppedAnimation<Color>(_friColor(score)),
            ),
            Text('$score',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: _friColor(score))),
          ],
        ),
      );

  // ── Facilities tab ─────────────────────────────────────────────────────

  List<Widget> _facilitiesTab() => [
        Row(
          children: [
            Expanded(
                child: Text('${_facilities.length} facilities across India',
                    style: FsText.small)),
            OutlinedButton(
              onPressed: () => context.push('/orgadmin/add-facility'),
              child: const Text('+ Add Facility'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._facilities.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                onTap: () => setState(() => _facilityDetail = f),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _friGauge(f.fri),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(f.name,
                                      style: FsText.cardTitle,
                                      overflow: TextOverflow.ellipsis)),
                              StatusBadge(
                                  status: f.noc == 'EXPIRING'
                                      ? 'EXPIRING'
                                      : 'Valid'),
                            ],
                          ),
                          Text('${f.city}, ${f.state} · ${f.type}',
                              style: FsText.tiny),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                  child: _miniStat('Area', f.area)),
                              Expanded(
                                  child: _miniStat('Floors',
                                      '${f.floors}F+B${f.basements}')),
                              Expanded(
                                  child: _miniStat('Findings',
                                      '${f.openFindings}')),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Last audit: ${f.lastAudit}',
                                  style: FsText.micro),
                              if (f.critical > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: FsColors.red100,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text('${f.critical} CRITICAL',
                                      style: FsText.micro.copyWith(
                                          color: FsColors.red700)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ];

  Widget _miniStat(String label, String value) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: FsColors.gray100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label,
                style: FsText.micro.copyWith(fontSize: 7.5)),
            Text(value,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  List<Widget> _facilityDetailView(_Facility f) => [
        GestureDetector(
          onTap: () => setState(() => _facilityDetail = null),
          child: Text('‹ Back to Facilities',
              style: FsText.small.copyWith(
                  color: FsColors.info, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Row(
            children: [
              _friGauge(f.fri),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: FsText.title),
                    Text('${f.city}, ${f.state}', style: FsText.tiny),
                    const SizedBox(height: 4),
                    Row(children: [
                      const StatusBadge(status: 'OPERATIONAL'),
                      const SizedBox(width: 6),
                      StatusBadge(status: f.noc),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 18, color: FsColors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fire NOC', style: FsText.cardTitle),
                    Text('Expires ${f.nocExpiry}', style: FsText.tiny),
                  ],
                ),
              ),
              StatusBadge(status: f.noc),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text('Open Corrective Actions', style: FsText.title),
        const SizedBox(height: 8),
        ..._cas.where((ca) => ca.facility.contains(f.city) || ca.facility.contains(f.name.substring(0, 10))).map(
              (ca) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        StatusBadge(status: ca.severity),
                        const SizedBox(width: 6),
                        StatusBadge(status: ca.status.replaceAll(' ', '_')),
                      ]),
                      const SizedBox(height: 4),
                      Text(ca.finding, style: FsText.small),
                      Text('Due ${ca.due} · ${ca.assignee}', style: FsText.micro),
                    ],
                  ),
                ),
              ),
            ),
      ];

  // ── Team tab ───────────────────────────────────────────────────────────

  String _roleFilter = 'All';

  /// "Save Offline" — lets an org admin keep working the Team tab through a
  /// connectivity drop by caching the full roster (including every member's
  /// real name) on this device. Supabase's `organisation_members`/`profiles`
  /// tables (via [FsPersistenceService]) stay the single source of truth;
  /// this is a read-through convenience cache only.
  Future<void> _saveRosterOffline() async {
    await FsOfflineRosterCache.saveRoster(_team
        .map((t) => (name: t.name, role: t.role, facility: t.facility))
        .toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Roster cached for offline use.'),
    ));
  }

  /// Redacted variant: caches only each member's positional index into the
  /// in-memory `_team` list (never their name or any other identifying
  /// field) alongside their facility — offered to a Safety Manager, whose
  /// role does not need (and per policy should not retain) the full team
  /// roster's identifying detail on this device. A resumed offline session
  /// re-resolves the real name from `_team[ref]`, the existing single
  /// source of truth for this session, exactly when it's shown on screen.
  Future<void> _saveRosterOfflineRedacted() async {
    await FsOfflineRosterCache.saveRosterReferencesOnly(_team
        .asMap()
        .entries
        .map((e) => (index: e.key, facility: e.value.facility))
        .toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Redacted roster cached for offline use.'),
    ));
  }

  List<Widget> _teamTab() {
    final filtered = _roleFilter == 'All'
        ? _team
        : _team.where((t) => t.role == _roleFilter).toList();
    return [
      Row(
        children: [
          Expanded(
              child: Text('${_team.length} team members', style: FsText.small)),
          OutlinedButton(
            onPressed: _saveRosterOffline,
            child: const Text('⬇ Save Offline'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _saveRosterOfflineRedacted,
            child: const Text('⬇ Save (redacted)'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.push('/orgadmin/create-user'),
            child: const Text('+ Add User'),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: ['All', 'Safety Manager', 'Auditor']
              .map((r) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _roleFilter = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _roleFilter == r
                              ? FsColors.info
                              : FsColors.gray100,
                          borderRadius: BorderRadius.circular(FsRadius.full),
                        ),
                        child: Text(r,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _roleFilter == r
                                    ? Colors.white
                                    : FsColors.muted)),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 10),
      ...filtered.map((u) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FsCard(
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: u.role == 'Safety Manager'
                          ? FsColors.roleManager
                          : FsColors.roleAuditor,
                      borderRadius: BorderRadius.circular(FsRadius.xl),
                    ),
                    child: Text(
                      u.name.split(' ').map((n) => n[0]).join(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(u.name, style: FsText.cardTitle),
                            const SizedBox(width: 6),
                            const StatusBadge(status: 'Valid'),
                          ],
                        ),
                        Text(u.role, style: FsText.tiny),
                        Text(u.facility,
                            style: FsText.micro,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${u.audits}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900)),
                      const Text('audits', style: FsText.micro),
                    ],
                  ),
                ],
              ),
            ),
          )),
    ];
  }

  // ── Audits tab ─────────────────────────────────────────────────────────

  List<Widget> _auditsTab() => [
        Row(
          children: [
            Expanded(
                child: Text('${_recentAudits.length} recent audits',
                    style: FsText.small)),
          ],
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Facility FRI Comparison', style: FsText.cardTitle),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _facilities
                      .map((f) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${f.fri}%',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          color: _friColor(f.fri))),
                                  Container(
                                    height: f.fri * 0.55,
                                    decoration: BoxDecoration(
                                      color: _friColor(f.fri),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(2)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(f.name.split(' ').last,
                                      style: FsText.micro,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._recentAudits.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.no,
                            style: FsText.tiny.copyWith(
                                color: FsColors.info,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        StatusBadge(status: a.status.replaceAll(' ', '_')),
                      ],
                    ),
                    Text(a.facility, style: FsText.cardTitle),
                    Text(a.type, style: FsText.tiny),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${a.date} · ${a.auditor}', style: FsText.micro),
                        Text('${a.score}%',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _friColor(a.score))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ProgressBar(value: a.score.toDouble(), color: _friColor(a.score)),
                  ],
                ),
              ),
            )),
      ];
}
