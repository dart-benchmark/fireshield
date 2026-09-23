/// Port of pwa_app/src/screens/govt/GovtDashboard.jsx (622 lines).
///
/// OFFICER, JURISDICTION_STATS, BUILDINGS (20), SUBMISSIONS (7),
/// CRITICAL_FINDINGS (6), COMPLIANCE_BY_TYPE (7), MONTHLY_INSPECTIONS (6)
/// and ZONE_COMPLIANCE (10) are reproduced verbatim from the source file.
library;

import 'package:flutter/material.dart';

import '../services/fs_noc_submission_service.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_charts.dart';
import '../widgets/fs_ui.dart';

const _officer = (
  name: 'Shri A.K. Sharma',
  designation: 'Deputy Director — Fire & Emergency Services',
  dept: 'Karnataka State Fire & Emergency Services',
  empId: 'KSFES-DD-2019-047',
  jurisdiction: 'Bengaluru Urban District',
);

const _stats = (
  totalBuildings: 2847,
  nocActive: 2210,
  nocExpired: 312,
  nocPending: 325,
  criticalBuildings: 48,
  compliancePct: 78,
  auditedThisMonth: 142,
  noticesIssued: 23,
  pendingApprovals: 18,
);

class _Building {
  final String id, name, type, zone, noc, nocExpiry, lastInspection, risk;
  final int daysLeft, score, floors, basements, violations;
  final String area;
  const _Building(this.id, this.name, this.type, this.zone, this.noc,
      this.nocExpiry, this.daysLeft, this.risk, this.lastInspection,
      this.score, this.floors, this.basements, this.area, this.violations);
}

const _buildings = [
  _Building('B001', 'Phoenix Marketcity Bengaluru', 'Mall', 'Whitefield', 'VALID', '27 Mar 2027', 282, 'HIGH', '12 Jun 2026', 82, 4, 3, '7,50,000 sqft', 2),
  _Building('B002', 'Apollo Hospital Bannerghatta Rd', 'Hospital', 'BTM Layout', 'VALID', '15 Aug 2026', 58, 'HIGH', '08 Jun 2026', 91, 7, 2, '2,80,000 sqft', 0),
  _Building('B003', 'Prestige Tech Park Tower 4', 'IT Park', 'Marathahalli', 'EXPIRING', '30 Jul 2026', 42, 'MEDIUM', '02 May 2026', 88, 12, 2, '1,95,000 sqft', 1),
  _Building('B004', 'Garuda Mall Rajajinagar', 'Mall', 'Rajajinagar', 'EXPIRED', '30 Nov 2025', -200, 'CRITICAL', '15 Jan 2026', 61, 4, 2, '4,20,000 sqft', 7),
  _Building('B005', 'Manyata Tech Park Block E', 'IT Park', 'Nagawara', 'VALID', '14 Jan 2027', 210, 'MEDIUM', '20 May 2026', 79, 8, 3, '3,10,000 sqft', 3),
  _Building('B006', 'Columbia Asia Hospital Yeshwanthpur', 'Hospital', 'Yeshwanthpur', 'VALID', '01 Dec 2026', 166, 'HIGH', '05 Jun 2026', 86, 6, 1, '1,60,000 sqft', 1),
  _Building('B007', 'Mantri Square Mall Malleswaram', 'Mall', 'Malleswaram', 'EXPIRING', '20 Aug 2026', 63, 'HIGH', '28 Apr 2026', 73, 4, 3, '9,24,000 sqft', 4),
  _Building('B008', 'Infosys Campus Building 12', 'IT Campus', 'Electronic City', 'VALID', '10 Feb 2027', 237, 'LOW', '01 Jun 2026', 93, 6, 2, '2,40,000 sqft', 0),
  _Building('B009', 'Brigade Gateway Phase 2', 'Residential', 'Rajajinagar', 'VALID', '30 Oct 2026', 134, 'MEDIUM', '18 May 2026', 84, 14, 2, '3,20,000 sqft', 2),
  _Building('B010', 'Narayana Multispeciality Hospital', 'Hospital', 'HSR Layout', 'EXPIRED', '31 Dec 2025', -170, 'CRITICAL', '10 Feb 2026', 58, 5, 1, '1,10,000 sqft', 9),
  _Building('B011', 'WTC Bengaluru Tower 1', 'Office', 'Hebbal', 'VALID', '25 Jun 2027', 372, 'LOW', '10 Jun 2026', 90, 22, 4, '5,50,000 sqft', 0),
  _Building('B012', 'Bengaluru Intl Airport Terminal 2', 'Airport', 'Devanahalli', 'VALID', '31 Mar 2027', 286, 'HIGH', '25 May 2026', 95, 5, 2, '25,00,000 sqft', 0),
  _Building('B013', 'HAL Heritage Centre', 'Defence', 'HAL Airport', 'EXPIRED', '31 Mar 2026', -79, 'HIGH', '15 Apr 2026', 69, 3, 1, '85,000 sqft', 5),
  _Building('B014', 'Total Mall Sarjapur', 'Mall', 'Sarjapur', 'VALID', '28 Feb 2027', 255, 'MEDIUM', '04 Jun 2026', 77, 3, 2, '3,80,000 sqft', 2),
  _Building('B015', 'BBMP Head Office', 'Government', 'Hudson Circle', 'EXPIRED', '15 Nov 2025', -215, 'MEDIUM', '20 Mar 2026', 71, 8, 0, '1,20,000 sqft', 3),
  _Building('B016', 'Sakra World Hospital', 'Hospital', 'Marathahalli', 'VALID', '20 Sep 2026', 94, 'HIGH', '30 May 2026', 87, 8, 2, '2,00,000 sqft', 1),
  _Building('B017', 'Bengaluru Central Prison', 'Government', 'Parappana Agrahara', 'EXPIRED', '30 Jun 2025', -353, 'HIGH', '05 May 2026', 54, 4, 0, '5,60,000 sqft', 12),
  _Building('B018', 'Orion Mall Rajajinagar', 'Mall', 'Rajajinagar', 'VALID', '05 Nov 2026', 140, 'MEDIUM', '22 May 2026', 81, 3, 3, '4,00,000 sqft', 2),
  _Building('B019', 'RV Circle Fire Station', 'Government', 'RV Circle', 'VALID', '01 Apr 2027', 287, 'LOW', '01 Jun 2026', 98, 3, 0, '18,000 sqft', 0),
  _Building('B020', 'Phoenix Palladium Whitefield', 'Mall', 'Whitefield', 'VALID', '01 Sep 2027', 440, 'MEDIUM', '28 May 2026', 91, 6, 3, '4,20,000 sqft', 1),
];

class _Submission {
  final String no, building, type, submitted, auditor, org, status;
  final int score;
  const _Submission(this.no, this.building, this.type, this.submitted,
      this.score, this.auditor, this.status, this.org);
}

const _submissions = [
  _Submission('SUB-2026-0891', 'Prestige Tech Park Tower 4', 'IT Park', '12 Jun 2026', 88, 'Priya Nair', 'UNDER_REVIEW', 'Prestige Group'),
  _Submission('SUB-2026-0889', 'Apollo Hospital Bannerghatta', 'Hospital', '08 Jun 2026', 91, 'Ravi Kumar', 'APPROVED', 'Apollo Hospitals'),
  _Submission('SUB-2026-0884', 'Infosys Campus Building 12', 'IT Campus', '01 Jun 2026', 93, 'Suresh Pillai', 'APPROVED', 'Infosys Limited'),
  _Submission('SUB-2026-0879', 'Phoenix Marketcity Bengaluru', 'Mall', '28 May 2026', 74, 'Priya Nair', 'UNDER_REVIEW', 'Phoenix Group'),
  _Submission('SUB-2026-0871', 'Brigade Gateway Phase 2', 'Residential', '20 May 2026', 65, 'Deepa Rajan', 'RETURNED', 'Brigade Group'),
  _Submission('SUB-2026-0865', 'Columbia Asia Yeshwanthpur', 'Hospital', '15 May 2026', 86, 'Ravi Kumar', 'APPROVED', 'Columbia Asia'),
  _Submission('SUB-2026-0858', 'Sakra World Hospital', 'Hospital', '10 May 2026', 87, 'Amol Patil', 'APPROVED', 'Sakra Healthcare'),
];

class _Finding {
  final String building, zone, finding, severity, reported, status;
  final int daysOpen;
  const _Finding(this.building, this.zone, this.finding, this.severity, this.reported, this.status, this.daysOpen);
}

const _findings = [
  _Finding('Narayana Multispeciality Hospital', 'HSR Layout', 'Exit doors chained shut on ground floor — NBC Cl. 4.4.3 violation', 'CRITICAL', '10 Jun 2026', 'UNRESOLVED', 8),
  _Finding('Garuda Mall Rajajinagar', 'Rajajinagar', 'All 3 fire pumps found non-functional — hydrant system inoperable', 'CRITICAL', '08 Jun 2026', 'UNRESOLVED', 10),
  _Finding('Bengaluru Central Prison', 'Parappana Agrahara', 'Zero fire extinguishers on Blocks C, D, E — total 12 missing', 'CRITICAL', '05 Jun 2026', 'ESCALATED', 13),
  _Finding('Prestige Tech Park Tower 4', 'Marathahalli', 'Sprinkler control valve closed in basement B2 — IS 15105 Cl. 9.2', 'HIGH', '02 Jun 2026', 'IN PROGRESS', 16),
  _Finding('Manyata Tech Park Block E', 'Nagawara', 'Fire alarm panel on bypass mode for >30 days — NBC Cl. 5.3.1', 'HIGH', '28 May 2026', 'IN PROGRESS', 21),
  _Finding('HAL Heritage Centre', 'HAL Airport', 'Emergency lighting batteries flat — 100% failure on test', 'HIGH', '15 May 2026', 'UNRESOLVED', 34),
];

const _complianceByType = [
  ('Healthcare', 88, Color(0xFFDC2626), 312),
  ('IT / Office', 91, Color(0xFF2563EB), 487),
  ('Retail / Malls', 72, Color(0xFFD97706), 178),
  ('Residential', 76, Color(0xFF7C3AED), 891),
  ('Educational', 83, Color(0xFF16A34A), 445),
  ('Industrial', 69, Color(0xFF64748B), 367),
  ('Government', 71, Color(0xFF0891B2), 167),
];

const _monthlyInspections = [
  ('Dec', 88), ('Jan', 102), ('Feb', 94), ('Mar', 118), ('Apr', 126), ('May', 142),
];

const _zoneCompliance = [
  ('Electronic City', 341, 93, 'LOW'),
  ('Whitefield', 287, 91, 'LOW'),
  ('Marathahalli', 198, 88, 'LOW'),
  ('Hebbal', 156, 85, 'MEDIUM'),
  ('Nagawara', 143, 83, 'MEDIUM'),
  ('BTM Layout', 221, 81, 'MEDIUM'),
  ('Malleswaram', 189, 77, 'MEDIUM'),
  ('Rajajinagar', 234, 73, 'HIGH'),
  ('HSR Layout', 178, 70, 'HIGH'),
  ('Parappana Agrahara', 89, 58, 'CRITICAL'),
];

Color _zoneColor(int pct) => pct >= 90
    ? const Color(0xFF16A34A)
    : pct >= 80
        ? const Color(0xFF65A30D)
        : pct >= 70
            ? const Color(0xFFD97706)
            : pct >= 60
                ? const Color(0xFFEA580C)
                : const Color(0xFFDC2626);

Color _scoreColor(int s) =>
    s >= 85 ? FsColors.success : s >= 70 ? FsColors.amber700 : FsColors.danger;

class FsGovtDashboard extends StatefulWidget {
  const FsGovtDashboard({super.key});

  @override
  State<FsGovtDashboard> createState() => _FsGovtDashboardState();
}

class _FsGovtDashboardState extends State<FsGovtDashboard> {
  static const _tabs = ['Overview', 'Buildings', 'NOC', 'Reports', 'Findings'];
  static const _tabIcons = ['⊞', '🏢', '📄', '📋', '🚨'];
  int _tab = 0;
  final _nocService = FsNocSubmissionService();
  final Set<String> _escalating = {};
  final Set<String> _escalated = {};

  @override
  void dispose() {
    _nocService.dispose();
    super.dispose();
  }

  Future<void> _escalate(_Finding f, {required bool verified}) async {
    final ref = '${f.building}|${f.zone}|${f.finding}';
    setState(() => _escalating.add(ref));
    try {
      if (verified) {
        await _nocService.escalateFindingViaVerifiedGateway(
          building: f.building,
          findingRef: ref,
        );
      } else {
        await _nocService.escalateFindingToEnforcement(
          building: f.building,
          findingRef: ref,
        );
      }
      if (mounted) {
        setState(() => _escalated.add(ref));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escalated ${f.building} to enforcement.')),
        );
      }
    } catch (e) {
      if (mounted) {
        // Both the verified-gateway and direct-enforcement branches above can
        // fail with a raw HTTP/library exception (a 4xx body, a TimeoutException,
        // a SocketException) whose text can name the enforcement endpoint's own
        // internal detail — shown verbatim regardless of which branch ran.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Escalation failed: $e'))); // SINK: PLANTED-Dart-HR-481
      }
    } finally {
      if (mounted) setState(() => _escalating.remove(ref));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: switch (_tab) {
                1 => _buildingsTab(),
                2 => _nocTab(),
                3 => _reportsTab(),
                4 => _findingsTab(),
                _ => _overviewTab(),
              },
            ),
          ),
        ],
      );

  Widget _buildHeader() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF1A2E4A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: FsColors.amber400,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('GOV',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: FsColors.gray900)),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('GOVERNMENT OFFICER',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF93C5FD),
                                              fontWeight: FontWeight.w600)),
                                      Text(_officer.name,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(_officer.designation,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF93C5FD))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Emp ID',
                                style: TextStyle(
                                    fontSize: 9, color: Color(0xFF60A5FA))),
                            Text(_officer.empId,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: FsColors.eyYellow,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('JURISDICTION',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF93C5FD),
                                        fontWeight: FontWeight.w600)),
                                Text(_officer.jurisdiction,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                                Text(_officer.dept,
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF93C5FD))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${_stats.compliancePct}%',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                              const Text('Compliance',
                                  style: TextStyle(
                                      fontSize: 9, color: Color(0xFF93C5FD))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _kpiChip('${_stats.totalBuildings}', 'Total', Colors.white),
                        _kpiChip('${_stats.nocActive}', 'NOC Valid', const Color(0xFF4ADE80)),
                        _kpiChip('${_stats.nocExpired}', 'Expired', const Color(0xFFF87171)),
                        _kpiChip('${_stats.criticalBuildings}', 'Critical', const Color(0xFFFB923C)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2,
                                color: active
                                    ? FsColors.amber400
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(_tabIcons[i],
                                  style: const TextStyle(fontSize: 14)),
                              Text(_tabs[i],
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? FsColors.amber400
                                          : const Color(0xFF93C5FD))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _kpiChip(String value, String label, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(FsRadius.xl),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF93C5FD))),
            ],
          ),
        ),
      );

  // ── Overview ───────────────────────────────────────────────────────────

  List<Widget> _overviewTab() {
    final expired = _buildings.where((b) => b.noc == 'EXPIRED').length;
    final expiring = _buildings.where((b) => b.noc == 'EXPIRING').length;
    final highRisk = _buildings
        .where((b) => b.risk == 'CRITICAL' || (b.risk == 'HIGH' && b.noc != 'VALID'))
        .take(4)
        .toList();

    return [
      FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('JURISDICTION COMPLIANCE SCORE',
                style: FsText.xs.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _stats.compliancePct / 100,
                        strokeWidth: 7,
                        backgroundColor: FsColors.gray100,
                        valueColor: const AlwaysStoppedAnimation<Color>(FsColors.info),
                      ),
                      Text('${_stats.compliancePct}%',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buildings in Compliance', style: FsText.cardTitle),
                      Text(
                          '${_stats.nocActive} of ${_stats.totalBuildings} buildings have valid NOC',
                          style: FsText.tiny),
                      const SizedBox(height: 4),
                      Text('⚠ ${_stats.nocPending} applications pending review',
                          style: FsText.tiny.copyWith(color: FsColors.amber700)),
                      Text('🚨 ${_stats.criticalBuildings} buildings flagged critical',
                          style: FsText.tiny.copyWith(color: FsColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (expired > 0)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FsColors.dangerLight,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Text('🚨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$expired buildings operating with expired NOC',
                        style: FsText.small.copyWith(
                            fontWeight: FontWeight.w700, color: FsColors.red700)),
                    Text(
                        'Show-cause notices should be issued. Action required within 48 hrs.',
                        style: FsText.tiny.copyWith(color: FsColors.red600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (expiring > 0)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '$expiring NOCs expiring within 60 days — initiate renewal reminders',
                    style: FsText.small.copyWith(
                        color: FsColors.amber700, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
              child: KpiCard(
                  icon: '📋',
                  label: 'Audited This Month',
                  value: '${_stats.auditedThisMonth}',
                  color: FsColors.info)),
          const SizedBox(width: 8),
          Expanded(
              child: KpiCard(
                  icon: '📨',
                  label: 'Notices Issued',
                  value: '${_stats.noticesIssued}',
                  color: FsColors.danger)),
          const SizedBox(width: 8),
          Expanded(
              child: KpiCard(
                  icon: '⏳',
                  label: 'Pending Approvals',
                  value: '${_stats.pendingApprovals}',
                  color: FsColors.amber700)),
        ],
      ),
      const SizedBox(height: 10),
      FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Zone-wise Compliance — Bengaluru Urban',
                        style: FsText.cardTitle)),
                Text('${_zoneCompliance.length} zones', style: FsText.micro),
              ],
            ),
            const SizedBox(height: 10),
            ..._zoneCompliance.map((z) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(z.$1,
                            style: FsText.tiny,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: FsColors.gray100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: z.$3 / 100,
                              child: Container(
                                height: 16,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: _zoneColor(z.$3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${z.$3}%',
                                    style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                          width: 30,
                          child: Text('${z.$2}',
                              style: FsText.micro, textAlign: TextAlign.end)),
                    ],
                  ),
                )),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compliance by Building Type', style: FsText.cardTitle),
            const SizedBox(height: 10),
            FsHorizontalBarChart(
              data: _complianceByType
                  .map((t) => (t.$1, t.$2, t.$3))
                  .toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inspection & NOC Issuance Trend', style: FsText.cardTitle),
            SizedBox(height: 10),
            FsBarChart(
                data: _monthlyInspections, color: Color(0xFF3B82F6)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('High-Risk Buildings — Immediate Action',
                        style: FsText.cardTitle)),
                Text('${highRisk.length} buildings',
                    style: FsText.micro.copyWith(
                        color: FsColors.danger, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            ...highRisk.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: b.risk == 'CRITICAL' ? FsColors.dangerLight : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(FsRadius.xl),
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
                                Text(b.name,
                                    style: FsText.small
                                        .copyWith(fontWeight: FontWeight.w700)),
                                Text('${b.zone} · ${b.type}', style: FsText.micro),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge(status: b.noc),
                              StatusBadge(status: b.risk),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${b.violations} active violations · Last inspected ${b.lastInspection}',
                          style: FsText.micro),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ];
  }

  // ── Buildings ──────────────────────────────────────────────────────────

  List<Widget> _buildingsTab() => [
        Text('${_buildings.length} buildings', style: FsText.small),
        const SizedBox(height: 10),
        ..._buildings.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: FsText.cardTitle),
                              Text('${b.zone} · ${b.type} · ${b.floors}F+B${b.basements}',
                                  style: FsText.tiny),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: b.noc),
                            StatusBadge(status: b.risk),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                            child: ProgressBar(
                                value: b.score.toDouble(),
                                color: _scoreColor(b.score))),
                        const SizedBox(width: 8),
                        Text('${b.score}%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _scoreColor(b.score))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Area: ${b.area} · NOC: ${b.nocExpiry} · Inspected: ${b.lastInspection}',
                        style: FsText.micro),
                    if (b.violations > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FsColors.red100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            '${b.violations} violation${b.violations > 1 ? 's' : ''}',
                            style: FsText.micro.copyWith(
                                fontWeight: FontWeight.w700, color: FsColors.red700)),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ];

  // ── NOC tracker ────────────────────────────────────────────────────────

  List<Widget> _nocTab() {
    final all = _buildings.where((b) => b.noc == 'EXPIRED' || b.noc == 'EXPIRING').toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final expired = all.where((b) => b.daysLeft < 0).toList();
    final critical = all.where((b) => b.daysLeft >= 0 && b.daysLeft <= 30).toList();
    final warning = all.where((b) => b.daysLeft > 30 && b.daysLeft <= 90).toList();

    Widget section(String title, Color color, List<_Building> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: FsText.cardTitle),
                const SizedBox(width: 6),
                Text('${items.length}', style: FsText.tiny),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FsCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.name, style: FsText.cardTitle),
                              Text('${b.zone} · ${b.type}', style: FsText.tiny),
                              Text(
                                b.daysLeft < 0
                                    ? '${-b.daysLeft} days overdue'
                                    : '${b.daysLeft} days remaining',
                                style: FsText.tiny.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: b.daysLeft < 0
                                        ? FsColors.danger
                                        : FsColors.amber700),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: b.noc),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      );
    }

    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FsColors.dangerLight,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${expired.length} buildings with expired NOC · ${critical.length} expiring within 30 days',
                style: FsText.small
                    .copyWith(fontWeight: FontWeight.w700, color: FsColors.red700)),
            Text('Immediate action required. Issue notices and schedule re-inspection.',
                style: FsText.tiny.copyWith(color: FsColors.red600)),
          ],
        ),
      ),
      const SizedBox(height: 14),
      section('Expired NOC — Immediate Action', FsColors.red600, expired),
      section('Expiring ≤ 30 Days — Critical', const Color(0xFFFB923C), critical),
      section('Expiring 31–90 Days — Warning', FsColors.amber400, warning),
    ];
  }

  // ── Reports (submissions) ─────────────────────────────────────────────

  List<Widget> _reportsTab() => [
        const Text(
            'Audit reports submitted by organisations for government NOC approval',
            style: FsText.small),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: FsColors.infoLight,
            borderRadius: BorderRadius.circular(FsRadius.xl),
          ),
          child: Text(
              '${_submissions.where((s) => s.status == 'UNDER_REVIEW').length} reports pending review · Response required within 15 working days',
              style: FsText.tiny.copyWith(color: FsColors.info)),
        ),
        const SizedBox(height: 10),
        ..._submissions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.no,
                                  style: FsText.micro.copyWith(
                                      color: FsColors.info, fontWeight: FontWeight.w700)),
                              Text(s.building, style: FsText.cardTitle),
                              Text('${s.type} · ${s.org}', style: FsText.tiny),
                            ],
                          ),
                        ),
                        StatusBadge(status: s.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(value: s.score.toDouble(), color: _scoreColor(s.score)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Submitted: ${s.submitted}', style: FsText.micro),
                        Text('Auditor: ${s.auditor}', style: FsText.micro),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ];

  // ── Findings ───────────────────────────────────────────────────────────

  int? _expandedFinding;

  List<Widget> _findingsTab() {
    final unresolved = _findings.where((f) => f.status != 'RESOLVED').length;
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FsColors.dangerLight,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
        ),
        child: Text(
            '$unresolved unresolved critical violations — requiring immediate government action',
            style: FsText.small.copyWith(fontWeight: FontWeight.w700, color: FsColors.red700)),
      ),
      const SizedBox(height: 12),
      ...List.generate(_findings.length, (i) {
        final f = _findings[i];
        final open = _expandedFinding == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(status: f.severity),
                    const SizedBox(width: 6),
                    Text(f.status,
                        style: FsText.micro.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${f.daysOpen} days open', style: FsText.micro),
                  ],
                ),
                const SizedBox(height: 6),
                Text(f.building, style: FsText.cardTitle),
                Text('${f.zone} · Reported ${f.reported}', style: FsText.tiny),
                const SizedBox(height: 4),
                Text(f.finding, style: FsText.small),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _expandedFinding = open ? null : i),
                        child: Text(open ? 'Hide Details' : 'View Audit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        final ref = '${f.building}|${f.zone}|${f.finding}';
                        final busy = _escalating.contains(ref);
                        final done = _escalated.contains(ref) ||
                            f.status == 'ESCALATED';
                        return ElevatedButton(
                          onPressed: busy
                              ? null
                              : () => _escalate(f, verified: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FsColors.gray900,
                            foregroundColor: FsColors.eyYellow,
                            elevation: 0,
                          ),
                          child: Text(done ? 'Escalated' : 'Escalate'),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _escalating.contains('${f.building}|${f.zone}|${f.finding}')
                        ? null
                        : () => _escalate(f, verified: true),
                    child: const Text('Escalate via verified gateway instead',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
                if (open) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: FsColors.gray100,
                      borderRadius: BorderRadius.circular(FsRadius.xl),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recommended Action',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        _FindingDetail('NBC Reference', 'NBC 2016 Part 4, Cl. 4.4.3 — Means of Egress'),
                        _FindingDetail('Enforcement', 'Section 13(4) Karnataka Fire Services Act, 1964'),
                        _FindingDetail('Closure Timeline', '24 hours for CRITICAL · 7 days for HIGH'),
                        _FindingDetail('Escalation', 'DIG Fire Services (if no response in 48 hrs)'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ];
  }
}

class _FindingDetail extends StatelessWidget {
  final String label, value;
  const _FindingDetail(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 96, child: Text(label, style: FsText.micro)),
            Expanded(child: Text(value, style: FsText.micro)),
          ],
        ),
      );
}
