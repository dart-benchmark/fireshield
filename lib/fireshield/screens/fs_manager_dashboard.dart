import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_mock_data.dart';
import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_dashboard_header.dart';
import '../widgets/fs_ui.dart';

/// Port of pwa_app/src/screens/manager/ManagerDashboard.jsx
///
/// Blue gradient header with a facility picker and the Fire Readiness Index,
/// four live KPIs, then four tabs: Dashboard, Audits, Issues, Reports.
class FsManagerDashboard extends StatefulWidget {
  const FsManagerDashboard({super.key});

  @override
  State<FsManagerDashboard> createState() => _FsManagerDashboardState();
}

class _FsManagerDashboardState extends State<FsManagerDashboard> {
  static const _tabs = ['Dashboard', 'Audits', 'Issues', 'Reports'];

  int _tab = 0;
  String _facilityId = 'F001';

  List<FsFacility> get _facilities =>
      mockFacilities.where((f) => f.org == 'Phoenix Group').toList();

  FsFacility get _facility => _facilities.firstWhere(
        (f) => f.id == _facilityId,
        orElse: () => _facilities.first,
      );

  List<FsAudit> get _audits =>
      allOrgAudits.where((a) => a.org == 'Phoenix Group').toList();

  @override
  Widget build(BuildContext context) {
    final user = FsAppState.instance.user;
    final f = _facility;
    final openAudits = _audits
        .where((a) => a.status == 'IN_PROGRESS' || a.status == 'SCHEDULED')
        .length;
    final openCas = correctiveActions.where((c) => c.isOpen).length;
    final overdue =
        correctiveActions.where((c) => c.status == 'OVERDUE').length;

    return Column(
      children: [
        FsDashboardHeader(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          ),
          eyebrow: 'SAFETY MANAGER',
          org: user?.org ?? 'Phoenix Group',
          title: f.name,
          subtitle:
              '${f.city}, ${f.state} · ${_facilities.length} facilities',
          initials: user?.initials ?? 'PS',
          onTitleTap: _pickFacility,
          hero: _buildFri(f),
          kpis: [
            ('$openAudits', 'Open Audits', null),
            ('$openCas', 'Open CAs', null),
            ('${_facilities.length}', 'Facilities', null),
            ('$overdue', 'Overdue', FsColors.red400),
          ],
          tabs: _tabs,
          activeTab: _tab,
          onTab: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: switch (_tab) {
            1 => _buildAudits(),
            2 => _buildIssues(),
            3 => _buildReports(),
            _ => _buildDashboard(),
          },
        ),
      ],
    );
  }

  // ─── Header hero ────────────────────────────────────────────────────────

  Widget _buildFri(FsFacility f) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(FsRadius.xl2),
        ),
        child: Row(
          children: [
            ScoreRing(score: f.fri, size: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fire Readiness Index',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${f.type} · ${f.city}',
                    style: const TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: FsColors.amber400.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(FsRadius.full),
                        ),
                        child: Text(
                          f.risk,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'NOC: ${f.nocExpiry}',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFBFDBFE)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _pickFacility() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FsRadius.xl3)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Facility',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: FsColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Phoenix Group · ${_facilities.length} facilities',
                style: FsText.tiny,
              ),
              const SizedBox(height: 16),
              ..._facilities.map(
                (f) => GestureDetector(
                  onTap: () => Navigator.pop(ctx, f.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: f.id == _facilityId
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(FsRadius.xl),
                      border: Border.all(
                        color: f.id == _facilityId
                            ? const Color(0xFF93C5FD)
                            : FsColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: FsColors.gray900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('${f.city}, ${f.state} · ${f.type}',
                                  style: FsText.tiny),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: f.compliance >= 85
                                ? FsColors.green100
                                : f.compliance >= 70
                                    ? FsColors.amber100
                                    : FsColors.red100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${f.compliance}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: f.compliance >= 85
                                  ? FsColors.green700
                                  : f.compliance >= 70
                                      ? FsColors.amber700
                                      : FsColors.red700,
                            ),
                          ),
                        ),
                        if (f.id == _facilityId) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check,
                              size: 16, color: Color(0xFF2563EB)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _facilityId = picked);
  }

  // ─── Tabs ───────────────────────────────────────────────────────────────

  Widget _buildDashboard() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _label('QUICK ACTIONS'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            children: [
              _action('📁', 'Upload Documents', const Color(0xFF2563EB),
                  () => _todo('Upload Documents')),
              _action('📋', 'Assign Audit', const Color(0xFF16A34A),
                  () => context.go('/manager/assign')),
              _action('⚠️', 'Corrective Actions', const Color(0xFFF59E0B),
                  () => setState(() => _tab = 2)),
              _action('📊', 'Generate Report', const Color(0xFF9333EA),
                  () => setState(() => _tab = 3)),
              _action('🤖', 'AI Audit Engine', FsColors.gray900,
                  () => context.go('/ai-engine')),
              _action('🏆', 'NOC Readiness', const Color(0xFF4F46E5),
                  () => context.go('/manager/noc')),
              _action('🧯', 'Equipment Inventory', FsColors.gray700,
                  () => context.go('/manager/equipment')),
              _action('🧑‍🏫', 'Training & Drills', const Color(0xFF15803D),
                  () => context.go('/manager/training')),
            ],
          ),
          const SizedBox(height: 20),
          _label('RECENT AUDITS'),
          ..._audits.take(3).map(_auditCard),
          const SizedBox(height: 12),
          FsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Corrective Actions',
                  action: 'View All →',
                  onAction: () => setState(() => _tab = 2),
                ),
                Row(
                  children: [
                    for (final s in const [
                      ('Critical', 'CRITICAL'),
                      ('Major', 'MAJOR'),
                      ('Minor', 'MINOR'),
                    ]) ...[
                      if (s.$1 != 'Critical') const SizedBox(width: 8),
                      Expanded(
                        child: _severityTile(
                          s.$1,
                          correctiveActions
                              .where((c) => c.severity == s.$2)
                              .length,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildAudits() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _label('ALL AUDITS · ${_audits.length}'),
          ..._audits.map(_auditCard),
        ],
      );

  Widget _buildIssues() {
    final open = correctiveActions.where((c) => c.isOpen).length;
    final overdue =
        correctiveActions.where((c) => c.status == 'OVERDUE').length;
    final closed =
        correctiveActions.where((c) => c.status == 'CLOSED').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: KpiCard(
                  icon: '📂',
                  label: 'Open',
                  value: '$open',
                  color: FsColors.warning),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                  icon: '⏰',
                  label: 'Overdue',
                  value: '$overdue',
                  color: FsColors.danger),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                  icon: '✅',
                  label: 'Closed',
                  value: '$closed',
                  color: FsColors.success),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _label('CORRECTIVE ACTIONS'),
        ...correctiveActions.map(_caCard),
      ],
    );
  }

  Widget _buildReports() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _label('GENERATE REPORT'),
          ...const [
            ('📄', 'Audit Summary Report', 'PDF · 12–18 pages'),
            ('🏆', 'NOC Readiness Certificate', 'PDF · Official Format'),
            ('📊', 'Risk Register', 'NBC 2026 Gap Mapping'),
            ('🏛️', 'Govt Submission Package', 'Regulatory Format'),
          ].map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                onTap: () => _todo(r.$2),
                child: Row(
                  children: [
                    Text(r.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$2, style: FsText.cardTitle),
                          const SizedBox(height: 2),
                          Text(r.$3, style: FsText.tiny),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: FsColors.subtle),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  // ─── Pieces ─────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: FsText.xs.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _action(String icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FsColors.card,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: FsColors.border),
            boxShadow: FsShadows.card,
          ),
          child: Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _auditCard(FsAudit a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FsCard(
          onTap: () => context.go('/audit'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.facility,
                      style: FsText.cardTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: a.status),
                ],
              ),
              const SizedBox(height: 4),
              Text('${a.type} · ${a.date}', style: FsText.tiny),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ProgressBar(
                      value: a.progress,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${a.done}/${a.total}',
                    style: FsText.tiny.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FsColors.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _caCard(FsCorrectiveAction c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(c.no,
                      style: FsText.tiny
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  StatusBadge(status: c.severity),
                  const Spacer(),
                  StatusBadge(status: c.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.title, style: FsText.cardTitle),
              const SizedBox(height: 4),
              Text('${c.std} · ${c.category}',
                  style: FsText.tiny.copyWith(color: FsColors.info)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: FsColors.subtle),
                  const SizedBox(width: 4),
                  Expanded(child: Text(c.assigned, style: FsText.tiny)),
                  const Icon(Icons.event_outlined,
                      size: 14, color: FsColors.subtle),
                  const SizedBox(width: 4),
                  Text(c.due, style: FsText.tiny),
                  const SizedBox(width: 10),
                  Text(
                    c.cost,
                    style: FsText.tiny.copyWith(
                      fontWeight: FontWeight.w700,
                      color: FsColors.gray700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _severityTile(String label, int count) {
    final (bg, fg) = switch (label) {
      'Critical' => (const Color(0xFFFEF2F2), FsColors.red600),
      'Major' => (const Color(0xFFFFFBEB), FsColors.amber700),
      _ => (const Color(0xFFF0FDF4), FsColors.green700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FsRadius.xl),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
          Text(label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  void _todo(String what) => FsToast.show(
        context,
        '$what is not wired up in this build.',
        type: FsToastType.info,
      );
}
