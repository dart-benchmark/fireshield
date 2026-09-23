import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class SafetyManagerDashboard extends StatefulWidget {
  final MockUser user;
  const SafetyManagerDashboard({super.key, required this.user});
  @override State<SafetyManagerDashboard> createState() => _State();
}

class _State extends State<SafetyManagerDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(user: widget.user),
          _AuditsTab(user: widget.user),
          _ComplianceTab(user: widget.user),
          _ReportsTab(user: widget.user),
          _ProfileTab(user: widget.user),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Audits'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_rounded), label: 'Compliance'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final MockUser user;
  const _DashboardTab({required this.user});

  @override
  Widget build(BuildContext context) {
    const stats = DashboardStats.smStats;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text(user.photoInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good Morning, ${user.name.split(' ').first}!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(user.facility, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      )),
                      Stack(
                        children: [
                          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => context.push('/notifications')),
                          Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeaderPill(label: 'Fire Readiness Index', value: '${stats['compliance']}%', color: Colors.greenAccent),
                      const SizedBox(width: 12),
                      _HeaderPill(label: 'Open CAs', value: '${stats['openCAs']}', color: Colors.orangeAccent),
                      const SizedBox(width: 12),
                      _HeaderPill(label: 'NOC Expiry', value: '${stats['nocDaysLeft']}d', color: Colors.yellowAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white), onPressed: () {}),
          ],
          title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert banner
                if ((stats['nocDaysLeft'] as int) < 40)
                  _AlertBanner(
                    message: '⚠️  Fire NOC expires in ${stats['nocDaysLeft']} days — initiate renewal immediately.',
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                const SizedBox(height: 16),

                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(label: 'Compliance Score', value: '${stats['compliance']}%', icon: Icons.verified_rounded, color: AppColors.success, subtitle: 'Good', onTap: () {}),
                    StatCard(label: 'Open Corrective Actions', value: '${stats['openCAs']}', icon: Icons.assignment_late_rounded, color: AppColors.warning, subtitle: '${stats['criticalCAs']} Critical', onTap: () => context.push('/corrective-actions')),
                    StatCard(label: 'Pending Audits', value: '${stats['pendingAudits']}', icon: Icons.assignment_rounded, color: AppColors.secondary, onTap: () {}),
                    StatCard(label: 'Equipment Due Service', value: '${stats['equipmentDue']}', icon: Icons.build_rounded, color: AppColors.error, subtitle: 'Urgent', onTap: () => context.push('/equipment')),
                  ],
                ),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Facility Overview'),
                const SizedBox(height: 12),
                _FacilityCard(facility: mockFacilities[0]),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Compliance by System'),
                const SizedBox(height: 12),
                _ComplianceSystemsCard(),

                const SizedBox(height: 24),
                SectionHeader(title: 'Recent Corrective Actions', actionLabel: 'View All', onAction: () => context.push('/corrective-actions')),
                const SizedBox(height: 8),
                ...mockCAs.take(3).map((ca) => _CaCard(ca: ca)),

                const SizedBox(height: 24),
                SectionHeader(title: 'Upcoming Compliance Tasks', actionLabel: 'Calendar', onAction: () {}),
                const SizedBox(height: 8),
                _ComplianceCalendar(),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActions(user: user),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderPill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
    ]),
  );
}

class _AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final VoidCallback? onTap;
  const _AlertBanner({required this.message, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500))),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
      ]),
    ),
  );
}

class _FacilityCard extends StatelessWidget {
  final MockFacility facility;
  const _FacilityCard({required this.facility});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))]),
    child: Column(
      children: [
        Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(facility.name, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${facility.type}  ·  ${facility.location}', style: AppTextStyles.caption),
              ],
            )),
            RiskTag(level: facility.riskLevel),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ScoreRing(score: facility.fri, label: 'FRI', size: 80, strokeWidth: 8)),
            const SizedBox(width: 20),
            const Expanded(flex: 2, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledProgressBar(label: 'Fire Exits', value: '88%', progress: 0.88, color: AppColors.success),
                SizedBox(height: 8),
                LabeledProgressBar(label: 'Equipment', value: '72%', progress: 0.72, color: AppColors.warning),
                SizedBox(height: 8),
                LabeledProgressBar(label: 'Detection', value: '91%', progress: 0.91, color: AppColors.success),
                SizedBox(height: 8),
                LabeledProgressBar(label: 'Suppression', value: '65%', progress: 0.65, color: AppColors.riskMedium),
              ],
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FacilityStat(label: 'Last Audit', value: facility.lastAudit),
            _FacilityStat(label: 'NOC Status', value: facility.nocStatus, color: facility.nocStatus == 'Valid' ? AppColors.success : AppColors.warning),
            _FacilityStat(label: 'NOC Expiry', value: facility.nocExpiry),
          ],
        ),
      ],
    ),
  );
}

class _FacilityStat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _FacilityStat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.label.copyWith(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w600)),
    ],
  );
}

class _ComplianceSystemsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final systems = [
      ('Fire Exits', 0.88, AppColors.success),
      ('Extinguishers', 0.72, AppColors.warning),
      ('Detection System', 0.91, AppColors.success),
      ('Suppression', 0.65, AppColors.riskMedium),
      ('Emergency Lighting', 0.80, AppColors.success),
      ('Hydrant System', 0.78, AppColors.info),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: systems.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: LabeledProgressBar(label: s.$1, value: '${(s.$2 * 100).toInt()}%', progress: s.$2, color: s.$3),
        )).toList(),
      ),
    );
  }
}

class _CaCard extends StatelessWidget {
  final MockCA ca;
  const _CaCard({required this.ca});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/corrective-actions'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Container(
            width: 4, height: 52,
            decoration: BoxDecoration(
              color: ca.severity == 'CRITICAL' ? AppColors.error : ca.severity == 'MAJOR' ? AppColors.warning : AppColors.info,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ca.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Text(ca.caNo, style: AppTextStyles.caption),
                const SizedBox(width: 8),
                SeverityBadge(severity: ca.severity),
              ]),
            ],
          )),
          const SizedBox(width: 8),
          StatusBadge(status: ca.status),
        ],
      ),
    ),
  );
}

class _ComplianceCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = [
      ('Fire Drill (Quarterly)', '20 Jun 2026', AppColors.warning, Icons.campaign_rounded),
      ('AMC Visit — Detector System', '25 Jun 2026', AppColors.info, Icons.build_circle_rounded),
      ('Fire NOC Renewal', '01 Jul 2026', AppColors.error, Icons.assignment_rounded),
      ('Monthly Extinguisher Inspection', '30 Jun 2026', AppColors.success, Icons.fire_extinguisher_rounded),
    ];
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: tasks.asMap().entries.map((e) {
          final (title, date, color, icon) = e.value;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
                title: Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                trailing: Text(date, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
              ),
              if (e.key < tasks.length - 1) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final MockUser user;
  const _QuickActions({required this.user});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Start Audit', Icons.play_circle_rounded, AppColors.primary, () => context.push('/audit-execution')),
      ('Equipment', Icons.inventory_2_rounded, AppColors.secondary, () => context.push('/equipment')),
      ('Corrective Actions', Icons.assignment_late_rounded, AppColors.warning, () => context.push('/corrective-actions')),
      ('AI Assistant', Icons.smart_toy_rounded, AppColors.info, () => context.push('/ai-assistant')),
      ('Reports', Icons.bar_chart_rounded, AppColors.success, () => context.push('/reports')),
      ('Documents', Icons.folder_rounded, AppColors.riskMedium, () {}),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) => GestureDetector(
        onTap: a.$4,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: a.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(a.$2, color: a.$3, size: 22)),
            const SizedBox(height: 8),
            Text(a.$1, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 11), textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }
}

// ─── Audits Tab ───────────────────────────────────────────────
class _AuditsTab extends StatelessWidget {
  final MockUser user;
  const _AuditsTab({required this.user});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'Audit Management', subtitle: '${mockAudits.length} audits'),
    backgroundColor: AppColors.background,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['All', 'In Progress', 'Scheduled', 'Submitted', 'Completed'].map((f) =>
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(f), selected: f == 'All', onSelected: (_) {}),
              )
            ).toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...mockAudits.map((a) => _AuditCard(audit: a)),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/audit-execution'),
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Start Audit'),
      backgroundColor: AppColors.primary,
    ),
  );
}

class _AuditCard extends StatelessWidget {
  final MockAudit audit;
  const _AuditCard({required this.audit});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/audit-execution'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(audit.facilityName, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${audit.auditNo}  ·  ${audit.type}', style: AppTextStyles.caption),
              ])),
              StatusBadge(status: audit.status),
            ],
          ),
          const SizedBox(height: 12),
          if (audit.status == 'IN_PROGRESS') ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress: ${audit.completed}/${audit.totalItems}', style: AppTextStyles.bodySmall),
              Text('${audit.score.toStringAsFixed(1)}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: audit.completed / audit.totalItems, backgroundColor: AppColors.borderLight, color: AppColors.primary, minHeight: 6)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _AuditMeta(icon: Icons.calendar_today_rounded, label: audit.scheduledDate),
              const SizedBox(width: 16),
              _AuditMeta(icon: Icons.person_rounded, label: audit.auditor),
              const Spacer(),
              if (audit.critical > 0) _AuditMeta(icon: Icons.warning_rounded, label: '${audit.critical} Critical', color: AppColors.error),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AuditMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _AuditMeta({required this.icon, required this.label, this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color ?? AppColors.textHint),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption.copyWith(color: color ?? AppColors.textSecondary)),
    ],
  );
}

// ─── Compliance Tab ───────────────────────────────────────────
class _ComplianceTab extends StatelessWidget {
  final MockUser user;
  const _ComplianceTab({required this.user});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'Compliance Dashboard'),
    backgroundColor: AppColors.background,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ComplianceOverviewCard(),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Compliance by Standard'),
        const SizedBox(height: 12),
        _StandardsComplianceCard(),
        const SizedBox(height: 16),
        SectionHeader(title: 'Equipment Status', actionLabel: 'Manage', onAction: () => context.push('/equipment')),
        const SizedBox(height: 12),
        _EquipmentSummaryCard(),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Documents & Certificates'),
        const SizedBox(height: 12),
        _DocumentsCard(),
      ],
    ),
  );
}

class _ComplianceOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(20)),
    child: Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fire Readiness Index', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('72.4', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
          const Text('/ 100', style: TextStyle(color: Colors.white60, fontSize: 16)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Level 3 — Managed', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ])),
        const SizedBox(width: 20),
        const Column(children: [
          _ComplianceMini(label: 'Equipment\nCompliance', value: '72%', color: Colors.orangeAccent),
          SizedBox(height: 12),
          _ComplianceMini(label: 'Audit\nScore', value: '78%', color: Colors.greenAccent),
          SizedBox(height: 12),
          _ComplianceMini(label: 'CA Closure\nRate', value: '64%', color: Colors.yellowAccent),
        ]),
      ],
    ),
  );
}

class _ComplianceMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ComplianceMini({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center),
  ]);
}

class _StandardsComplianceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final standards = [
      ('NBC 2016 — Part 4', 'Fire & Life Safety', 0.78, AppColors.primary),
      ('IS 2190', 'Portable Extinguishers', 0.72, AppColors.warning),
      ('IS 2189', 'Fire Alarm Systems', 0.85, AppColors.success),
      ('IS 13039', 'Wet Riser / Hydrant', 0.80, AppColors.info),
      ('OISD-116', 'Fire Protection', 0.65, AppColors.riskMedium),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: standards.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$1, style: AppTextStyles.h6),
                Text(s.$2, style: AppTextStyles.caption),
              ])),
              Text('${(s.$3 * 100).toInt()}%', style: AppTextStyles.h6.copyWith(color: s.$4)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.$3, backgroundColor: AppColors.borderLight, color: s.$4, minHeight: 6)),
          ]),
        )).toList(),
      ),
    );
  }
}

class _EquipmentSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _EquipStat(label: 'Total\nEquipment', value: '${mockEquipment.length}', color: AppColors.textPrimary),
        const _EquipStat(label: 'Operational', value: '5', color: AppColors.success),
        const _EquipStat(label: 'Service Due', value: '1', color: AppColors.warning),
        const _EquipStat(label: 'Defective', value: '1', color: AppColors.error),
        const _EquipStat(label: 'Missing', value: '0', color: AppColors.textSecondary),
      ],
    ),
  );
}

class _EquipStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EquipStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h3.copyWith(color: color)),
    const SizedBox(height: 4),
    Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
  ]);
}

class _DocumentsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final docs = [
      ('Fire NOC', 'Expiry: 31 Mar 2027', AppColors.success, Icons.verified_rounded),
      ('Building Plan (Approved)', 'Uploaded: 15 Jan 2025', AppColors.info, Icons.architecture_rounded),
      ('AMC Certificate — Extinguishers', 'Expiry: 31 Dec 2026', AppColors.success, Icons.assignment_turned_in_rounded),
      ('AMC Certificate — Detectors', 'Expiry: 15 Mar 2027', AppColors.success, Icons.sensors_rounded),
      ('PESO License', 'Expiry: 31 Aug 2026', AppColors.warning, Icons.shield_rounded),
    ];
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(children: docs.asMap().entries.map((e) => Column(children: [
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: e.value.$3.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(e.value.$4, color: e.value.$3, size: 18)),
          title: Text(e.value.$1, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          subtitle: Text(e.value.$2, style: AppTextStyles.caption),
          trailing: const Icon(Icons.download_rounded, size: 18, color: AppColors.textHint),
        ),
        if (e.key < docs.length - 1) const Divider(height: 1, indent: 56),
      ])).toList()),
    );
  }
}

// ─── Reports Tab ──────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  final MockUser user;
  const _ReportsTab({required this.user});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'Reports'),
    backgroundColor: AppColors.background,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Generate Report'),
        const SizedBox(height: 12),
        _ReportTypeGrid(onTap: () => context.push('/reports')),
        const SizedBox(height: 24),
        SectionHeader(title: 'Recent Reports', actionLabel: 'All Reports', onAction: () => context.push('/reports')),
        const SizedBox(height: 12),
        ..._recentReports.map((r) => _ReportCard(title: r.$1, date: r.$2, type: r.$3)),
      ],
    ),
  );

  List<(String, String, String)> get _recentReports => [
    ('Fire Audit Report — Jamnagar Refinery', '10 Jun 2026', 'Audit Report'),
    ('Monthly Compliance Report — Jun 2026', '01 Jun 2026', 'Compliance Report'),
    ('Equipment Status Report', '28 May 2026', 'Equipment Report'),
    ('Executive Fire Readiness Report', '15 May 2026', 'Executive Report'),
  ];
}

class _ReportTypeGrid extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportTypeGrid({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final types = [
      ('Audit Report', Icons.assignment_rounded, AppColors.primary),
      ('Compliance Report', Icons.verified_rounded, AppColors.success),
      ('Risk Report', Icons.warning_rounded, AppColors.warning),
      ('Equipment Report', Icons.inventory_2_rounded, AppColors.info),
      ('Executive Report', Icons.analytics_rounded, AppColors.secondary),
      ('NOC Readiness', Icons.shield_rounded, AppColors.riskMedium),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: types.map((t) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(t.$2, color: t.$3, size: 28),
            const SizedBox(height: 8),
            Text(t.$1, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title, date, type;
  const _ReportCard({required this.title, required this.date, required this.type});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('$type  ·  $date', style: AppTextStyles.caption),
      ])),
      const Icon(Icons.download_rounded, color: AppColors.textHint, size: 20),
    ]),
  );
}

// ─── Profile Tab ──────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final MockUser user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'My Profile'),
    backgroundColor: AppColors.background,
    body: ListView(
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: 16),
        _ProfileMenuSection(
          title: 'Account',
          items: [
            ('Edit Profile', Icons.edit_rounded, () {}),
            ('Change Password', Icons.lock_rounded, () {}),
            ('Biometric Settings', Icons.fingerprint_rounded, () {}),
            ('Notification Preferences', Icons.notifications_rounded, () {}),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileMenuSection(
          title: 'App',
          items: [
            ('Language', Icons.language_rounded, () {}),
            ('Offline Data', Icons.cloud_off_rounded, () {}),
            ('About', Icons.info_outline_rounded, () {}),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  final MockUser user;
  const _ProfileHeader({required this.user});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      CircleAvatar(radius: 42, backgroundColor: AppColors.primaryLight, child: Text(user.photoInitials, style: AppTextStyles.h2.copyWith(color: AppColors.primary))),
      const SizedBox(height: 12),
      Text(user.name, style: AppTextStyles.h4),
      Text(user.role, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(user.facility, style: AppTextStyles.caption),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ProfileBadge(label: user.employeeId, icon: Icons.badge_rounded),
        const SizedBox(width: 12),
        _ProfileBadge(label: user.department, icon: Icons.business_rounded),
      ]),
    ]),
  );
}

class _ProfileBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ProfileBadge({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<(String, IconData, VoidCallback)> items;
  const _ProfileMenuSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(title, style: AppTextStyles.overline)),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
        child: Column(children: items.asMap().entries.map((e) => Column(children: [
          ListTile(
            dense: true,
            leading: Icon(e.value.$2, size: 20, color: AppColors.textSecondary),
            title: Text(e.value.$1, style: AppTextStyles.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
            onTap: e.value.$3,
          ),
          if (e.key < items.length - 1) const Divider(height: 1, indent: 56),
        ])).toList()),
      ),
    ],
  );
}
