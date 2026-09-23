import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

// ─── Evidence data model ────────────────────────────────────────────────────

class EvidenceRecord {
  final String imagePath;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String itemId;
  bool pendingSync;
  String? aiAsset;
  String? aiCondition;
  int? aiConfidence;
  bool aiAnalysing;

  EvidenceRecord({
    required this.imagePath,
    required this.timestamp,
    required this.itemId,
    this.latitude,
    this.longitude,
    this.pendingSync = true,
    this.aiAsset,
    this.aiCondition,
    this.aiConfidence,
    this.aiAnalysing = false,
  });
}

String _aiAssetFor(String question) {
  final q = question.toLowerCase();
  if (q.contains('extinguish')) return 'Fire Extinguisher — Type ABC';
  if (q.contains('sprinkler')) return 'Sprinkler Head — Upright';
  if (q.contains('detector') || q.contains('smoke')) return 'Smoke Detector — Photoelectric';
  if (q.contains('exit') || q.contains('egress')) return 'Emergency Exit Sign — LED';
  if (q.contains('hydrant')) return 'Fire Hydrant — 63mm';
  if (q.contains('hose')) return 'Hose Reel — Type 1';
  if (q.contains('panel')) return 'Fire Alarm Control Panel';
  if (q.contains('door')) return 'Fire Door — 60-min rating';
  return 'Fire Safety Asset';
}

// ─── GPS helper ─────────────────────────────────────────────────────────────

Future<Position?> _fetchPosition() async {
  try {
    final svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 6)),
    );
  } catch (_) {
    return null;
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class AuditExecutionScreen extends StatefulWidget {
  const AuditExecutionScreen({super.key});
  @override
  State<AuditExecutionScreen> createState() => _State();
}

class _State extends State<AuditExecutionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _audit = mockAudits[0];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: mockSections.length, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  double get _overallProgress {
    final total = mockSections.fold(0, (s, sec) => s + sec.total);
    final done  = mockSections.fold(0, (s, sec) => s + sec.completed);
    return total == 0 ? 0 : done / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Audit In Progress', style: AppTextStyles.h5),
          Text(_audit.auditNo, style: AppTextStyles.caption),
        ]),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _showExitDialog),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton.icon(
            onPressed: _showPauseDialog,
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 18, color: AppColors.warning),
            label: const Text('Pause', style: TextStyle(color: AppColors.warning, fontSize: 13)),
          ),
          TextButton.icon(
            onPressed: () => context.push('/audit-summary', extra: _audit),
            icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
            label: const Text('Submit', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(children: [
            _ProgressHeader(progress: _overallProgress, audit: _audit),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              padding: EdgeInsets.zero,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.caption,
              indicator: const UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 2), borderRadius: BorderRadius.all(Radius.circular(2))),
              tabs: mockSections.map((s) => Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.title),
                  if (s.nonCompliant > 0) ...[
                    const SizedBox(width: 6),
                    Container(width: 18, height: 18, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Center(child: Text('${s.nonCompliant}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
                  ],
                ]),
              )).toList(),
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: mockSections.map((s) => _SectionView(section: s)).toList(),
      ),
    );
  }

  void _showExitDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Save & Exit Audit?', style: AppTextStyles.h5),
      content: const Text('Your progress will be saved as a draft. You can resume anytime.', style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.of(context).pop(); context.pop(); }, child: const Text('Save Draft')),
      ],
    ),
  );

  void _showPauseDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Pause Audit', style: AppTextStyles.h5),
      content: const Text('The audit will be paused. Progress is auto-saved.', style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.of(context).pop(); context.pop(); }, child: const Text('Pause')),
      ],
    ),
  );
}

// ─── Progress header ─────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final double progress;
  final MockAudit audit;
  const _ProgressHeader({required this.progress, required this.audit});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(audit.facilityName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          Text('${(progress * 100).toInt()}% Complete', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.borderLight, color: AppColors.primary, minHeight: 6)),
        const SizedBox(height: 4),
        Row(children: [
          _ProgressPill('${audit.completed} Done', AppColors.success),
          const SizedBox(width: 8),
          _ProgressPill('${audit.nonCompliant} Issues', AppColors.error),
          const SizedBox(width: 8),
          _ProgressPill('${audit.totalItems - audit.completed} Left', AppColors.textSecondary),
        ]),
      ])),
    ]),
  );
}

class _ProgressPill extends StatelessWidget {
  final String text;
  final Color color;
  const _ProgressPill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
  );
}

// ─── Section view ─────────────────────────────────────────────────────────────

class _SectionView extends StatefulWidget {
  final MockChecklistSection section;
  const _SectionView({required this.section});
  @override
  State<_SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<_SectionView> {
  final Map<String, String> _responses = {};
  final Map<String, bool> _expanded = {};
  final Map<String, List<EvidenceRecord>> _evidence = {};

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _SectionProgressBar(section: widget.section),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: widget.section.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final item = widget.section.items[i];
            return _ChecklistItemCard(
              item: item,
              index: i + 1,
              response: _responses[item.id] ?? item.response,
              isExpanded: _expanded[item.id] ?? (item.response.isEmpty),
              evidenceCount: (_evidence[item.id] ?? []).length,
              onResponseChanged: (r) => setState(() { _responses[item.id] = r; _expanded[item.id] = false; }),
              onToggleExpand: () => setState(() => _expanded[item.id] = !(_expanded[item.id] ?? false)),
              onEvidenceTap: () => _openEvidenceSheet(item),
            );
          },
        ),
      ),
    ]);
  }

  void _openEvidenceSheet(MockChecklistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EvidenceSheet(
        item: item,
        photos: List.from(_evidence[item.id] ?? []),
        onPhotosChanged: (updated) {
          if (mounted) setState(() => _evidence[item.id] = updated);
        },
      ),
    );
  }
}

// ─── Section progress bar ────────────────────────────────────────────────────

class _SectionProgressBar extends StatelessWidget {
  final MockChecklistSection section;
  const _SectionProgressBar({required this.section});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(section.title, style: AppTextStyles.h6),
          Text('${section.completed}/${section.total}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text(section.standard, style: AppTextStyles.caption),
      ])),
      const SizedBox(width: 12),
      if (section.nonCompliant > 0) Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(20)),
        child: Text('${section.nonCompliant} Non-Compliant', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ─── Checklist item card ──────────────────────────────────────────────────────

class _ChecklistItemCard extends StatelessWidget {
  final MockChecklistItem item;
  final int index;
  final String response;
  final bool isExpanded;
  final int evidenceCount;
  final void Function(String) onResponseChanged;
  final VoidCallback onToggleExpand, onEvidenceTap;

  const _ChecklistItemCard({
    required this.item, required this.index, required this.response,
    required this.isExpanded, required this.evidenceCount,
    required this.onResponseChanged, required this.onToggleExpand, required this.onEvidenceTap,
  });

  Color get _borderColor => switch (response) {
    'YES' => AppColors.success,
    'NO' => AppColors.error,
    'PARTIAL' => AppColors.warning,
    _ => AppColors.border,
  };

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor, width: response.isEmpty ? 1 : 1.5),
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1))],
    ),
    child: Column(children: [
      InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ItemNumber(number: index, response: response),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.question, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4)),
              const SizedBox(height: 6),
              Row(children: [
                SeverityBadge(severity: item.severity),
                const SizedBox(width: 8),
                Flexible(child: Text(item.standard, style: AppTextStyles.caption.copyWith(color: AppColors.info), overflow: TextOverflow.ellipsis)),
                if (item.isFlagged) ...[const SizedBox(width: 6), const Icon(Icons.flag_rounded, size: 12, color: AppColors.error)],
              ]),
            ])),
            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(children: [
          _ResponseBtn(label: 'YES', selected: response == 'YES', color: AppColors.success, onTap: () => onResponseChanged('YES')),
          const SizedBox(width: 8),
          _ResponseBtn(label: 'NO', selected: response == 'NO', color: AppColors.error, onTap: () => onResponseChanged('NO')),
          const SizedBox(width: 8),
          _ResponseBtn(label: 'PARTIAL', selected: response == 'PARTIAL', color: AppColors.warning, onTap: () => onResponseChanged('PARTIAL')),
          const SizedBox(width: 8),
          _ResponseBtn(label: 'N/A', selected: response == 'NA', color: AppColors.textSecondary, onTap: () => onResponseChanged('NA')),
        ]),
      ),
      if (isExpanded) ...[
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _GuidanceBox(text: item.guidance),
            const SizedBox(height: 12),
            Row(children: [
              _ActionIcon(icon: Icons.camera_alt_rounded, label: 'Photo', color: AppColors.primary, onTap: onEvidenceTap, badgeCount: evidenceCount),
              const SizedBox(width: 8),
              _ActionIcon(icon: Icons.photo_library_rounded, label: 'Gallery', color: AppColors.secondary, onTap: onEvidenceTap),
              const SizedBox(width: 8),
              _ActionIcon(icon: Icons.mic_rounded, label: 'Voice', color: AppColors.success, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice notes — next release'), duration: Duration(seconds: 2)))),
              const SizedBox(width: 8),
              _ActionIcon(icon: Icons.attach_file_rounded, label: 'Doc', color: AppColors.warning, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document attach — next release'), duration: Duration(seconds: 2)))),
              const SizedBox(width: 8),
              _ActionIcon(icon: Icons.flag_rounded, label: 'Flag', color: item.isFlagged ? AppColors.error : AppColors.textHint, onTap: () {}),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Observation Notes', hintText: 'Describe what you observed...', prefixIcon: Icon(Icons.edit_note_rounded, size: 20, color: AppColors.textSecondary)),
              maxLines: 2,
              style: AppTextStyles.bodySmall,
            ),
          ]),
        ),
      ],
    ]),
  );
}

class _ItemNumber extends StatelessWidget {
  final int number;
  final String response;
  const _ItemNumber({required this.number, required this.response});

  Color get _color => switch (response) {
    'YES' => AppColors.success, 'NO' => AppColors.error,
    'PARTIAL' => AppColors.warning, 'NA' => AppColors.textSecondary, _ => AppColors.textHint,
  };
  IconData? get _icon => switch (response) {
    'YES' => Icons.check_rounded, 'NO' => Icons.close_rounded,
    'PARTIAL' => Icons.remove_rounded, 'NA' => Icons.block_rounded, _ => null,
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      color: _color.withValues(alpha: response.isEmpty ? 0.05 : 0.12),
      shape: BoxShape.circle,
      border: Border.all(color: _color.withValues(alpha: 0.3)),
    ),
    child: Center(child: _icon != null
      ? Icon(_icon, size: 16, color: _color)
      : Text('$number', style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w700))),
  );
}

class _ResponseBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ResponseBtn({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : AppColors.borderLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? color : AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
    ),
  );
}

class _GuidanceBox extends StatelessWidget {
  final String text;
  const _GuidanceBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.info, height: 1.5))),
    ]),
  );
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;
  const _ActionIcon({required this.icon, required this.label, required this.color, required this.onTap, this.badgeCount = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Stack(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        if (badgeCount > 0) Positioned(top: 0, right: 0, child: Container(
          width: 14, height: 14,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: Center(child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900))),
        )),
      ]),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
    ]),
  );
}

// ─── Evidence sheet (real camera) ───────────────────────────────────────────

class _EvidenceSheet extends StatefulWidget {
  final MockChecklistItem item;
  final List<EvidenceRecord> photos;
  final void Function(List<EvidenceRecord>) onPhotosChanged;
  const _EvidenceSheet({required this.item, required this.photos, required this.onPhotosChanged});
  @override
  State<_EvidenceSheet> createState() => _EvidenceSheetState();
}

class _EvidenceSheetState extends State<_EvidenceSheet> {
  late List<EvidenceRecord> _photos;
  bool _capturing = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  Future<void> _capture(ImageSource source) async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final xFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xFile == null) { setState(() => _capturing = false); return; }

      final pos = await _fetchPosition();
      final record = EvidenceRecord(
        imagePath: xFile.path,
        timestamp: DateTime.now(),
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        itemId: widget.item.id,
        aiAnalysing: true,
      );

      setState(() {
        _photos = [..._photos, record];
        _capturing = false;
      });
      widget.onPhotosChanged(_photos);

      // AI analysis simulation
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      final idx = _photos.indexOf(record);
      if (idx == -1) return;
      setState(() {
        _photos[idx].aiAnalysing = false;
        _photos[idx].aiAsset = _aiAssetFor(widget.item.question);
        _photos[idx].aiCondition = ['Good — Serviceable', 'Pressure OK — Pin Intact', 'Functional — Recently Tested'][_rng.nextInt(3)];
        _photos[idx].aiConfidence = 79 + _rng.nextInt(18);
      });
      widget.onPhotosChanged(_photos);
    } catch (_) {
      setState(() => _capturing = false);
    }
  }

  void _delete(int index) {
    setState(() => _photos.removeAt(index));
    widget.onPhotosChanged(_photos);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Capture Evidence', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(widget.item.question, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text('Photos are GPS-tagged & timestamped automatically', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ]),
            ]),
          ),
          const Divider(height: 24),
          // Camera / gallery buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _CaptureBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                sublabel: 'Open Camera',
                color: AppColors.primary,
                loading: _capturing,
                onTap: () => _capture(ImageSource.camera),
              )),
              const SizedBox(width: 12),
              Expanded(child: _CaptureBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                sublabel: 'Choose Photo',
                color: AppColors.secondary,
                loading: false,
                onTap: () => _capture(ImageSource.gallery),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          // Photo count badge
          if (_photos.isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('${_photos.length} photo${_photos.length > 1 ? 's' : ''} captured', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.sync_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Pending Sync', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Photos list
          Expanded(
            child: _photos.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.photo_camera_outlined, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No photos yet', style: AppTextStyles.bodySmall),
                  SizedBox(height: 4),
                  Text('Tap "Take Photo" to open camera', style: AppTextStyles.caption),
                ]))
              : ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _photos.length,
                  itemBuilder: (_, i) => _PhotoCard(
                    photo: _photos[i],
                    index: i + 1,
                    onDelete: () => _delete(i),
                    onRetake: () => _capture(ImageSource.camera),
                  ),
                ),
          ),
        ]),
      ),
    );
  }
}

class _CaptureBtn extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _CaptureBtn({required this.icon, required this.label, required this.sublabel, required this.color, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: loading ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        loading
          ? SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: color, strokeWidth: 2.5))
          : Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(sublabel, style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.7), fontSize: 10)),
      ]),
    ),
  );
}

class _PhotoCard extends StatelessWidget {
  final EvidenceRecord photo;
  final int index;
  final VoidCallback onDelete, onRetake;
  const _PhotoCard({required this.photo, required this.index, required this.onDelete, required this.onRetake});

  String get _time {
    final t = photo.timestamp;
    return '${t.day.toString().padLeft(2,'0')}/${t.month.toString().padLeft(2,'0')}/${t.year}  ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:${t.second.toString().padLeft(2,'0')}';
  }

  String get _gps => photo.latitude != null
    ? '${photo.latitude!.toStringAsFixed(5)}, ${photo.longitude!.toStringAsFixed(5)}'
    : 'GPS unavailable';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Thumbnail
      ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(children: [
          SizedBox(
            width: double.infinity, height: 180,
            child: Image.file(File(photo.imagePath), fit: BoxFit.cover),
          ),
          Positioned(top: 10, left: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
            child: Text('Photo $index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          )),
          Positioned(top: 10, right: 10, child: Row(children: [
            _IconBtn(icon: Icons.replay_rounded, color: AppColors.warning, onTap: onRetake),
            const SizedBox(width: 6),
            _IconBtn(icon: Icons.delete_rounded, color: AppColors.error, onTap: () => _confirmDelete(context)),
          ])),
        ]),
      ),
      // Metadata
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _MetaRow(icon: Icons.access_time_rounded, text: _time, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          _MetaRow(icon: Icons.location_on_rounded, text: _gps, color: AppColors.info),
          const SizedBox(height: 6),
          _MetaRow(icon: Icons.sync_rounded, text: 'Pending Upload Sync', color: AppColors.warning),
        ]),
      ),
      // AI Analysis section
      const Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Divider(height: 1),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: photo.aiAnalysing
          ? Row(children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.purple, strokeWidth: 2)),
              const SizedBox(width: 10),
              Text('AI analysing photo...', style: AppTextStyles.caption.copyWith(color: Colors.purple, fontWeight: FontWeight.w600)),
            ])
          : photo.aiAsset != null
            ? _AiAnalysisBox(photo: photo)
            : const SizedBox.shrink(),
      ),
    ]),
  );

  void _confirmDelete(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete Photo?', style: AppTextStyles.h6),
      content: const Text('This photo will be removed from the audit record.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.of(context).pop(); onDelete(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetaRow({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: color),
    const SizedBox(width: 6),
    Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: color, fontSize: 10))),
  ]);
}

class _AiAnalysisBox extends StatelessWidget {
  final EvidenceRecord photo;
  const _AiAnalysisBox({required this.photo});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.purple.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.purple),
        const SizedBox(width: 6),
        const Text('AI Analysis', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w800)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('COMPLIANT', style: AppTextStyles.caption.copyWith(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 9)),
        ),
      ]),
      const SizedBox(height: 8),
      _AiRow('Detected Asset', photo.aiAsset!),
      _AiRow('Condition', photo.aiCondition!),
      _AiRow('Confidence', '${photo.aiConfidence}%'),
      const SizedBox(height: 6),
      LinearProgressIndicator(
        value: (photo.aiConfidence ?? 0) / 100,
        backgroundColor: Colors.purple.withValues(alpha: 0.1),
        valueColor: const AlwaysStoppedAnimation(Colors.purple),
        borderRadius: BorderRadius.circular(4),
        minHeight: 4,
      ),
    ]),
  );
}

class _AiRow extends StatelessWidget {
  final String label, value;
  const _AiRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 10))),
      Expanded(child: Text(value, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 10))),
    ]),
  );
}
