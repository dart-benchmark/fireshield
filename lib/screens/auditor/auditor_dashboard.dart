import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

final _auditor = demoUsers[3]; // Priya Nair - Auditor

class AuditorDashboard extends StatefulWidget {
  const AuditorDashboard({super.key});
  @override
  State<AuditorDashboard> createState() => _State();
}

class _State extends State<AuditorDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: IndexedStack(index: _tab, children: [
      _OverviewTab(),
      _MyAuditsTab(),
      _EquipmentTab(),
      _ProfileTab(),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'My Audits'),
        NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Equipment'),
        NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('Field Auditor', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text('Welcome, ${_auditor.name}', style: AppTextStyles.h3.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('2 audits assigned today', style: AppTextStyles.caption),
          ]),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => context.push('/notifications')),
        IconButton(icon: const Icon(Icons.sync_rounded, color: Colors.white), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing offline data...')))),
      ],
    ),
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(delegate: SliverChildListDelegate([
        const Row(children: [
          Expanded(child: StatCard(label: 'Assigned', value: '4', icon: Icons.assignment_rounded, color: AppColors.secondary)),
          SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Completed', value: '28', icon: Icons.check_circle_rounded, color: AppColors.success)),
        ]),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: StatCard(label: 'Pending', value: '2', icon: Icons.pending_actions_rounded, color: AppColors.warning)),
          SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Findings', value: '14', icon: Icons.report_rounded, color: AppColors.error)),
        ]),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Today\'s Schedule'),
        const SizedBox(height: 12),
        ...mockAudits.take(2).map((a) => _ScheduleCard(audit: a)),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _QuickAction(icon: Icons.play_circle_rounded, label: 'Start Audit', color: AppColors.primary, onTap: () => context.push('/audit-execution')),
            _QuickAction(icon: Icons.camera_alt_rounded, label: 'Evidence Capture', color: AppColors.secondary, onTap: () {}),
            _QuickAction(icon: Icons.offline_bolt_rounded, label: 'Offline Mode', color: AppColors.warning, onTap: () {}),
            _QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'Scan Tag', color: AppColors.info, onTap: () {}),
            _QuickAction(icon: Icons.smart_toy_rounded, label: 'AI Assistant', color: AppColors.success, onTap: () => context.push('/ai-assistant')),
            _QuickAction(icon: Icons.assignment_late_rounded, label: 'My CAs', color: AppColors.riskHigh, onTap: () => context.push('/corrective-actions')),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recent Findings'),
        const SizedBox(height: 12),
        const _FindingCard(finding: 'Blocked emergency exit on Floor 3', severity: 'CRITICAL', facility: 'Jamnagar Refinery', ref: 'NBC 2016 Cl. 4.2.5'),
        const _FindingCard(finding: 'Fire extinguisher pressure low — 2 units', severity: 'MAJOR', facility: 'City Hospital', ref: 'IS 2190:2010'),
        const _FindingCard(finding: 'Exit signage not illuminated', severity: 'MINOR', facility: 'Phoenix Mall', ref: 'NBC 2016 Cl. 4.13.2'),
      ])),
    ),
  ]);
}

class _ScheduleCard extends StatelessWidget {
  final MockAudit audit;
  const _ScheduleCard({required this.audit});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/audit-execution'),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(audit.facilityName, style: AppTextStyles.h6),
          Text('${audit.type} · ${audit.scheduledDate}', style: AppTextStyles.caption),
        ])),
        StatusBadge(status: audit.status),
      ]),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _FindingCard extends StatelessWidget {
  final String finding, severity, facility, ref;
  const _FindingCard({required this.finding, required this.severity, required this.facility, required this.ref});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      Container(width: 4, height: 50, decoration: BoxDecoration(color: severity == 'CRITICAL' ? AppColors.error : severity == 'MAJOR' ? AppColors.warning : AppColors.info, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(finding, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 2),
        const SizedBox(height: 4),
        Text('$facility · $ref', style: AppTextStyles.caption),
      ])),
      SeverityBadge(severity: severity),
    ]),
  );
}

class _MyAuditsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'My Audits', actions: [IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {})]),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mockAudits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = mockAudits[i];
        return GestureDetector(
          onTap: () => context.push('/audit-execution'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.auditNo, style: AppTextStyles.caption.copyWith(color: AppColors.info))),
                StatusBadge(status: a.status),
              ]),
              const SizedBox(height: 6),
              Text(a.facilityName, style: AppTextStyles.h6),
              Text(a.type, style: AppTextStyles.caption),
              const SizedBox(height: 10),
              LabeledProgressBar(label: 'Progress', value: '${a.completed}/${a.totalItems}', progress: a.totalItems > 0 ? a.completed / a.totalItems : 0, color: AppColors.secondary),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(a.scheduledDate, style: AppTextStyles.caption),
                const Spacer(),
                if (a.status == 'IN_PROGRESS')
                  ElevatedButton(onPressed: () => context.push('/audit-execution'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero, textStyle: AppTextStyles.caption.copyWith(fontSize: 11)), child: const Text('Resume')),
              ]),
            ]),
          ),
        );
      },
    ),
  );
}

class _EquipmentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'Equipment Check', actions: [IconButton(icon: const Icon(Icons.qr_code_scanner_rounded), onPressed: () {})]),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mockEquipment.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = mockEquipment[i];
        final color = e.status == 'OPERATIONAL' ? AppColors.success : e.status == 'MAINTENANCE_DUE' ? AppColors.warning : AppColors.error;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(children: [
            Icon(Icons.inventory_2_rounded, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.type, style: AppTextStyles.h6),
              Text('${e.location} · Next: ${e.nextService}', style: AppTextStyles.caption),
            ])),
            StatusBadge(status: e.status),
          ]),
        );
      },
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'Profile'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            CircleAvatar(radius: 30, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.person_rounded, color: Colors.white, size: 30)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_auditor.name, style: AppTextStyles.h5.copyWith(color: Colors.white)),
              Text(_auditor.role, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              Text(_auditor.email, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
          child: Column(children: [
            _MenuItem(icon: Icons.badge_rounded, title: 'Certifications & Training', onTap: () {}),
            const Divider(height: 1),
            _MenuItem(icon: Icons.offline_bolt_rounded, title: 'Offline Data Sync', subtitle: 'Last sync: 2 mins ago', onTap: () {}),
            const Divider(height: 1),
            _MenuItem(icon: Icons.security_rounded, title: 'Digital Signature', onTap: () {}),
            const Divider(height: 1),
            _MenuItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push('/notifications')),
            const Divider(height: 1),
            _MenuItem(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () {}),
            const Divider(height: 1),
            _MenuItem(icon: Icons.logout_rounded, title: 'Sign Out', onTap: () => context.go('/login'), isDestructive: true),
          ]),
        ),
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuItem({required this.icon, required this.title, this.subtitle, required this.onTap, this.isDestructive = false});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary, size: 20),
    title: Text(title, style: AppTextStyles.bodySmall.copyWith(color: isDestructive ? AppColors.error : AppColors.textPrimary)),
    subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
    onTap: onTap,
  );
}
