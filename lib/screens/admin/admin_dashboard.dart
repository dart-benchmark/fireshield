import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _State();
}

class _State extends State<AdminDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: IndexedStack(index: _tab, children: [
      _OverviewTab(),
      _OrgsTab(),
      _UsersTab(),
      _SettingsTab(),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
        NavigationDestination(icon: Icon(Icons.domain_rounded), label: 'Orgs'),
        NavigationDestination(icon: Icon(Icons.people_rounded), label: 'Users'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
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
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('Platform Administrator', style: AppTextStyles.caption),
            const SizedBox(height: 2),
            Text('Welcome, ${demoUsers[4].name}', style: AppTextStyles.h3.copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            const Text('12 new alerts need attention', style: AppTextStyles.caption),
          ]),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => context.push('/notifications')),
        IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platform settings available in next release.'), duration: Duration(seconds: 2)))),
      ],
    ),
    SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(delegate: SliverChildListDelegate([
        // Governance KPIs — Row 1
        const Row(children: [
          Expanded(child: StatCard(label: 'Organisations', value: '${GovernanceStats.totalOrgs}', icon: Icons.domain_rounded, color: Color(0xFF9C27B0))),
          SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Facilities', value: '${GovernanceStats.totalFacilities}', icon: Icons.location_city_rounded, color: AppColors.secondary)),
        ]),
        const SizedBox(height: 12),
        // Row 2
        const Row(children: [
          Expanded(child: StatCard(label: 'Buildings', value: '${GovernanceStats.totalBuildings}', icon: Icons.apartment_rounded, color: AppColors.info)),
          SizedBox(width: 12),
          Expanded(child: StatCard(label: 'Total Users', value: '${GovernanceStats.totalUsers}', icon: Icons.people_rounded, color: AppColors.success)),
        ]),
        const SizedBox(height: 12),
        // Row 3 — role breakdown
        const Row(children: [
          Expanded(child: StatCard(label: 'Org Admins', value: '${GovernanceStats.totalOrgAdmins}', icon: Icons.manage_accounts_rounded, color: AppColors.primary)),
          SizedBox(width: 8),
          Expanded(child: StatCard(label: 'Managers', value: '${GovernanceStats.totalManagers}', icon: Icons.badge_rounded, color: AppColors.secondary)),
          SizedBox(width: 8),
          Expanded(child: StatCard(label: 'Auditors', value: '${GovernanceStats.totalAuditors}', icon: Icons.assignment_ind_rounded, color: AppColors.warning)),
        ]),
        const SizedBox(height: 12),
        // Row 4 — audits
        const Row(children: [
          Expanded(child: StatCard(label: 'Total Audits', value: '${GovernanceStats.totalAudits}', icon: Icons.assignment_rounded, color: AppColors.error)),
          SizedBox(width: 12),
          Expanded(child: StatCard(label: 'This Month', value: '142', icon: Icons.calendar_month_rounded, color: AppColors.success)),
        ]),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Platform Usage (Last 7 Days)'),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
          child: BarChart(BarChartData(
            barGroups: [
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 42, color: AppColors.secondary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 55, color: AppColors.secondary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 38, color: AppColors.secondary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 67, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 71, color: AppColors.primary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 48, color: AppColors.secondary, width: 18, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 59, color: AppColors.secondary, width: 18, borderRadius: BorderRadius.circular(4))]),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Text(days[v.toInt()], style: AppTextStyles.caption.copyWith(fontSize: 10));
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 24),
        // State-wise Distribution
        const SectionHeader(title: 'State-wise Distribution'),
        const SizedBox(height: 12),
        ...GovernanceStats.stateWise.map((s) => _DistributionBar(label: s['state'] as String, value: s['orgs'] as int, max: 14, color: AppColors.primary)),
        const SizedBox(height: 24),
        // Industry-wise Distribution
        const SectionHeader(title: 'Industry-wise Distribution'),
        const SizedBox(height: 12),
        ...GovernanceStats.industryWise.map((s) => _DistributionBar(label: s['industry'] as String, value: s['orgs'] as int, max: 14, color: AppColors.secondary)),
        const SizedBox(height: 24),
        // Recent Registrations
        SectionHeader(title: 'Recent Registrations', actionLabel: 'Register Org', onAction: () => context.push('/register-org')),
        const SizedBox(height: 12),
        ...GovernanceStats.recentRegistrations.map((r) => _RecentRegCard(data: r)),
        const SizedBox(height: 24),
        // Recent Activities
        const SectionHeader(title: 'Recent Activities'),
        const SizedBox(height: 12),
        ...GovernanceStats.recentActivities.map((a) => _ActivityRow(data: a)),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Subscription Overview'),
        const SizedBox(height: 12),
        const _SubscriptionCard(tier: 'Enterprise', orgs: 12, color: Color(0xFF9C27B0)),
        const _SubscriptionCard(tier: 'Professional', orgs: 15, color: AppColors.secondary),
        const _SubscriptionCard(tier: 'Starter', orgs: 7, color: AppColors.success),
        const SizedBox(height: 24),
        SectionHeader(title: 'System Alerts', actionLabel: 'View All', onAction: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert centre available in next release.'), duration: Duration(seconds: 2)))),
        const SizedBox(height: 12),
        const _AlertItem(icon: Icons.storage_rounded, title: 'Azure Blob Storage at 78%', body: 'Consider storage tier upgrade', color: AppColors.warning),
        const _AlertItem(icon: Icons.security_rounded, title: 'API Rate Limit Warning', body: '94% of daily quota used', color: AppColors.error),
        const _AlertItem(icon: Icons.sync_rounded, title: 'Sync Queue Backlog', body: '342 records pending sync', color: AppColors.info),
      ])),
    ),
  ]);
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int value, max;
  final Color color;
  const _DistributionBar({required this.label, required this.value, required this.max, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value / max, backgroundColor: color.withValues(alpha: 0.1), color: color, minHeight: 8))),
      const SizedBox(width: 8),
      Text('$value', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
    ]),
  );
}

class _RecentRegCard extends StatelessWidget {
  final Map data;
  const _RecentRegCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      CircleAvatar(backgroundColor: AppColors.primaryLight, radius: 18, child: Text((data['name'] as String).substring(0, 2), style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['name'] as String, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        Text('${data['type']} · ${data['facilities']} facilities', style: AppTextStyles.caption),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(data['date'] as String, style: AppTextStyles.caption),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
          child: const Text('Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 10)),
        ),
      ]),
    ]),
  );
}

class _ActivityRow extends StatelessWidget {
  final Map data;
  const _ActivityRow({required this.data});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['action'] as String, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        Text('${data['entity']} · ${data['time']}', style: AppTextStyles.caption),
      ])),
    ]),
  );
}

class _SubscriptionCard extends StatelessWidget {
  final String tier;
  final int orgs;
  final Color color;
  const _SubscriptionCard({required this.tier, required this.orgs, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Expanded(child: Text('$tier Plan', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
      Text('$orgs orgs', style: AppTextStyles.caption),
    ]),
  );
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  const _AlertItem({required this.icon, required this.title, required this.body, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        Text(body, style: AppTextStyles.caption),
      ])),
    ]),
  );
}

class _OrgsTab extends StatelessWidget {
  final _orgs = const [
    {'name': 'Reliance Industries Ltd.', 'type': 'Enterprise', 'facilities': '28', 'score': '82'},
    {'name': 'Apollo Hospitals Group', 'type': 'Enterprise', 'facilities': '14', 'score': '91'},
    {'name': 'DLF Commercial Properties', 'type': 'Professional', 'facilities': '9', 'score': '76'},
    {'name': 'Chennai Airport Authority', 'type': 'Professional', 'facilities': '3', 'score': '88'},
    {'name': 'Prestige Group Malls', 'type': 'Professional', 'facilities': '7', 'score': '73'},
    {'name': 'IIT Jodhpur', 'type': 'Starter', 'facilities': '2', 'score': '65'},
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppApp(context),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/register-org'), icon: const Icon(Icons.add_rounded), label: const Text('Register Org')),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _orgs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = _orgs[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.domain_rounded, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['name']!, style: AppTextStyles.h6),
              Text('${o['facilities']!} facilities · FRI: ${o['score']!}', style: AppTextStyles.caption),
            ])),
            StatusBadge(status: o['type']!),
          ]),
        );
      },
    ),
  );

  PreferredSizeWidget buildAppApp(BuildContext context) => buildAppBar(context, title: 'Organisations', actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search available in next release.'), duration: Duration(seconds: 2))))]);
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'User Management', actions: [IconButton(icon: const Icon(Icons.person_add_rounded), onPressed: () {})]),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: demoUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = demoUsers[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(u.name[0], style: AppTextStyles.h5.copyWith(color: AppColors.primary))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.name, style: AppTextStyles.h6),
              Text(u.email, style: AppTextStyles.caption),
            ])),
            const StatusBadge(status: 'ACTIVE'),
          ]),
        );
      },
    ),
  );
}

class _SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'Platform Settings'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Integrations'),
        const SizedBox(height: 12),
        ...[
          ('Azure AD / SSO', Icons.cloud_rounded, true),
          ('Firebase Cloud Messaging', Icons.notifications_rounded, true),
          ('AI Compliance Engine', Icons.smart_toy_rounded, true),
          ('Azure Blob Storage', Icons.storage_rounded, true),
          ('SAP Integration', Icons.business_center_rounded, false),
          ('ServiceNow ITSM', Icons.support_agent_rounded, false),
        ].map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          child: Row(children: [
            Icon(item.$2, color: item.$3 ? AppColors.success : AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(item.$1, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500))),
            StatusBadge(status: item.$3 ? 'CONNECTED' : 'INACTIVE'),
          ]),
        )),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Compliance Configuration'),
        const SizedBox(height: 12),
        ...[
          'NBC 2016 Part 4 — Fire & Life Safety',
          'NBC 2016 Part 7 — Electrical',
          'IS 2189:2008 — Fire Detection',
          'OISD-116 — Hydrocarbon Facilities',
          'NABH — Hospital Standards',
        ].map((s) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(s, style: AppTextStyles.bodySmall)),
          ]),
        )),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: () => context.go('/login'), icon: const Icon(Icons.logout_rounded), label: const Text('Sign Out'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error)),
      ],
    ),
  );
}
