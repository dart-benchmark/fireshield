import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DocumentIntelligenceScreen extends StatefulWidget {
  const DocumentIntelligenceScreen({super.key});
  @override
  State<DocumentIntelligenceScreen> createState() => _State();
}

class _State extends State<DocumentIntelligenceScreen> with TickerProviderStateMixin {
  String? _selectedDocType;
  String _stage = 'upload'; // upload | processing | result
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _progress = 0;

  static const _docTypes = [
    {'key': 'floor_plan', 'label': 'Floor Plan (PDF/CAD)', 'icon': Icons.map_rounded},
    {'key': 'bim', 'label': 'BIM File (.rvt / .ifc)', 'icon': Icons.view_in_ar_rounded},
    {'key': 'noc_doc', 'label': 'NOC Document (PDF)', 'icon': Icons.description_rounded},
    {'key': 'fire_plan', 'label': 'Approved Fire Plan', 'icon': Icons.local_fire_department_rounded},
    {'key': 'erp', 'label': 'Emergency Response Plan', 'icon': Icons.crisis_alert_rounded},
  ];

  static const _extractionResult = {
    'buildingSummary': {
      'name': 'Phoenix Marketcity — Main Tower A',
      'type': 'Shopping Mall / Mixed Occupancy',
      'floors': '4 above ground + 3 basements',
      'totalArea': '7,50,000 sq.ft (approx.)',
      'occupancyGroup': 'Group F — Mercantile (NBC 2016)',
      'drawingRevision': 'Rev 3 | Mar 2024',
    },
    'floorRoomCount': {
      'totalRooms': '312 rooms / compartments',
      'criticalAreas': '18 critical zones',
      'exitRoutes': '6 main exit routes',
      'staircases': '8 fire staircases',
      'refugeAreas': '2 refuge areas (2F, 4F)',
    },
    'fireAssets': [
      {'name': 'Fire Extinguishers', 'count': '248', 'locations': '94 locations marked'},
      {'name': 'Hydrant Outlets', 'count': '84', 'locations': '28 per floor'},
      {'name': 'Sprinkler Heads', 'count': '12,400', 'locations': 'Entire retail floor'},
      {'name': 'Smoke Detectors', 'count': '860', 'locations': 'All zones'},
      {'name': 'Manual Call Points', 'count': '142', 'locations': 'Near staircases'},
      {'name': 'Emergency Lighting', 'count': '1,240', 'locations': 'Corridors & exits'},
    ],
    'gaps': [
      {'severity': 'High', 'finding': 'Exit route from Basement 3 not clearly marked on plan'},
      {'severity': 'Medium', 'finding': 'No sprinkler coverage shown in Generator Room'},
      {'severity': 'Medium', 'finding': 'Extinguisher locations missing from Roof Level plan'},
      {'severity': 'Low', 'finding': 'Refuge area signage not shown on 2F escape route'},
    ],
    'recommendations': [
      'Update Basement 3 exit plan with evacuation arrows (IS 16069)',
      'Confirm sprinkler coverage in Generator and Electrical Rooms',
      'Add extinguisher location markers to Roof Level drawing',
      'Include refuge area directional signage on floor plans per NBC Cl. 4.13',
    ],
  };

  static const _processingSteps = [
    'Uploading document to secure server...',
    'Parsing file structure (CAD/PDF layers)...',
    'Extracting building metadata...',
    'Identifying fire asset locations...',
    'Running compliance gap analysis...',
    'Generating intelligence report...',
  ];

  int _processingStep = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  void _startProcessing() {
    if (_selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a document type first')));
      return;
    }
    setState(() { _stage = 'processing'; _processingStep = 0; _progress = 0; });
    _runProcessing();
  }

  void _runProcessing() async {
    for (int i = 0; i < _processingSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _processingStep = i;
        _progress = ((i + 1) / _processingSteps.length * 100).round();
      });
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _stage = 'result');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(context, title: 'Document Intelligence', showBack: true),
    body: switch (_stage) {
      'processing' => _buildProcessing(),
      'result'     => _buildResult(),
      _            => _buildUpload(),
    },
  );

  // ─── Upload Stage ─────────────────────────────────────────────────────────
  Widget _buildUpload() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Document Analysis', style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
            const SizedBox(height: 2),
            const Text('Upload building plans, CAD files, or NOC documents. Our AI extracts fire safety asset data, identifies gaps, and generates compliance insights.', style: AppTextStyles.bodySmall),
          ])),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Select Document Type', style: AppTextStyles.h6),
      const SizedBox(height: 12),
      ...(_docTypes.map((d) => GestureDetector(
        onTap: () => setState(() => _selectedDocType = d['key'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _selectedDocType == d['key'] ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _selectedDocType == d['key'] ? AppColors.primary : AppColors.borderLight, width: _selectedDocType == d['key'] ? 2 : 1),
          ),
          child: Row(children: [
            Icon(d['icon'] as IconData, color: _selectedDocType == d['key'] ? AppColors.primary : AppColors.textHint, size: 24),
            const SizedBox(width: 12),
            Text(d['label'] as String, style: AppTextStyles.bodyMedium.copyWith(color: _selectedDocType == d['key'] ? AppColors.primary : AppColors.textPrimary, fontWeight: _selectedDocType == d['key'] ? FontWeight.w600 : FontWeight.w400)),
            const Spacer(),
            if (_selectedDocType == d['key']) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ))),
      const SizedBox(height: 20),
      // Simulated upload zone
      GestureDetector(
        onTap: _startProcessing,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2, style: BorderStyle.solid),
          ),
          child: Column(children: [
            const Icon(Icons.cloud_upload_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Tap to upload document', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('PDF, CAD (.dwg), BIM (.rvt/.ifc)\nMax 50 MB', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 14),
          SizedBox(width: 8),
          Expanded(child: Text('Documents are processed securely on-premise. No data leaves your network.', style: AppTextStyles.caption)),
        ]),
      ),
    ]),
  );

  // ─── Processing Stage ─────────────────────────────────────────────────────
  Widget _buildProcessing() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FadeTransition(
          opacity: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.document_scanner_rounded, size: 56, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
        const Text('Analysing Document', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Text('AI extraction in progress...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: _progress / 100, minHeight: 8, backgroundColor: AppColors.primaryLight, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text('$_progress%', style: AppTextStyles.h6.copyWith(color: AppColors.primary)),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _processingSteps[_processingStep.clamp(0, _processingSteps.length - 1)],
            key: ValueKey(_processingStep),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
          child: Column(children: List.generate(_processingSteps.length, (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(
                i < _processingStep ? Icons.check_circle_rounded : i == _processingStep ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: i < _processingStep ? AppColors.success : i == _processingStep ? AppColors.primary : AppColors.borderLight,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_processingSteps[i], style: AppTextStyles.caption.copyWith(color: i <= _processingStep ? AppColors.textPrimary : AppColors.textHint))),
            ]),
          ))),
        ),
      ]),
    ),
  );

  // ─── Result Stage ─────────────────────────────────────────────────────────
  Widget _buildResult() {
    const r = _extractionResult;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Analysis complete — AI extracted fire safety intelligence from your document.', style: AppTextStyles.bodySmall),
          ]),
        ),
        const SizedBox(height: 16),
        SectionCard(title: 'Building Summary', child: Column(children: (r['buildingSummary'] as Map<String, String>).entries.toList().asMap().entries.map((e) => InfoRow(label: e.value.key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim().replaceAll('_', ' '), value: e.value.value, isLast: e.key == (r['buildingSummary'] as Map).length - 1)).toList())),
        const SizedBox(height: 12),
        SectionCard(title: 'Floor & Room Count', child: Column(children: (r['floorRoomCount'] as Map<String, String>).entries.toList().asMap().entries.map((e) => InfoRow(label: e.value.key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim(), value: e.value.value, isLast: e.key == (r['floorRoomCount'] as Map).length - 1)).toList())),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Fire Assets Detected',
          child: Column(children: (r['fireAssets'] as List).asMap().entries.map((e) {
            final a = e.value as Map<String, String>;
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < (r['fireAssets'] as List).length - 1 ? 12 : 0),
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(a['name']!, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(a['count']!, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  Text(a['locations']!, style: AppTextStyles.caption),
                ]),
              ]),
            );
          }).toList()),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Compliance Gaps Identified',
          child: Column(children: (r['gaps'] as List).asMap().entries.map((e) {
            final g = e.value as Map<String, String>;
            final color = g['severity'] == 'High' ? AppColors.warning : g['severity'] == 'Medium' ? AppColors.info : AppColors.textHint;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(g['finding']!, style: AppTextStyles.bodySmall)),
                const SizedBox(width: 8),
                Text(g['severity']!, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList()),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'AI Recommendations',
          child: Column(children: (r['recommendations'] as List).asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Text('${e.key + 1}', style: AppTextStyles.overline.copyWith(color: AppColors.primary, fontSize: 9)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(e.value as String, style: AppTextStyles.bodySmall)),
            ]),
          )).toList()),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Analyse Another'),
            onPressed: () => setState(() { _stage = 'upload'; _selectedDocType = null; }),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Report'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intelligence report exported as PDF'))),
          )),
        ]),
      ]),
    );
  }
}
