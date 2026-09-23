import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class OrgAdminDashboard extends StatefulWidget {
  const OrgAdminDashboard({super.key});
  @override
  State<OrgAdminDashboard> createState() => _State();
}

class _State extends State<OrgAdminDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  static const _org = {
    'name': 'Phoenix Malls Pvt. Ltd.',
    'id': 'ORG-2024-00031',
    'gst': '29AACCP1234M1Z5',
    'industry': 'Real Estate & Commercial',
    'city': 'Bengaluru, Karnataka',
    'nocStatus': 'Valid',
    'nocExpiry': '27 Mar 2027',
    'facilities': '3',
    'buildings': '8',
    'users': '12',
    'audits': '24',
  };

  static const _facilities = [
    {'name': 'Phoenix Marketcity Bengaluru', 'buildings': '3', 'area': '7,50,000 sqft', 'noc': 'Valid', 'lastAudit': '15 Mar 2026'},
    {'name': 'Phoenix Mall of Asia Bengaluru', 'buildings': '2', 'area': '12,50,000 sqft', 'noc': 'Valid', 'lastAudit': '02 Feb 2026'},
    {'name': 'Phoenix One Bengaluru West', 'buildings': '3', 'area': '5,50,000 sqft', 'noc': 'Expiring Soon', 'lastAudit': '10 Jan 2026'},
  ];

  static const _users = [
    {'name': 'Arjun Sharma', 'role': 'Safety Manager', 'emp': 'SM-1001', 'facility': 'Marketcity', 'status': 'Active'},
    {'name': 'Priya Nair', 'role': 'Auditor', 'emp': 'AU-1002', 'facility': 'Mall of Asia', 'status': 'Active'},
    {'name': 'Rohan Gupta', 'role': 'Auditor', 'emp': 'AU-1003', 'facility': 'Bengaluru West', 'status': 'Active'},
    {'name': 'Sneha Patel', 'role': 'Safety Manager', 'emp': 'SM-1004', 'facility': 'All Facilities', 'status': 'Active'},
    {'name': 'Karan Verma', 'role': 'Auditor', 'emp': 'AU-1005', 'facility': 'Marketcity', 'status': 'On Leave'},
  ];

  static const _audits = [
    {'id': 'AUD-2026-031', 'facility': 'Phoenix Marketcity', 'date': '15 Mar 2026', 'score': '87%', 'status': 'Completed', 'auditor': 'Priya Nair'},
    {'id': 'AUD-2026-018', 'facility': 'Phoenix Mall of Asia', 'date': '02 Feb 2026', 'score': '91%', 'status': 'Completed', 'auditor': 'Rohan Gupta'},
    {'id': 'AUD-2026-041', 'facility': 'Bengaluru West', 'date': '20 Jun 2026', 'score': '—', 'status': 'In Progress', 'auditor': 'Priya Nair'},
    {'id': 'AUD-2025-087', 'facility': 'Phoenix Marketcity', 'date': '10 Sep 2025', 'score': '79%', 'status': 'Completed', 'auditor': 'Karan Verma'},
  ];

  static const _activities = [
    {'icon': Icons.check_circle_rounded, 'color': AppColors.success, 'title': 'Audit completed — Marketcity', 'time': '2 hours ago'},
    {'icon': Icons.warning_amber_rounded, 'color': AppColors.warning, 'title': 'NOC expiry alert — Bengaluru West (90 days)', 'time': '1 day ago'},
    {'icon': Icons.person_add_rounded, 'color': AppColors.primary, 'title': 'New auditor added — Sneha Patel', 'time': '3 days ago'},
    {'icon': Icons.upload_file_rounded, 'color': AppColors.info, 'title': 'Fire plan uploaded — Mall of Asia', 'time': '5 days ago'},
    {'icon': Icons.assignment_rounded, 'color': AppColors.secondary, 'title': 'Audit scheduled — Bengaluru West', 'time': '1 week ago'},
  ];

  static const _equipment = [
    {'name': 'Fire Extinguishers', 'count': '248', 'due': '15 Jul 2026', 'status': 'OK'},
    {'name': 'Hydrant System', 'count': '3 networks', 'due': 'Annual Test Apr 2026', 'status': 'Overdue'},
    {'name': 'Sprinkler System', 'count': '12,400 heads', 'due': 'Quarterly Test', 'status': 'OK'},
    {'name': 'Fire Alarm (FACP)', 'count': '18 panels', 'due': 'Half-yearly', 'status': 'OK'},
    {'name': 'Emergency Lighting', 'count': '1,240 units', 'due': 'Monthly Test', 'status': 'Warning'},
    {'name': 'Fire Pumps', 'count': '9 pumps', 'due': 'Weekly Test', 'status': 'OK'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Organisation Admin', style: AppTextStyles.h5),
        Text(_org['name'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]),
      backgroundColor: AppColors.surface,
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Facilities'),
          Tab(text: 'Users'),
          Tab(text: 'Audits'),
          Tab(text: 'Equipment'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _buildOverview(),
        _buildFacilities(),
        _buildUsers(),
        _buildAudits(),
        _buildEquipment(),
      ],
    ),
  );

  Widget _buildOverview() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // KPI row
      Row(children: [
        Expanded(child: _kpi('Facilities', _org['facilities'] as String, Icons.apartment_rounded, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _kpi('Buildings', _org['buildings'] as String, Icons.domain_rounded, AppColors.secondary)),
        const SizedBox(width: 8),
        Expanded(child: _kpi('Users', _org['users'] as String, Icons.people_rounded, AppColors.info)),
        const SizedBox(width: 8),
        Expanded(child: _kpi('Audits', _org['audits'] as String, Icons.assignment_rounded, AppColors.success)),
      ]),
      const SizedBox(height: 16),
      // Org detail card
      SectionCard(title: 'Organisation Details', child: Column(children: [
        InfoRow(label: 'Organisation ID', value: _org['id'] as String),
        InfoRow(label: 'Industry', value: _org['industry'] as String),
        InfoRow(label: 'GST Number', value: _org['gst'] as String),
        InfoRow(label: 'Headquarters', value: _org['city'] as String),
        InfoRow(label: 'NOC Status', value: _org['nocStatus'] as String, valueColor: AppColors.success),
        InfoRow(label: 'NOC Expiry', value: _org['nocExpiry'] as String, isLast: true),
      ])),
      const SizedBox(height: 12),
      // Compliance score ring
      SectionCard(title: 'Compliance Overview', child: Row(children: [
        _scoreDial(87, 'Compliance', AppColors.success),
        const SizedBox(width: 16),
        _scoreDial(72, 'Risk Score', AppColors.warning),
        const SizedBox(width: 16),
        _scoreDial(91, 'Readiness', AppColors.info),
      ])),
      const SizedBox(height: 12),
      // Recent Activity
      SectionCard(title: 'Recent Activity', child: Column(
        children: _activities.map((a) => _activityRow(a)).toList(),
      )),
    ]),
  );

  Widget _buildFacilities() => ListView(
    padding: const EdgeInsets.all(16),
    children: _facilities.map((f) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(f['name'] as String, style: AppTextStyles.h6)),
          StatusBadge(status: f['noc'] as String),
        ]),
        const SizedBox(height: 8),
        InfoRow(label: 'Buildings', value: f['buildings'] as String),
        InfoRow(label: 'Built-up Area', value: f['area'] as String),
        InfoRow(label: 'Last Audit', value: f['lastAudit'] as String, isLast: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.assignment_rounded, size: 14), label: const Text('Schedule Audit'), onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.visibility_rounded, size: 14), label: const Text('View Details'), onPressed: () {})),
        ]),
      ]),
    )).toList(),
  );

  Widget _buildUsers() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => context.push('/create-user'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Create User'),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      ),
    ),
    Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: _users.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              radius: 22,
              child: Text((u['name'] as String).substring(0, 2), style: AppTextStyles.label.copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text('${u['role']} · ${u['emp']}', style: AppTextStyles.caption),
              Text(u['facility'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
            ])),
            StatusBadge(status: u['status'] as String),
          ]),
        )).toList(),
      ),
    ),
  ]);

  Widget _buildAudits() => ListView(
    padding: const EdgeInsets.all(16),
    children: _audits.map((a) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a['id'] as String, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontFamily: 'monospace'))),
          StatusBadge(status: a['status'] as String),
        ]),
        const SizedBox(height: 4),
        Text(a['facility'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(a['date'] as String, style: AppTextStyles.caption),
          const SizedBox(width: 16),
          const Icon(Icons.person_rounded, size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(a['auditor'] as String, style: AppTextStyles.caption),
          const Spacer(),
          if (a['score'] != '—') Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
            child: Text(a['score'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    )).toList(),
  );

  Widget _buildEquipment() => ListView(
    padding: const EdgeInsets.all(16),
    children: _equipment.map((e) {
      final (color, icon) = switch (e['status']) {
        'OK'      => (AppColors.success, Icons.check_circle_rounded),
        'Warning' => (AppColors.warning, Icons.warning_amber_rounded),
        'Overdue' => (AppColors.error, Icons.error_rounded),
        _         => (AppColors.textHint, Icons.info_rounded),
      };
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
        child: Row(children: [
          Icon(Icons.fire_extinguisher_rounded, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e['name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(e['count'] as String, style: AppTextStyles.caption),
            Text('Next: ${e['due']}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ])),
          Icon(icon, color: color, size: 20),
        ]),
      );
    }).toList(),
  );

  Widget _kpi(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.h5.copyWith(color: color)),
      Text(label, style: AppTextStyles.overline, textAlign: TextAlign.center),
    ]),
  );

  Widget _scoreDial(int score, String label, Color color) => Expanded(child: Column(children: [
    Stack(alignment: Alignment.center, children: [
      SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: score / 100, strokeWidth: 6, backgroundColor: color.withValues(alpha: 0.15), color: color)),
      Text('$score%', style: AppTextStyles.label.copyWith(color: color, fontSize: 12)),
    ]),
    const SizedBox(height: 6),
    Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
  ]));

  Widget _activityRow(Map<String, dynamic> a) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: (a['color'] as Color).withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a['title'] as String, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
        Text(a['time'] as String, style: AppTextStyles.caption),
      ])),
    ]),
  );
}
