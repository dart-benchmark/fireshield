import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class CorrectiveActionsScreen extends StatefulWidget {
  const CorrectiveActionsScreen({super.key});
  @override
  State<CorrectiveActionsScreen> createState() => _State();
}

class _State extends State<CorrectiveActionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Critical', 'Overdue', 'Open', 'Closed'];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: _tabs.length, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<MockCA> _filtered(String tab) => switch (tab) {
    'Critical' => mockCAs.where((c) => c.severity == 'CRITICAL').toList(),
    'Overdue' => mockCAs.where((c) => c.status == 'OVERDUE' || c.status == 'ESCALATED').toList(),
    'Open' => mockCAs.where((c) => c.status == 'OPEN' || c.status == 'IN_PROGRESS' || c.status == 'ASSIGNED').toList(),
    'Closed' => mockCAs.where((c) => c.status == 'CLOSED').toList(),
    _ => mockCAs,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Corrective Actions', style: AppTextStyles.h5),
        Text('Track & close all findings', style: AppTextStyles.caption),
      ]),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
      actions: [
        IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () => _nextRelease(context)),
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _nextRelease(context)),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.caption,
        indicator: const UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 2)),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    ),
    body: Column(children: [
      _CaSummaryBar(),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((t) => _CaListView(items: _filtered(t))).toList(),
        ),
      ),
    ]),
  );

  void _nextRelease(BuildContext ctx) => ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(content: Text('This feature is available in the next release.'), duration: Duration(seconds: 2)),
  );
}

class _CaSummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _Stat('Total', mockCAs.length.toString(), AppColors.textPrimary),
      _Stat('Critical', '${mockCAs.where((c) => c.severity == 'CRITICAL').length}', AppColors.error),
      _Stat('Overdue', '${mockCAs.where((c) => c.status == 'OVERDUE' || c.status == 'ESCALATED').length}', AppColors.riskHigh),
      _Stat('Open', '${mockCAs.where((c) => c.status == 'OPEN' || c.status == 'IN_PROGRESS').length}', AppColors.warning),
      _Stat('Closed', '${mockCAs.where((c) => c.status == 'CLOSED').length}', AppColors.success),
    ]),
  );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h4.copyWith(color: color)),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _CaListView extends StatelessWidget {
  final List<MockCA> items;
  const _CaListView({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyState(title: 'No Corrective Actions', subtitle: 'No items match the selected filter', icon: Icons.assignment_turned_in_rounded);
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CaCard(ca: items[i]),
    );
  }
}

class _CaCard extends StatelessWidget {
  final MockCA ca;
  const _CaCard({required this.ca});

  Color get _severityColor => switch (ca.severity) {
    'CRITICAL' => AppColors.error,
    'MAJOR' => AppColors.warning,
    _ => AppColors.info,
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showDetail(context),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (ca.status == 'OVERDUE' || ca.status == 'ESCALATED') ? AppColors.error.withValues(alpha: 0.4) : AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, decoration: BoxDecoration(color: _severityColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(ca.caNo, style: AppTextStyles.caption)),
                      SeverityBadge(severity: ca.severity),
                    ]),
                    const SizedBox(height: 6),
                    Text(ca.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.business_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(child: Text(ca.facility, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(ca.assignedTo, style: AppTextStyles.caption),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('Due: ${ca.dueDate}', style: AppTextStyles.caption.copyWith(color: (ca.status == 'OVERDUE') ? AppColors.error : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(ca.standard, style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                      StatusBadge(status: ca.status),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showDetail(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _CaDetailSheet(ca: ca),
  );
}

class _CaDetailSheet extends StatelessWidget {
  final MockCA ca;
  const _CaDetailSheet({required this.ca});

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (_, ctrl) => Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Text(ca.caNo, style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary))),
            SeverityBadge(severity: ca.severity),
            const SizedBox(width: 8),
            StatusBadge(status: ca.status),
          ]),
          const SizedBox(height: 10),
          Text(ca.title, style: AppTextStyles.h4),
          const SizedBox(height: 16),
          const Divider(),
          InfoRow(label: 'Facility', value: ca.facility),
          InfoRow(label: 'Standard Ref.', value: ca.standard, valueColor: AppColors.info),
          InfoRow(label: 'Assigned To', value: ca.assignedTo),
          InfoRow(label: 'Raised Date', value: ca.raisedDate),
          InfoRow(label: 'Due Date', value: ca.dueDate, valueColor: ca.status == 'OVERDUE' ? AppColors.error : null),
          InfoRow(label: 'Status', value: ca.status, isLast: true),
          const SizedBox(height: 20),
          const Text('Corrective Measure', style: AppTextStyles.h6),
          const SizedBox(height: 8),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(hintText: 'Describe the corrective action taken...', prefixIcon: Icon(Icons.edit_note_rounded, size: 20, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 16),
          const Text('Completion Evidence', style: AppTextStyles.h6),
          const SizedBox(height: 8),
          Container(
            height: 100, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, style: BorderStyle.solid)),
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_rounded, size: 32, color: AppColors.textHint),
              SizedBox(height: 4),
              Text('Add photos / documents as proof', style: AppTextStyles.caption),
            ])),
          ),
          const SizedBox(height: 20),
          if (ca.status != 'CLOSED') Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Reassign'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Submitted for verification'))); },
              child: const Text('Mark Completed'),
            )),
          ]),
        ],
      ),
    ),
  );
}
