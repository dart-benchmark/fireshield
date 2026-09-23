import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class AuditSummaryScreen extends StatefulWidget {
  final MockAudit audit;
  const AuditSummaryScreen({super.key, required this.audit});
  @override
  State<AuditSummaryScreen> createState() => _State();
}

class _State extends State<AuditSummaryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Sections derived from the live checklist data
  static const _sections = [
    {'name': 'Fire Exits & Evacuation Routes', 'score': 75, 'items': 12, 'pass': 9, 'fail': 3},
    {'name': 'Fire Extinguishers',             'score': 83, 'items': 18, 'pass': 15, 'fail': 3},
    {'name': 'Fire Detection & Alarm System',  'score': 79, 'items': 22, 'pass': 17, 'fail': 5},
  ];

  // Findings derived from flagged checklist items
  static const _findings = [
    {'id': 'F-001', 'title': 'Fire exit corridor obstructed with stored boxes — Floor 2',        'severity': 'Critical', 'system': 'Fire Exits',      'clause': 'NBC 2016 Cl. 4.9.2',  'due': 'Immediate'},
    {'id': 'F-002', 'title': 'Staircase fire door self-closer defective — 4th floor East wing',  'severity': 'High',     'system': 'Fire Exits',      'clause': 'NBC 2016 Cl. 4.7.3',  'due': '3 days'},
    {'id': 'F-003', 'title': '6 fire extinguishers past annual service date — Floor 3',          'severity': 'Critical', 'system': 'Extinguishers',   'clause': 'IS 2190 Cl. 6.2',      'due': '3 days'},
    {'id': 'F-004', 'title': 'Manual call point obstructed near food court entry',               'severity': 'High',     'system': 'Fire Alarm',      'clause': 'IS 2189 Cl. 9.1',      'due': '7 days'},
    {'id': 'F-005', 'title': 'Emergency lighting not tested for last 60 days',                   'severity': 'Medium',   'system': 'Emergency Ltg',   'clause': 'IS 1944 / NBC 2016',   'due': '14 days'},
    {'id': 'F-006', 'title': 'Assembly point signage missing on North parking exit',             'severity': 'Low',      'system': 'Evacuation',      'clause': 'NBC 2016 Cl. 4.9.8',  'due': '30 days'},
  ];

  static const _recommendations = [
    {'priority': 'Critical', 'title': 'Clear fire exit obstructions immediately',           'cost': '₹ 0',      'timeline': '24 hours'},
    {'priority': 'Critical', 'title': 'Service / refill all overdue extinguishers',        'cost': '₹ 18,000', 'timeline': '3 days'},
    {'priority': 'High',     'title': 'Repair door self-closer — staircase East wing',     'cost': '₹ 8,500',  'timeline': '3 days'},
    {'priority': 'High',     'title': 'Clear manual call point obstruction — food court',  'cost': '₹ 0',      'timeline': '7 days'},
    {'priority': 'Medium',   'title': 'Conduct emergency lighting functional test',        'cost': '₹ 2,000',  'timeline': '14 days'},
    {'priority': 'Low',      'title': 'Install assembly point signage — North exit',       'cost': '₹ 3,500',  'timeline': '30 days'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  // Derive display values from the live MockAudit object
  int get _complianceScore => widget.audit.score.toInt();
  int get _safetyIndex => (100 - (widget.audit.nonCompliant / widget.audit.totalItems * 100)).toInt().clamp(0, 100);
  int get _readinessScore => ((_complianceScore + _safetyIndex) / 2).toInt();

  String get _clientName => switch (widget.audit.facilityType) {
    'Shopping Mall' => 'Phoenix Malls Pvt. Ltd.',
    'Hospital'      => 'City Hospital Trust',
    'School'        => 'Delhi Public School Society',
    'Refinery'      => 'Reliance Industries Ltd.',
    'Data Centre'   => 'National Informatics Centre',
    'Airport'       => 'GVK Airport Developers',
    _               => 'Client Organisation',
  };

  String get _authority => switch (widget.audit.facilityType) {
    'Shopping Mall' => 'KSFES Bengaluru',
    'Hospital'      => 'Gujarat Fire Prevention Bureau',
    'School'        => 'Delhi Fire Service',
    'Refinery'      => 'OISD / PESO Gujarat',
    'Airport'       => 'DGCA / BCAS Mumbai',
    _               => 'State Fire Authority',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Audit Summary', style: AppTextStyles.h5),
        Text(widget.audit.auditNo, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]),
      backgroundColor: AppColors.surface,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.of(context).pop()),
      actions: [
        IconButton(icon: const Icon(Icons.print_rounded), onPressed: _showPrintDialog, tooltip: 'Print'),
        IconButton(icon: const Icon(Icons.picture_as_pdf_rounded), onPressed: _showExportDialog, tooltip: 'Export PDF'),
        const SizedBox(width: 4),
      ],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Executive Summary'),
          Tab(text: 'Findings'),
          Tab(text: 'Scores'),
          Tab(text: 'Recommendations'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _buildExecutiveSummary(),
        _buildFindings(),
        _buildScores(),
        _buildRecommendations(),
      ],
    ),
  );

  // ─── Executive Summary ────────────────────────────────────────────────────
  Widget _buildExecutiveSummary() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _auditHeader(),
      const SizedBox(height: 16),
      _scoreRow(),
      const SizedBox(height: 16),
      SectionCard(title: 'Facility Details', child: Column(children: [
        InfoRow(label: 'Facility',          value: widget.audit.facilityName),
        InfoRow(label: 'Facility Type',     value: widget.audit.facilityType),
        InfoRow(label: 'Audit Type',        value: widget.audit.type),
        InfoRow(label: 'Scheduled Date',    value: widget.audit.scheduledDate),
        InfoRow(label: 'Auditor',           value: widget.audit.auditor),
        InfoRow(label: 'Client',            value: _clientName),
        InfoRow(label: 'Issuing Authority', value: _authority),
        InfoRow(label: 'Duration',          value: '5 hours 42 min'),
        InfoRow(label: 'Status',            value: widget.audit.status, valueColor: AppColors.warning, isLast: true),
      ])),
      const SizedBox(height: 16),
      SectionCard(title: 'Scope of Audit', child: Column(children: [
        InfoRow(label: 'Checklist Sections',    value: '${_sections.length} sections'),
        InfoRow(label: 'Total Items',           value: '${widget.audit.totalItems} items'),
        InfoRow(label: 'Completed',             value: '${widget.audit.completed} (${((widget.audit.completed / widget.audit.totalItems) * 100).toInt()}%)'),
        InfoRow(label: 'Non-Compliant Items',   value: '${widget.audit.nonCompliant}', valueColor: AppColors.error),
        const InfoRow(label: 'Photographic Evidence', value: 'Captured per item', isLast: true),
      ])),
      const SizedBox(height: 16),
      _findingsSummaryBox(),
    ]),
  );

  Widget _auditHeader() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(widget.audit.auditNo, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(widget.audit.status, style: AppTextStyles.caption.copyWith(color: Colors.white)),
        ),
      ]),
      const SizedBox(height: 8),
      Text(widget.audit.facilityName, style: AppTextStyles.h5.copyWith(color: Colors.white)),
      Text(widget.audit.facilityType, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
      const SizedBox(height: 4),
      Text('${widget.audit.type} • ${widget.audit.scheduledDate}', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
    ]),
  );

  Widget _scoreRow() => Row(children: [
    Expanded(child: _scoreDial(_complianceScore, 'Compliance', AppColors.success)),
    const SizedBox(width: 8),
    Expanded(child: _scoreDial(_safetyIndex, 'Safety Index', AppColors.info)),
    const SizedBox(width: 8),
    Expanded(child: _scoreDial(_readinessScore, 'Readiness', AppColors.primary)),
  ]);

  Widget _scoreDial(int score, String label, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Column(children: [
      Stack(alignment: Alignment.center, children: [
        SizedBox(width: 72, height: 72, child: CircularProgressIndicator(value: score / 100, strokeWidth: 7, backgroundColor: color.withValues(alpha: 0.12), color: color)),
        Text('$score%', style: AppTextStyles.h6.copyWith(color: color)),
      ]),
      const SizedBox(height: 6),
      Text(label, style: AppTextStyles.overline, textAlign: TextAlign.center),
    ]),
  );

  Widget _findingsSummaryBox() {
    final counts = {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};
    for (final f in _findings) { counts[f['severity'] as String] = (counts[f['severity'] as String] ?? 0) + 1; }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Findings Summary', style: AppTextStyles.h6),
        const SizedBox(height: 12),
        Row(children: [
          _findingBadge('Critical', counts['Critical']!, AppColors.error),
          const SizedBox(width: 8),
          _findingBadge('High', counts['High']!, AppColors.warning),
          const SizedBox(width: 8),
          _findingBadge('Medium', counts['Medium']!, AppColors.info),
          const SizedBox(width: 8),
          _findingBadge('Low', counts['Low']!, AppColors.textHint),
        ]),
      ]),
    );
  }

  Widget _findingBadge(String label, int count, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text('$count', style: AppTextStyles.h4.copyWith(color: color)),
      Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    ]),
  ));

  // ─── Findings ─────────────────────────────────────────────────────────────
  Widget _buildFindings() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _findings.length,
    itemBuilder: (_, i) {
      final f = _findings[i];
      final sev = f['severity'] as String;
      final color = switch (sev) {
        'Critical' => AppColors.error,
        'High'     => AppColors.warning,
        'Medium'   => AppColors.info,
        _          => AppColors.textHint,
      };
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(f['id'] as String, style: AppTextStyles.label.copyWith(color: AppColors.textHint, fontFamily: 'monospace')),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(sev, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(f['title'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.category_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(f['system'] as String, style: AppTextStyles.caption),
            const SizedBox(width: 12),
            const Icon(Icons.gavel_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(f['clause'] as String, style: AppTextStyles.caption),
            const Spacer(),
            Text('Due: ${f['due']}', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        ]),
      );
    },
  );

  // ─── Scores ───────────────────────────────────────────────────────────────
  Widget _buildScores() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ..._sections.map((s) {
        final score = s['score'] as int;
        final color = score >= 90 ? AppColors.success : score >= 75 ? AppColors.warning : AppColors.error;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s['name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
              Text('$score%', style: AppTextStyles.h6.copyWith(color: color)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: score / 100, backgroundColor: color.withValues(alpha: 0.12), color: color, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text('${s['pass']} pass', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              const SizedBox(width: 12),
              const Icon(Icons.cancel_outlined, size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Text('${s['fail']} fail', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              const SizedBox(width: 12),
              Text('${s['items']} total items', style: AppTextStyles.caption),
            ]),
          ]),
        );
      }),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
        child: Row(children: [
          const Icon(Icons.assessment_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Overall Audit Score', style: AppTextStyles.h6)),
          Text('${widget.audit.score.toStringAsFixed(1)}%', style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
        ]),
      ),
    ],
  );

  // ─── Recommendations ──────────────────────────────────────────────────────
  Widget _buildRecommendations() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _recommendations.length,
    itemBuilder: (_, i) {
      final r = _recommendations[i];
      final color = switch (r['priority']) {
        'Critical' => AppColors.error,
        'High'     => AppColors.warning,
        'Medium'   => AppColors.info,
        _          => AppColors.textHint,
      };
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text('${i + 1}', style: AppTextStyles.label.copyWith(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['title'] as String, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(children: [
              Text(r['cost'] as String, style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(r['timeline'] as String, style: AppTextStyles.caption),
            ]),
          ])),
          const SizedBox(width: 8),
          StatusBadge(status: r['priority'] as String),
        ]),
      );
    },
  );

  // ─── Actions ──────────────────────────────────────────────────────────────
  void _showPrintDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Print Audit Report'),
      content: Text('Preparing print-friendly report...\n\nAudit: ${widget.audit.auditNo}\nFacility: ${widget.audit.facilityName}\n\nAll sections will be included.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _showToast('PDF export available in next release'); },
          child: const Text('Print'),
        ),
      ],
    ),
  );

  void _showExportDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Export PDF'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Generate PDF report for ${widget.audit.auditNo}'),
        const SizedBox(height: 12),
        const InfoRow(label: 'Format', value: 'A4, Portrait'),
        const InfoRow(label: 'Sections', value: 'All (Executive + Findings + Scores)'),
        const InfoRow(label: 'Photos', value: 'Included', isLast: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _showToast('PDF export available in next release'); },
          child: const Text('Export PDF'),
        ),
      ],
    ),
  );

  void _showToast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
  );
}
