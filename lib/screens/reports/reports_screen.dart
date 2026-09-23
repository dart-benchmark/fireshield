import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'Reports', showBack: true,
      actions: [IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {})],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Quick Generate'),
        const SizedBox(height: 12),
        _ReportTypeGrid(),
        const SizedBox(height: 24),
        SectionHeader(title: 'Report Archive', actionLabel: 'Filter', onAction: () {}),
        const SizedBox(height: 12),
        ..._reports.map((r) => _ReportItem(data: r)),
      ],
    ),
  );

  List<Map<String, String>> get _reports => [
    {'title': 'Fire Audit Report — Jamnagar Refinery', 'date': '10 Jun 2026', 'type': 'Audit Report', 'pages': '28', 'status': 'APPROVED'},
    {'title': 'Monthly Compliance Report — Jun 2026', 'date': '01 Jun 2026', 'type': 'Compliance Report', 'pages': '14', 'status': 'APPROVED'},
    {'title': 'Equipment Status Report — May 2026', 'date': '31 May 2026', 'type': 'Equipment Report', 'pages': '8', 'status': 'APPROVED'},
    {'title': 'Corrective Action Tracker — Q2 2026', 'date': '28 May 2026', 'type': 'CA Report', 'pages': '12', 'status': 'APPROVED'},
    {'title': 'Fire Readiness Executive Summary', 'date': '15 May 2026', 'type': 'Executive Report', 'pages': '6', 'status': 'APPROVED'},
    {'title': 'Pre-Inspection Audit — City Hospital', 'date': '08 Jun 2026', 'type': 'Audit Report', 'pages': '34', 'status': 'UNDER_REVIEW'},
  ];
}

class _ReportTypeGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final types = [
      ('Facility Report', Icons.domain_rounded, AppColors.primary),
      ('Audit Report', Icons.assignment_rounded, AppColors.secondary),
      ('Compliance Report', Icons.verified_rounded, AppColors.success),
      ('Risk Report', Icons.warning_rounded, AppColors.warning),
      ('Equipment Report', Icons.inventory_2_rounded, AppColors.info),
      ('CA Report', Icons.assignment_late_rounded, AppColors.riskHigh),
      ('Executive Report', Icons.analytics_rounded, AppColors.riskMedium),
      ('NOC Readiness', Icons.shield_rounded, AppColors.success),
      ('Govt Format', Icons.account_balance_rounded, AppColors.secondary),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: types.map((t) => GestureDetector(
        onTap: () => _showGenerateSheet(context, t.$1),
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: t.$3.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(t.$2, color: t.$3, size: 22)),
            const SizedBox(height: 8),
            Text(t.$1, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.center),
          ]),
        ),
      )).toList(),
    );
  }

  void _showGenerateSheet(BuildContext context, String type) => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Generate $type', style: AppTextStyles.h4),
        const SizedBox(height: 20),
        const TextField(decoration: InputDecoration(labelText: 'Facility', prefixIcon: Icon(Icons.business_rounded, size: 20, color: AppColors.textSecondary))),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'From Date', prefixIcon: Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary)))),
          SizedBox(width: 12),
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'To Date', prefixIcon: Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary)))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📊 $type generating...'))); },
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate'),
          )),
        ]),
      ]),
    ),
  );
}

class _ReportItem extends StatelessWidget {
  final Map<String, String> data;
  const _ReportItem({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['title']!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600), maxLines: 2),
        const SizedBox(height: 4),
        Text('${data['type']}  ·  ${data['date']}  ·  ${data['pages']} pages', style: AppTextStyles.caption),
      ])),
      const SizedBox(width: 8),
      Column(children: [
        StatusBadge(status: data['status']!),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.share_rounded, size: 16, color: AppColors.textHint),
          SizedBox(width: 8),
          Icon(Icons.download_rounded, size: 16, color: AppColors.textHint),
        ]),
      ]),
    ]),
  );
}
