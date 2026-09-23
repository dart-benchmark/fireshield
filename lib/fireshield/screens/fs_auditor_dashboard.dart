/// Port of pwa_app/src/screens/auditor/AuditorDashboard.jsx
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_mock_data.dart';
import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class FsAuditorDashboard extends StatefulWidget {
  const FsAuditorDashboard({super.key});

  @override
  State<FsAuditorDashboard> createState() => _FsAuditorDashboardState();
}

class _FsAuditorDashboardState extends State<FsAuditorDashboard> {
  int _tab = 0; // 0 today, 1 all, 2 docs

  List<FsAudit> get _myAudits =>
      allOrgAudits.where((a) => a.auditor == 'Priya Nair' || a.auditor == 'Ravi Kumar').toList();

  @override
  Widget build(BuildContext context) {
    final user = FsAppState.instance.user;
    final myAudits = _myAudits;
    final active = myAudits.firstWhere(
      (a) => a.status == 'IN_PROGRESS',
      orElse: () => myAudits.isNotEmpty
          ? myAudits.firstWhere((a) => a.status == 'SCHEDULED',
              orElse: () => myAudits.first)
          : const FsAudit(
              id: '', no: '', facility: '', org: '', facilityId: '',
              type: '', status: 'SCHEDULED', date: '', total: 0, done: 0,
              score: 0, auditor: '', priority: 'NORMAL'),
    );
    final completed = myAudits
        .where((a) => a.status == 'APPROVED' || a.status == 'SUBMITTED')
        .length;
    final scheduled = myAudits.where((a) => a.status == 'SCHEDULED').length;
    final scored = myAudits.where((a) => a.score > 0).toList();
    final avgScore = scored.isEmpty
        ? 0
        : (scored.fold<double>(0, (s, a) => s + a.score) / scored.length)
            .round();

    return Column(
      children: [
        _buildHeader(user, myAudits, active, completed, scheduled, avgScore),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: switch (_tab) {
              1 => _allAudits(myAudits),
              2 => _documents(),
              _ => _today(myAudits),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(FsUser? user, List<FsAudit> myAudits, FsAudit active,
          int completed, int scheduled, num avgScore) =>
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                                  const Text('FIELD AUDITOR',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                          color: Color(0xFFFCA5A5))),
                                  const SizedBox(width: 6),
                                  Text(user?.org ?? 'Phoenix Group',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: FsColors.eyYellow)),
                                ],
                              ),
                              Text(
                                'Hello, ${(user?.name ?? 'Auditor').split(' ').first} 👋',
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white),
                              ),
                              Text(
                                '${myAudits.length} active assignments',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFFFCA5A5)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FsColors.eyYellow,
                            borderRadius: BorderRadius.circular(FsRadius.xl),
                          ),
                          child: Text(user?.initials ?? 'AU',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: FsColors.gray900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (active.id.isNotEmpty)
                      GestureDetector(
                        onTap: () => context.go('/audit'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(FsRadius.xl2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('CURRENT ASSIGNMENT',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFFCA5A5))),
                                        Text(active.facility,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: active.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '📋 ${active.type}  ·  📅 ${active.date}',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFFFCA5A5)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Progress',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFFCA5A5))),
                                  Text(
                                    '${active.done}/${active.total} items · ${active.progress.round()}%',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFFCA5A5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ProgressBar(
                                  value: active.progress,
                                  color: FsColors.eyYellow),
                              const SizedBox(height: 8),
                              const Text('Tap to continue →',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: FsColors.eyYellow)),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          _kpiChip('${myAudits.length}', 'Assigned', Colors.white),
                          _kpiChip('$scheduled', 'Upcoming', const Color(0xFF93C5FD)),
                          _kpiChip('$completed', 'Completed', const Color(0xFF86EFAC)),
                          _kpiChip('$avgScore%', 'Avg Score', FsColors.eyYellow),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15))),
                ),
                child: Row(
                  children: [
                    _tabButton('Today', 0),
                    _tabButton('All Audits', 1),
                    _tabButton('Documents', 2),
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
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFFFCA5A5))),
            ],
          ),
        ),
      );

  Widget _tabButton(String label, int idx) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = idx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: idx == _tab ? FsColors.eyYellow : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: idx == _tab ? FsColors.eyYellow : const Color(0xFFFCA5A5),
              ),
            ),
          ),
        ),
      );

  List<Widget> _today(List<FsAudit> myAudits) {
    final scheduled = myAudits.where((a) => a.status == 'SCHEDULED').toList();
    return [
      Text('QUICK ACTIONS',
          style: FsText.xs.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
        children: [
          _quickTile('🔍', 'Start Audit', FsColors.primary, () => context.go('/audit')),
          _quickTile('🤖', 'AI Engine', FsColors.gray900, () => context.go('/ai-engine')),
          _quickTile('🧠', 'AI Assistant', const Color(0xFF7C3AED), () => context.go('/ai')),
          _quickTile('📁', 'Documents', const Color(0xFF059669), () => setState(() => _tab = 2)),
          _quickTile('⚠️', 'My Findings', const Color(0xFFD97706), () => context.go('/audit')),
          _quickTile('📊', 'Reports', const Color(0xFF0891B2), () => context.go('/reports')),
        ],
      ),
      const SizedBox(height: 16),
      Text('UPCOMING SCHEDULE',
          style: FsText.xs.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      if (scheduled.isEmpty)
        const EmptyState(
            icon: '📅',
            title: 'No upcoming audits',
            subtitle: 'New assignments will appear here')
      else
        ...scheduled.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                onTap: () => context.go('/audit'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.no,
                              style: FsText.micro.copyWith(
                                  color: FsColors.info,
                                  fontWeight: FontWeight.w700)),
                          Text(a.facility, style: FsText.cardTitle),
                          Text(a.type, style: FsText.tiny),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(a.date,
                            style: FsText.small.copyWith(
                                color: FsColors.info,
                                fontWeight: FontWeight.w700)),
                        Text('${a.total} items', style: FsText.micro),
                      ],
                    ),
                  ],
                ),
              ),
            )),
    ];
  }

  Widget _quickTile(String icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: FsColors.border),
            boxShadow: FsShadows.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ],
          ),
        ),
      );

  List<Widget> _allAudits(List<FsAudit> myAudits) => [
        Text('ALL ASSIGNMENTS · PHOENIX GROUP',
            style: FsText.xs.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        ...myAudits.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                onTap: () => context.go('/audit'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.no,
                                  style: FsText.micro.copyWith(
                                      color: FsColors.danger,
                                      fontWeight: FontWeight.w700)),
                              Text(a.facility, style: FsText.cardTitle),
                              Text('${a.type} · ${a.date}', style: FsText.tiny),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: a.status),
                            if (a.score > 0)
                              Text('${a.score}%',
                                  style: FsText.small.copyWith(
                                      color: FsColors.info,
                                      fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ProgressBar(
                            value: a.progress,
                            color: a.score >= 80
                                ? FsColors.success
                                : a.score >= 60
                                    ? FsColors.warning
                                    : a.status == 'SCHEDULED'
                                        ? const Color(0xFF93C5FD)
                                        : FsColors.danger,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${a.done}/${a.total}', style: FsText.tiny),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ];

  List<Widget> _documents() {
    final docs = [
      ('📄', 'Fire NOC Certificate', 'VALID', '01 Jun 2026', 4),
      ('📐', 'Approved Floor Plan', 'VALID', '15 Mar 2026', 12),
      ('🚪', 'Evacuation Plan', 'EXPIRED', '20 Dec 2023', 2),
    ];
    return [
      const FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phoenix Marketcity Bengaluru', style: FsText.title),
            Text('Bengaluru, Karnataka · Facility Documents', style: FsText.tiny),
          ],
        ),
      ),
      const SizedBox(height: 10),
      ...docs.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FsCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(d.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.$2, style: FsText.cardTitle),
                            Text('Uploaded: ${d.$4} · ${d.$5} pages',
                                style: FsText.tiny),
                          ],
                        ),
                      ),
                      StatusBadge(status: d.$3 == 'VALID' ? 'Valid' : 'Expired'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => context.go('/audit'),
                      child: const Text('👁 View Document'),
                    ),
                  ),
                ],
              ),
            ),
          )),
    ];
  }
}
