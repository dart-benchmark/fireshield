import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class GovernmentDashboard extends StatefulWidget {
  final MockUser user;
  const GovernmentDashboard({super.key, required this.user});
  @override
  State<GovernmentDashboard> createState() => _State();
}

class _State extends State<GovernmentDashboard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: IndexedStack(
      index: _tab,
      children: [
        _OverviewTab(user: widget.user),
        _FacilitiesTab(),
        _InspectionsTab(),
        _ReportsTab(),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.business_rounded), label: 'Facilities'),
        BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Inspections'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
      ],
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  final MockUser user;
  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context) {
    const s = DashboardStats.govtStats;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.success,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.greenGradient),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(backgroundColor: Colors.white.withValues(alpha: 0.2), child: Text(user.photoInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Government Officer Portal', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(user.facility, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Row(children: [
                    Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Regulatory View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _GovtPill(label: 'Total Facilities', value: '${s['totalFacilities']}'),
                  const SizedBox(width: 10),
                  _GovtPill(label: 'Critical Risk', value: '${s['critical']}', color: Colors.redAccent),
                  const SizedBox(width: 10),
                  _GovtPill(label: 'NOC Expired', value: '${s['nocExpired']}', color: Colors.orangeAccent),
                ]),
              ]),
            ),
          ),
          title: const Text('Regulatory Dashboard', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(label: 'Compliant Facilities', value: '${s['compliant']}', icon: Icons.verified_rounded, color: AppColors.success, subtitle: '${((s['compliant']! / s['totalFacilities']!) * 100).toInt()}%'),
                    StatCard(label: 'Non-Compliant', value: '${s['nonCompliant']}', icon: Icons.warning_rounded, color: AppColors.warning),
                    StatCard(label: 'Critical Risk', value: '${s['critical']}', icon: Icons.dangerous_rounded, color: AppColors.error, subtitle: 'Immediate'),
                    StatCard(label: 'Scheduled Inspections', value: '${s['scheduledInspections']}', icon: Icons.event_rounded, color: AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'NOC Status Overview'),
                const SizedBox(height: 12),
                const _NocStatusCard(stats: s),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Compliance Trend (Last 6 Months)'),
                const SizedBox(height: 12),
                _ComplianceTrendChart(),
                const SizedBox(height: 24),
                SectionHeader(title: 'High-Risk Facilities', actionLabel: 'View All', onAction: () {}),
                const SizedBox(height: 12),
                ...mockFacilities.where((f) => f.riskLevel == 'CRITICAL' || f.riskLevel == 'HIGH').take(3).map((f) => _GovtFacilityCard(facility: f)),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Facility Type Distribution'),
                const SizedBox(height: 12),
                _FacilityTypeChart(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GovtPill extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _GovtPill({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]),
  );
}

class _NocStatusCard extends StatelessWidget {
  final Map<String, int> stats;
  const _NocStatusCard({required this.stats});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _NocStat('Valid', '${stats['totalFacilities']! - stats['nocPending']! - stats['nocExpired']!}', AppColors.success),
          _NocStat('Pending', '${stats['nocPending']}', AppColors.warning),
          _NocStat('Expired', '${stats['nocExpired']}', AppColors.error),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: [
            Expanded(flex: stats['totalFacilities']! - stats['nocPending']! - stats['nocExpired']!, child: Container(height: 10, color: AppColors.success)),
            Expanded(flex: stats['nocPending']!, child: Container(height: 10, color: AppColors.warning)),
            Expanded(flex: stats['nocExpired']!, child: Container(height: 10, color: AppColors.error)),
          ]),
        ),
        const SizedBox(height: 8),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _Legend('Valid NOC', AppColors.success),
          _Legend('Pending', AppColors.warning),
          _Legend('Expired', AppColors.error),
        ]),
      ],
    ),
  );
}

class _NocStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NocStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h2.copyWith(color: color)),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _ComplianceTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borderLight, strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: AppTextStyles.caption.copyWith(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
            return Text(months[v.toInt()], style: AppTextStyles.caption.copyWith(fontSize: 10));
          })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [FlSpot(0, 62), FlSpot(1, 65), FlSpot(2, 68), FlSpot(3, 71), FlSpot(4, 73), FlSpot(5, 76)],
            isCurved: true,
            color: AppColors.success,
            barWidth: 2.5,
            dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: AppColors.success, strokeWidth: 1, strokeColor: Colors.white)),
            belowBarData: BarAreaData(show: true, color: AppColors.success.withValues(alpha: 0.08)),
          ),
          LineChartBarData(
            spots: const [FlSpot(0, 38), FlSpot(1, 35), FlSpot(2, 32), FlSpot(3, 29), FlSpot(4, 27), FlSpot(5, 24)],
            isCurved: true,
            color: AppColors.error,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
            belowBarData: BarAreaData(show: true, color: AppColors.error.withValues(alpha: 0.05)),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    ),
  );
}

class _GovtFacilityCard extends StatelessWidget {
  final MockFacility facility;
  const _GovtFacilityCard({required this.facility});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: facility.riskLevel == 'CRITICAL' ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderLight)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: facility.riskLevel == 'CRITICAL' ? AppColors.errorLight : AppColors.warningLight, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.business_rounded, color: facility.riskLevel == 'CRITICAL' ? AppColors.error : AppColors.warning, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(facility.name, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${facility.type}  ·  ${facility.location}', style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Row(children: [
          const Text('NOC: ', style: AppTextStyles.caption),
          StatusBadge(status: facility.nocStatus),
          const SizedBox(width: 8),
          Text('FRI: ${facility.fri}%', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ])),
      Column(children: [
        RiskTag(level: facility.riskLevel),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: Size.zero, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Inspect', style: TextStyle(fontSize: 11, color: AppColors.primary)),
        ),
      ]),
    ]),
  );
}

class _FacilityTypeChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      ('Hospital', 18, AppColors.chartColors[0]),
      ('School', 24, AppColors.chartColors[1]),
      ('Mall', 12, AppColors.chartColors[2]),
      ('Industrial', 31, AppColors.chartColors[3]),
      ('Hotel', 9, AppColors.chartColors[4]),
      ('Others', 6, AppColors.chartColors[5]),
    ];
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: data.map((d) => PieChartSectionData(value: d.$2.toDouble(), color: d.$3, radius: 55, showTitle: false)).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 32,
          )),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: d.$3, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${d.$1} (${d.$2}%)', style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}

// ─── Facilities Tab ───────────────────────────────────────────
class _FacilitiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'All Facilities', subtitle: '${mockFacilities.length} facilities',
      actions: [
        IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        IconButton(icon: const Icon(Icons.map_rounded), onPressed: () {}),
      ],
    ),
    backgroundColor: AppColors.background,
    body: Column(children: [
      const Padding(padding: EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'Search facilities...', prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary)))),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: mockFacilities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _GovtFacilityListCard(facility: mockFacilities[i]),
      )),
    ]),
  );
}

class _GovtFacilityListCard extends StatelessWidget {
  final MockFacility facility;
  const _GovtFacilityListCard({required this.facility});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(facility.name, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis)),
        RiskTag(level: facility.riskLevel),
      ]),
      const SizedBox(height: 4),
      Text('${facility.type}  ·  ${facility.location}', style: AppTextStyles.caption),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LabeledProgressBar(label: 'Compliance', value: '${facility.compliance}%', progress: facility.compliance / 100, color: facility.compliance >= 80 ? AppColors.success : facility.compliance >= 60 ? AppColors.warning : AppColors.error),
        ])),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('FRI: ${facility.fri}', style: AppTextStyles.h6.copyWith(color: facility.fri >= 80 ? AppColors.success : AppColors.warning)),
          StatusBadge(status: facility.nocStatus),
        ]),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('Last Audit: ${facility.lastAudit}', style: AppTextStyles.caption),
        const Spacer(),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('View Details', style: TextStyle(fontSize: 11, color: AppColors.primary)),
        ),
      ]),
    ]),
  );
}

// ─── Inspections Tab ──────────────────────────────────────────
class _InspectionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'Inspections'),
    backgroundColor: AppColors.background,
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeader(title: 'Scheduled Inspections'),
      const SizedBox(height: 12),
      ..._inspections.map((i) => _InspectionCard(data: i)),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Recent Inspection Results'),
      const SizedBox(height: 12),
      ..._completed.map((i) => _InspectionCard(data: i, isCompleted: true)),
    ]),
  );

  List<Map<String, String>> get _inspections => [
    {'facility': 'Delhi Public School Sector 19', 'date': '15 Jun 2026', 'type': 'NOC Verification', 'risk': 'CRITICAL'},
    {'facility': 'Phoenix Mall Bengaluru', 'date': '18 Jun 2026', 'type': 'Periodic Inspection', 'risk': 'MEDIUM'},
    {'facility': 'City Hospital Ahmedabad', 'date': '22 Jun 2026', 'type': 'Pre-Renewal Inspection', 'risk': 'MEDIUM'},
  ];
  List<Map<String, String>> get _completed => [
    {'facility': 'GVK Airport Terminal 2', 'date': '10 Jun 2026', 'type': 'DGCA Fire Safety', 'risk': 'HIGH', 'score': '94%'},
    {'facility': 'NPC Data Centre Noida', 'date': '05 Jun 2026', 'type': 'Periodic Inspection', 'risk': 'HIGH', 'score': '88%'},
  ];
}

class _InspectionCard extends StatelessWidget {
  final Map<String, String> data;
  final bool isCompleted;
  const _InspectionCard({required this.data, this.isCompleted = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isCompleted ? AppColors.successLight : AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
        child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded, color: isCompleted ? AppColors.success : AppColors.info, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['facility']!, style: AppTextStyles.h6, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${data['type']}  ·  ${data['date']}', style: AppTextStyles.caption),
        if (isCompleted && data['score'] != null) Text('Score: ${data['score']}', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
      ])),
      Column(children: [
        RiskTag(level: data['risk']!),
        if (!isCompleted) ...[
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Start', style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ),
        ],
      ]),
    ]),
  );
}

// ─── Analytics Tab ────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(context, title: 'Analytics & Reports'),
    backgroundColor: AppColors.background,
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeader(title: 'State-wise Compliance'),
      const SizedBox(height: 12),
      _StateComplianceChart(),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Generate Government Reports'),
      const SizedBox(height: 12),
      _GovtReportGrid(),
    ]),
  );
}

class _StateComplianceChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final states = [
      ('Maharashtra', 0.81, AppColors.chartColors[0]),
      ('Gujarat', 0.76, AppColors.chartColors[1]),
      ('Karnataka', 0.88, AppColors.chartColors[2]),
      ('Delhi', 0.58, AppColors.chartColors[3]),
      ('UP', 0.62, AppColors.chartColors[4]),
      ('Tamil Nadu', 0.79, AppColors.chartColors[5]),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
      child: Column(children: states.map((s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: LabeledProgressBar(label: s.$1, value: '${(s.$2 * 100).toInt()}%', progress: s.$2, color: s.$3),
      )).toList()),
    );
  }
}

class _GovtReportGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final types = [
      ('State Compliance Report', Icons.map_rounded, AppColors.primary),
      ('NOC Status Report', Icons.shield_rounded, AppColors.success),
      ('Risk Register', Icons.warning_rounded, AppColors.error),
      ('Inspection Summary', Icons.checklist_rounded, AppColors.info),
      ('Facility Performance', Icons.analytics_rounded, AppColors.secondary),
      ('Annual Statistics', Icons.bar_chart_rounded, AppColors.warning),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: types.map((t) => GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generating ${t.$1}...'))),
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(t.$2, color: t.$3, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(t.$1, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, height: 1.3))),
          ]),
        ),
      )).toList(),
    );
  }
}
