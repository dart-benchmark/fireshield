/// Port of pwa_app/src/screens/admin/AdminDashboard.jsx (672 lines).
///
/// Ported directly from source this time — the platform-wide `adminStats`,
/// `adminNotifications` (20) and `allUsers` (20) constants are reproduced
/// verbatim, not approximated. Charts (Audits by Month, Facilities by
/// State, Risk Distribution, Compliance Trend) use the same data points as
/// the PWA via [FsBarChart]/[FsHorizontalBarChart]/[FsDonutChart]/[FsTrendLine].
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_mock_data.dart';
import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_charts.dart';
import '../widgets/fs_ui.dart';

// ── Platform stats — verbatim from AdminDashboard.jsx `adminStats` ─────────
const _totalOrgs = 247;
const _totalFacilities = 1834;
const _totalBuildings = 3291;
const _totalUsers = 8420;
const _orgAdmins = 48;
const _complianceScore = 84;
const _pendingAudits = 15;
const _openFindings = 40;
const _totalAudits = 12847;

const _auditsByMonth = [
  ('Jan', 58), ('Feb', 72), ('Mar', 91), ('Apr', 84), ('May', 103),
  ('Jun', 76), ('Jul', 68), ('Aug', 89), ('Sep', 97), ('Oct', 112),
  ('Nov', 88), ('Dec', 104),
];
const _facilitiesByState = [
  ('Karnataka', 9), ('Maharashtra', 5), ('Delhi', 3),
  ('Tamil Nadu', 3), ('Haryana', 3), ('Gujarat', 2),
];
const _riskDist = [('LOW', 14, FsColors.green500), ('MEDIUM', 8, FsColors.amber400), ('HIGH', 3, FsColors.red600)];
const _complianceTrend = [76, 78, 79, 81, 82, 84, 84];
const _complianceTrendMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
const _stateColors = [
  FsColors.eyYellow, FsColors.primary, FsColors.gray900,
  Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981),
];

// ── Notifications — verbatim from `adminNotifications` (20) ────────────────
class _Notif {
  final String icon, title, body, time, severity;
  final bool read;
  const _Notif(this.icon, this.title, this.body, this.time, this.read, this.severity);
}

const _notifications = [
  _Notif('📋', 'Audit due in 3 days', 'Phoenix Mall Bengaluru — AUD-202606-1091', '2h ago', false, 'HIGH'),
  _Notif('💧', 'Hydrant inspection overdue', 'L&T Manufacturing Plant — 22 days overdue', '4h ago', false, 'CRITICAL'),
  _Notif('📄', 'Fire NOC expires in 45 days', 'Prestige Tech Park Bengaluru — NOC: 30 Jul 2026', '6h ago', false, 'HIGH'),
  _Notif('⚠️', 'Critical finding unresolved', 'Apollo Hospital Delhi — Exit door locked', '8h ago', false, 'CRITICAL'),
  _Notif('🎓', 'Fire warden training due', 'DLF Cyber City Gurugram — 4 wardens untrained', '1d ago', true, 'MEDIUM'),
  _Notif('🔔', 'Fire drill pending', 'Infosys Campus Mysuru — Last drill: Jan 2024', '1d ago', true, 'MEDIUM'),
  _Notif('🧯', 'Extinguisher service overdue', 'Adani Mundra Port — 18 units past service date', '2d ago', true, 'HIGH'),
  _Notif('📊', 'Monthly compliance report ready', 'May 2026 platform-wide report generated', '2d ago', true, 'LOW'),
  _Notif('👤', 'New user registration request', 'Sanjay Mehta — Auditor — BEL Bengaluru', '3d ago', true, 'LOW'),
  _Notif('✅', 'Audit approved', 'Infosys Campus OISD Audit — Score: 78.1%', '3d ago', true, 'LOW'),
  _Notif('🔴', 'Smoke detector fault', 'TCS Olympus Campus — 3 zones offline', '4d ago', true, 'CRITICAL'),
  _Notif('📅', 'Annual pump test overdue', 'BEL Electronics Complex — Last test: Dec 2023', '4d ago', true, 'HIGH'),
  _Notif('🏢', 'New organization registered', 'Wipro Limited — 5 facilities added', '5d ago', true, 'LOW'),
  _Notif('📁', 'Occupancy certificate expired', 'L&T Manufacturing Plant Chennai', '5d ago', true, 'HIGH'),
  _Notif('🌊', 'Sprinkler valve found closed', 'Brigade Gateway Bengaluru — B2 zone', '6d ago', true, 'CRITICAL'),
  _Notif('💡', 'Emergency light battery low', 'Phoenix Mall — 7 units below threshold', '6d ago', true, 'MEDIUM'),
  _Notif('📋', 'CAPA closure rate update', 'Platform: 68% CAPAs closed this month', '7d ago', true, 'LOW'),
  _Notif('🔖', 'Building classification pending', '3 buildings without NBC classification', '7d ago', true, 'MEDIUM'),
  _Notif('📞', 'Government inspection notice', 'DLF Cyber City — Joint inspection 20 Jun', '8d ago', true, 'HIGH'),
  _Notif('✅', 'NOC renewed successfully', 'Apollo Hospital Delhi — Valid until Sep 2026', '9d ago', true, 'LOW'),
];

// ── Users — verbatim from `allUsers` (20) ───────────────────────────────────
class _AdminUser {
  final String name, role, facility, status, dept;
  const _AdminUser(this.name, this.role, this.facility, this.status, this.dept);
}

const _allUsers = [
  _AdminUser('Rajesh Kumar', 'manager', 'Phoenix Mall, Bengaluru', 'ACTIVE', 'Fire Safety'),
  _AdminUser('Priya Nair', 'auditor', 'Phoenix Mall, Bengaluru', 'ACTIVE', 'Compliance'),
  _AdminUser('Admin User', 'admin', 'All Facilities', 'ACTIVE', 'Platform'),
  _AdminUser('Ananya Sharma', 'manager', 'Apollo Hospital, Delhi', 'ACTIVE', 'Safety'),
  _AdminUser('Vikram Singh', 'auditor', 'Infosys Mysuru', 'ON_LEAVE', 'Audit'),
  _AdminUser('Divya Menon', 'auditor', 'DLF Cyber City', 'ACTIVE', 'Audit'),
  _AdminUser('Suresh Reddy', 'manager', 'L&T Chennai', 'ACTIVE', 'Safety'),
  _AdminUser('Kavitha Rajan', 'auditor', 'Prestige Tech Park', 'ACTIVE', 'Audit'),
  _AdminUser('Arjun Patel', 'manager', 'Adani Mundra', 'INACTIVE', 'Safety'),
  _AdminUser('Meena Iyer', 'auditor', 'TCS Mumbai', 'ACTIVE', 'Audit'),
  _AdminUser('Shri A.K. Sharma', 'govt', 'Karnataka Fire Services', 'ACTIVE', 'Government'),
  _AdminUser('Ramesh Gupta', 'auditor', 'BEL Bengaluru', 'ACTIVE', 'Audit'),
  _AdminUser('Nandita Roy', 'manager', 'Brigade Gateway', 'ACTIVE', 'Safety'),
  _AdminUser('Dr. Sunita Verma', 'govt', 'Maharashtra Fire Services', 'ACTIVE', 'Government'),
  _AdminUser('Sanjay Mehta', 'auditor', 'L&T Chennai', 'ACTIVE', 'Audit'),
  _AdminUser('Lalitha Krishnan', 'manager', 'Infosys Mysuru', 'ACTIVE', 'Safety'),
  _AdminUser('Arun Pillai', 'auditor', 'DLF Cyber City', 'INACTIVE', 'Audit'),
  _AdminUser('Geeta Iyer', 'admin', 'All Facilities', 'ACTIVE', 'Platform'),
  _AdminUser('Mohammed Irfan', 'auditor', 'Phoenix Mall', 'ACTIVE', 'Audit'),
  _AdminUser('Preethi Kumar', 'manager', 'Prestige Tech Park', 'ACTIVE', 'Safety'),
];

const Map<String, Color> _roleColor = {
  'admin': Color(0xFFA855F7),
  'manager': FsColors.roleManager,
  'auditor': FsColors.roleAuditor,
  'govt': Color(0xFF15803D),
};

class FsAdminDashboard extends StatefulWidget {
  final String? tab;
  const FsAdminDashboard({super.key, this.tab});

  @override
  State<FsAdminDashboard> createState() => _FsAdminDashboardState();
}

class _FsAdminDashboardState extends State<FsAdminDashboard> {
  static const _tabs = ['Overview', 'Orgs', 'Facilities', 'Users', 'Activity'];
  late int _tab = switch (widget.tab) {
    'orgs' => 1,
    'facilities' => 2,
    'users' => 3,
    'activity' => 4,
    'analytics' => 0,
    _ => 0,
  };
  bool _notifOpen = false;

  final _unread = _notifications.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    final user = FsAppState.instance.user;

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(user?.initials ?? 'AU'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: switch (_tab) {
                  1 => _orgsTab(),
                  2 => _facilitiesTab(),
                  3 => _usersTab(),
                  4 => _activityTab(),
                  _ => _overviewTab(context),
                },
              ),
            ),
          ],
        ),
        if (_notifOpen) _buildNotifDrawer(),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(String initials) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2D1B6B)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Platform Admin',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: FsColors.gray400,
                                      fontWeight: FontWeight.w500)),
                              const Text('FireShield AI™',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.2)),
                              Text('by EY · Powered by EY',
                                  style: FsText.tiny.copyWith(
                                      color: FsColors.eyYellow,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _notifOpen = true),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(FsRadius.xl),
                                ),
                                child: const Text('🔔',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            if (_unread > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_unread',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FsColors.eyYellow,
                            borderRadius: BorderRadius.circular(FsRadius.xl),
                          ),
                          child: Text(initials,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: FsColors.gray900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _kpiChip('$_totalOrgs', 'Orgs', FsColors.eyYellow),
                        _kpiChip('$_totalFacilities', 'Facilities', FsColors.eyYellow),
                        _kpiChip('$_totalAudits', 'Audits', FsColors.eyYellow),
                        _kpiChip('$_totalUsers', 'Users', FsColors.eyYellow),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _kpiChip('$_pendingAudits', 'Pending', const Color(0xFFFBBF24)),
                        _kpiChip('$_openFindings', 'Open CAs', const Color(0xFFF87171)),
                        _kpiChip('$_complianceScore%', 'Compliance', const Color(0xFFC4B5FD)),
                        _kpiChip('$_orgAdmins', 'Org Admins', const Color(0xFF6EE7B7)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 2,
                                  color: i == _tab
                                      ? FsColors.eyYellow
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: Text(
                              _tabs[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: i == _tab
                                    ? FsColors.eyYellow
                                    : FsColors.gray400,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _kpiChip(String value, String label, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(FsRadius.xl),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 8.5,
                      color: FsColors.gray300,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );

  // ── Overview tab ───────────────────────────────────────────────────────

  List<Widget> _overviewTab(BuildContext context) => [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _govCard('🏢', '$_totalOrgs', 'Total Organisations', const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
            _govCard('🏗️', '$_totalFacilities', 'Total Facilities', const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)),
            _govCard('🏛️', '$_totalBuildings', 'Total Buildings', const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
            _govCard('👥', '$_totalUsers', 'Total Users', FsColors.gray700, FsColors.gray100),
            _govCard('🛡️', '$_orgAdmins', 'Org Admins', const Color(0xFF047857), const Color(0xFFECFDF5)),
            _govCard('📋', '$_totalAudits', 'Total Audits Conducted', const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
          ],
        ),
        const SizedBox(height: 16),
        Text('QUICK ACTIONS',
            style: FsText.xs
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.85,
          children: [
            _quickAction('🏢', 'Register Organisation', 'Name → Building → Fire NOC',
                const Color(0xFF7C3AED), () => context.push('/admin/register-org')),
            _quickAction('👤', 'Create User', 'Safety Manager / Auditor',
                const Color(0xFF16A34A), () => context.push('/admin/create-user')),
            _quickAction('📊', 'View Analytics', 'Reports & Dashboards',
                FsColors.gray700, () => context.go('/reports')),
            _quickAction('🤖', 'AI Assistant', 'NBC 2026 Queries',
                FsColors.roleAuditor, () => context.go('/ai')),
          ],
        ),
        const SizedBox(height: 16),
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('Audits by Month', style: FsText.cardTitle),
                  Spacer(),
                  Text('Last 6 months', style: FsText.micro),
                ],
              ),
              const SizedBox(height: 10),
              FsBarChart(
                data: _auditsByMonth.sublist(6).map((e) => (e.$1, e.$2)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Facilities by State', style: FsText.cardTitle),
              const SizedBox(height: 10),
              FsHorizontalBarChart(
                data: [
                  for (var i = 0; i < _facilitiesByState.length; i++)
                    (
                      _facilitiesByState[i].$1,
                      _facilitiesByState[i].$2,
                      _stateColors[i % _stateColors.length],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Risk Distribution', style: FsText.cardTitle),
              const SizedBox(height: 12),
              Row(
                children: [
                  FsDonutChart(
                    segments: _riskDist.map((r) => (r.$2, r.$3)).toList(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: _riskDist
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: r.$3,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text('${r.$1} Risk',
                                            style: FsText.small)),
                                    Text('${r.$2}',
                                        style: FsText.small.copyWith(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
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
                  const Text('Compliance Trend', style: FsText.cardTitle),
                  const Spacer(),
                  Text('↑ +3.2%',
                      style: FsText.small.copyWith(
                          color: FsColors.green700,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              const FsTrendLine(values: _complianceTrend),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _complianceTrendMonths
                    .map((m) => Text(m, style: FsText.micro))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Platform Stats', style: FsText.cardTitle),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.1,
                children: [
                  _statTile('📋', 'Total Audits', '$_totalAudits', FsColors.info),
                  _statTile('👥', 'Active Users', '87 / 100', FsColors.success),
                  _statTile('📊', 'Avg Score', '74.3%', FsColors.amber700),
                  _statTile('⚠️', 'Pending NCRs', '$_openFindings', FsColors.danger),
                  _statTile('🔗', 'APIs Online', '12 / 12', FsColors.success),
                  _statTile('⚡', 'Uptime', '99.8%', FsColors.info),
                ],
              ),
            ],
          ),
        ),
      ];

  Widget _govCard(String icon, String value, String label, Color fg, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: fg)),
                  Text(label,
                      style: FsText.micro,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _quickAction(String icon, String label, String sub, Color color,
          VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: FsColors.border),
            boxShadow: FsShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Color(0xFF1F2937))),
                    Text(sub, style: FsText.micro, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statTile(String icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FsColors.gray100,
          borderRadius: BorderRadius.circular(FsRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: FsText.micro)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      );

  // ── Orgs tab ───────────────────────────────────────────────────────────

  List<Widget> _orgsTab() => [
        Text('${organizations.length} Organisations',
            style: FsText.cardTitle),
        const SizedBox(height: 10),
        ...organizations.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(o.name,
                              style: FsText.cardTitle,
                              overflow: TextOverflow.ellipsis),
                        ),
                        StatusBadge(status: o.risk),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${o.industry} · ${o.state}', style: FsText.tiny),
                    Text('GST: ${o.gst}', style: FsText.tiny),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child:
                                _miniStat('Facilities', '${o.facilities}')),
                        Expanded(
                            child: _miniStat('Buildings',
                                '${(o.facilities * 1.8).round()}')),
                        Expanded(
                            child: _miniStat(
                                'Users', '${o.facilities * 4}')),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ];

  Widget _miniStat(String label, String value) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: FsColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
            Text(label, style: FsText.micro),
          ],
        ),
      );

  // ── Facilities tab ─────────────────────────────────────────────────────

  List<Widget> _facilitiesTab() => [
        Text('${mockFacilities.length} Facilities', style: FsText.cardTitle),
        const SizedBox(height: 10),
        ...mockFacilities.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(f.name,
                                style: FsText.cardTitle,
                                overflow: TextOverflow.ellipsis)),
                        StatusBadge(status: f.risk),
                      ],
                    ),
                    Text('${f.type} · ${f.city}, ${f.state}',
                        style: FsText.tiny),
                    Text(f.org, style: FsText.tiny),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: ProgressBar(
                                value: f.compliance.toDouble(),
                                color: FsColors.green500)),
                        const SizedBox(width: 8),
                        Text('${f.compliance}%',
                            style: FsText.small
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${f.floors}F + ${f.basements}B · ${f.area}',
                            style: FsText.micro),
                        Text('NOC: ${f.nocExpiry}',
                            style: FsText.micro.copyWith(
                                color: f.noc == 'Expiring'
                                    ? FsColors.amber700
                                    : f.noc == 'Expired'
                                        ? FsColors.danger
                                        : FsColors.green700)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ];

  // ── Users tab ──────────────────────────────────────────────────────────

  String _usersFilter = 'all';

  List<Widget> _usersTab() {
    final filtered = _usersFilter == 'all'
        ? _allUsers
        : _allUsers.where((u) => u.role == _usersFilter).toList();

    return [
      Row(
        children: [
          Expanded(
              child: Text('${_allUsers.length} Users',
                  style: FsText.cardTitle)),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: ['all', 'admin', 'manager', 'auditor', 'govt']
              .map((r) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _usersFilter = r),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _usersFilter == r
                              ? FsColors.gray900
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(FsRadius.full),
                          border: Border.all(color: FsColors.border),
                        ),
                        child: Text(
                          r == 'all'
                              ? 'All'
                              : '${r[0].toUpperCase()}${r.substring(1)}'
                                  ' (${_allUsers.where((u) => u.role == r).length})',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _usersFilter == r
                                ? FsColors.eyYellow
                                : FsColors.gray600,
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 10),
      Text('Showing ${filtered.length} of ${_allUsers.length} users',
          style: FsText.micro),
      const SizedBox(height: 8),
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
                      color: _roleColor[u.role] ?? FsColors.subtle,
                      borderRadius: BorderRadius.circular(FsRadius.xl),
                    ),
                    child: Text(
                      u.name
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join(),
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
                        Text(u.name, style: FsText.cardTitle),
                        Text(u.facility,
                            style: FsText.tiny,
                            overflow: TextOverflow.ellipsis),
                        Text('${u.role} · ${u.dept}', style: FsText.micro),
                      ],
                    ),
                  ),
                  StatusBadge(status: u.status == 'ACTIVE' ? 'APPROVED' : u.status == 'ON_LEAVE' ? 'PENDING_REVIEW' : 'CANCELLED'),
                ],
              ),
            ),
          )),
    ];
  }

  // ── Activity tab ───────────────────────────────────────────────────────

  List<Widget> _activityTab() => [
        const Text('Activity Timeline', style: FsText.title),
        const SizedBox(height: 4),
        Text('${_notifications.length} events', style: FsText.tiny),
        const SizedBox(height: 12),
        ..._notifications.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FsCard(
                child: Row(
                  children: [
                    Text(n.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title,
                              style: FsText.small
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Text(n.body, style: FsText.tiny),
                          Text(n.time, style: FsText.micro),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ];

  // ── Notification drawer ────────────────────────────────────────────────

  Widget _buildNotifDrawer() => Positioned.fill(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _notifOpen = false),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(FsRadius.xl3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Notifications',
                                    style: FsText.title),
                                Text(
                                    '$_unread unread · ${_notifications.length} total',
                                    style: FsText.tiny),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _notifOpen = false),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: FsColors.gray100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _notifications
                            .map((n) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: n.read
                                        ? FsColors.gray100
                                        : FsColors.infoLight,
                                    borderRadius:
                                        BorderRadius.circular(FsRadius.xl),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(n.icon,
                                          style:
                                              const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(n.title,
                                                style: FsText.small.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text(n.body, style: FsText.tiny),
                                            Text(n.time, style: FsText.micro),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
