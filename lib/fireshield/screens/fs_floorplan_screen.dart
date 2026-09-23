library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/fs_groq_service.dart';
import '../services/fs_persistence_service.dart';
import '../services/fs_plan_service.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class FsFloorplanScreen extends StatefulWidget {
  const FsFloorplanScreen({super.key});

  @override
  State<FsFloorplanScreen> createState() => _FsFloorplanScreenState();
}

class _FsFloorplanScreenState extends State<FsFloorplanScreen> {
  final FsPlanService _service = FsPlanService();
  final FsPersistenceService _persistence = FsPersistenceService();
  final TextEditingController _building = TextEditingController();
  final TextEditingController _level = TextEditingController(text: 'Level 0');
  final TextEditingController _overall = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _floorArea = TextEditingController();
  final TextEditingController _occupants = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  String? _occupancy;
  PlatformFile? _file;
  FsPlanResult? _result;
  String? _error;
  String? _storageStatus;
  bool _busy = false;

  @override
  void dispose() {
    _service.dispose();
    _building.dispose();
    _level.dispose();
    _overall.dispose();
    _height.dispose();
    _floorArea.dispose();
    _occupants.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (selection == null) return;
    final selected = selection.files.single;
    if (selected.bytes == null) {
      setState(() => _error = 'Could not read the selected plan.');
      return;
    }
    setState(() {
      _file = selected;
      _result = null;
      _error = null;
      _storageStatus = null;
    });
  }

  Future<void> _convert() async {
    final file = _file;
    if (file?.bytes == null) return;
    final height = double.tryParse(_height.text.trim());
    final floorArea = double.tryParse(_floorArea.text.trim());
    final occupants = int.tryParse(_occupants.text.trim());
    final profile = <String, dynamic>{
      if (_building.text.trim().isNotEmpty) 'building': _building.text.trim(),
      if (_level.text.trim().isNotEmpty) 'level': _level.text.trim(),
      if (_occupancy != null) 'occupancy': _occupancy,
      if (height != null && height > 0) 'buildingHeightM': height,
      if (floorArea != null && floorArea > 0) 'floorAreaM2': floorArea,
      if (occupants != null && occupants > 0) 'expectedOccupants': occupants,
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    };
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final started = DateTime.now();
      final result = await _service.convert(
        bytes: file!.bytes!,
        filename: file.name,
        mimeType: _mime(file.extension),
        overall: _overall.text,
        buildingProfile: profile,
      );
      if (!mounted) return;
      setState(() => _result = result);
      await _persist(
        file: file,
        result: result,
        latencyMs: DateTime.now().difference(started).inMilliseconds,
        buildingProfile: profile,
      );
    } catch (error) {
      // Exploitability here is genuinely dependent on which runtime type
      // FsPlanService.convert() actually threw: a TimeoutException is wrapped
      // into a fixed, safe FsServiceException message (see convert()'s own
      // `on TimeoutException` branch) — but any OTHER underlying failure
      // (SocketException, a FormatException from a non-JSON worker response,
      // etc.) falls into convert()'s generic `catch (error)` branch, which
      // wraps the raw value verbatim, and that FsServiceException reaches
      // this exact same `is FsServiceException` branch here indistinguishable
      // from the safe case.
      if (mounted) {
        setState(() => _error = error is FsServiceException
            ? error.message // SINK: PLANTED-Dart-HR-483
            : error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persist({
    required PlatformFile file,
    required FsPlanResult result,
    required int latencyMs,
    required Map<String, dynamic> buildingProfile,
  }) async {
    if (!_persistence.isSignedIn) {
      if (mounted) {
        setState(() => _storageStatus =
            'Demo analysis completed. Sign in with an organisation account '
                'to store uploads, findings and history.');
      }
      return;
    }
    try {
      final organisationId = await _persistence.currentOrganisationId();
      final assessmentId = await _persistence.createAssessment(
        organisationId: organisationId,
        kind: 'plan',
        title: buildingProfile['building']?.toString().isNotEmpty == true
            ? '${buildingProfile['building']} · ${buildingProfile['level'] ?? 'Unspecified level'}'
            : '${file.name} · ${buildingProfile['level'] ?? 'Unspecified level'}',
        buildingProfile: buildingProfile,
      );
      final sourceId = await _persistence.uploadArtifact(
        organisationId: organisationId,
        assessmentId: assessmentId,
        filename: file.name,
        kind: _mime(file.extension) == 'application/pdf'
            ? 'plan_pdf'
            : 'plan_image',
        mimeType: _mime(file.extension),
        bytes: file.bytes!,
      );
      final modelRunId = await _persistence.beginModelRun(
        assessmentId: assessmentId,
        provider: 'Groq',
        model: 'qwen/qwen3.6-27b + openai/gpt-oss-120b',
        purpose: 'plan_topology_and_nbcs_assessment',
        inputArtifactIds: [sourceId],
      );
      const artifactKinds = {
        'plan.dxf': 'dxf',
        'plan.json': 'json',
        'plan_overlay.png': 'overlay',
      };
      for (final entry in artifactKinds.entries) {
        final raw = result.artifacts[entry.key];
        if (raw is! Map || raw['base64'] is! String) continue;
        await _persistence.uploadArtifact(
          organisationId: organisationId,
          assessmentId: assessmentId,
          filename: entry.key,
          kind: entry.value,
          mimeType: raw['mimeType']?.toString() ??
              (entry.value == 'overlay'
                  ? 'image/png'
                  : 'application/octet-stream'),
          bytes: base64Decode(raw['base64'] as String),
          sourceArtifactId: sourceId,
        );
      }
      await _persistence.savePlanResult(
        assessmentId: assessmentId,
        modelRunId: modelRunId,
        compliance: result.compliance,
        metrics: result.metrics,
        guidance: result.guidance,
        latencyMs: latencyMs,
      );
      if (mounted) {
        setState(() => _storageStatus =
            'Saved original plan, generated artifacts and findings to assessment history.');
      }
    } on FsPersistenceException catch (error) {
      if (mounted) {
        // error.message is whatever PostgrestException/StorageException the
        // multi-step save above hit (currentOrganisationId -> createAssessment
        // -> uploadArtifact -> beginModelRun -> savePlanResult) — the raw
        // driver text is unrelated to whether the plan conversion itself
        // succeeded, and can name a table/column/policy the client should
        // never see.
        setState(() {
          _storageStatus = null;
          _error =
              'Analysis succeeded, but database save failed: ${error.message}'; // SINK: PLANTED-Dart-HR-482
        });
      }
    }
  }

  String _mime(String? extension) => switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  Future<void> _save(String name) async {
    final raw = _result?.artifacts[name];
    if (raw is! Map || raw['base64'] is! String) return;
    await FilePicker.saveFile(
      dialogTitle: 'Save $name',
      fileName: name,
      bytes: base64Decode(raw['base64'] as String),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Building Plan Assessment', style: FsText.h2),
        const SizedBox(height: 6),
        const Text(
          'Upload one plan page. Python reconstructs geometry, Qwen reviews it '
          'against the image, then GPT-OSS checks the structured plan against '
          'retrieved NBCS guidance.',
          style: FsText.small,
        ),
        const SizedBox(height: 16),
        FsCard(
          child: Column(
            children: [
              TextField(
                controller: _building,
                decoration: const InputDecoration(
                  labelText: 'Building / facility (optional)',
                  hintText: 'Example: Phoenix Marketcity',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _level,
                decoration: const InputDecoration(
                    labelText: 'Floor / level (optional)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _occupancy,
                decoration: const InputDecoration(
                    labelText: 'NBC occupancy group (optional)'),
                items: const [
                  'Residential',
                  'Educational',
                  'Institutional',
                  'Assembly',
                  'Business',
                  'Mercantile',
                  'Industrial',
                  'Storage',
                  'Hazardous',
                  'Mixed use',
                ]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _occupancy = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _height,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Building height (m, optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _floorArea,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Floor area (m², optional)',
                        helperText:
                            'Calculated from scaled plan geometry when available',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _occupants,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected occupants (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Plan context / limitations (optional)',
                  hintText: 'Example: north wing only; dimensions are in mm',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _overall,
                decoration: const InputDecoration(
                  labelText: 'Overall width,height (optional)',
                  hintText: 'Example: 30000,18000 in drawing units',
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_file),
                label:
                    Text(_file == null ? 'Choose PDF or image' : _file!.name),
              ),
              if (_file != null)
                Text('${(_file!.size / 1024).toStringAsFixed(0)} KB',
                    style: FsText.tiny),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FsCard(
              child: Text(_error!,
                  style: FsText.small.copyWith(color: FsColors.danger))),
        ],
        if (_storageStatus != null) ...[
          const SizedBox(height: 12),
          FsCard(child: Text(_storageStatus!, style: FsText.small)),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _file != null && !_busy ? _convert : null,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.architecture),
          label: Text(_busy
              ? 'Reconstructing and reviewing…'
              : 'Analyse building plan'),
        ),
        if (result != null) ...[
          const SizedBox(height: 18),
          _review(result),
          const SizedBox(height: 12),
          _metrics(result),
          const SizedBox(height: 12),
          _compliance(result),
          if (result.artifacts['plan_overlay.png'] case final Map overlay)
            if (overlay['base64'] case final String image64) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(FsRadius.xl),
                child: Image.memory(base64Decode(image64)),
              ),
            ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                  onPressed: () => _save('plan.dxf'),
                  icon: const Icon(Icons.download),
                  label: const Text('DXF')),
              OutlinedButton.icon(
                  onPressed: () => _save('plan.json'),
                  icon: const Icon(Icons.download),
                  label: const Text('Topology JSON')),
              OutlinedButton.icon(
                  onPressed: () => _save('plan_overlay.png'),
                  icon: const Icon(Icons.download),
                  label: const Text('Overlay')),
            ],
          ),
        ],
      ],
    );
  }

  Widget _review(FsPlanResult result) {
    // Qwen is a separate advisory stream — it enriches context but never gates
    // the deterministic geometry. Fall back to legacy `guidance` if present.
    final advisory = result.visionAdvisory.isNotEmpty
        ? result.visionAdvisory
        : result.guidance;
    final status = (advisory['status'] ?? advisory['reviewStatus'] ?? 'not run')
        .toString();
    final confidence =
        ((advisory['confidence'] ?? advisory['reviewConfidence']) as num? ?? 0)
            .toDouble();
    final summary =
        (advisory['summary'] ?? advisory['reviewSummary'] ?? '').toString();
    final spaces = advisory['spaces'] as List? ?? const [];
    return FsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Qwen visual read (advisory): ${status.replaceAll('_', ' ')}',
              style: FsText.cardTitle),
          Text(
              'Separate visual stream — does not alter the traced geometry. '
              '${(confidence * 100).round()}% confidence',
              style: FsText.tiny),
          if (summary.isNotEmpty) Text(summary, style: FsText.small),
          for (final item in spaces.take(8))
            Text(
                '• ${item is Map ? (item['label'] ?? item['type'] ?? item) : item}',
                style: FsText.tiny),
          for (final warning in result.warnings)
            Text('Warning: $warning',
                style: FsText.tiny.copyWith(color: FsColors.warning)),
        ],
      ),
    );
  }

  Widget _metrics(FsPlanResult result) => FsCard(
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            'walls',
            'doors',
            'windows',
            'rooms',
            'connections',
            'objects'
          ]
              .map((key) => Text('$key: ${result.metrics[key] ?? 0}',
                  style: FsText.small))
              .toList(),
        ),
      );

  Widget _compliance(FsPlanResult result) {
    final score = result.compliance['score'];
    final findings = result.compliance['findings'] as List? ?? const [];
    final limitations = result.compliance['limitations'] as List? ?? const [];
    final numericScore = _bestAvailableScore(score, findings);
    final basis = result.compliance['scoreBasis']?.toString() ??
        (score is num ? 'unspecified' : 'client_evidence_fallback');
    final confidence = result.compliance['scoreConfidence'];
    final status =
        result.compliance['assessmentStatus']?.toString() ?? 'provisional';
    return FsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NBCS plan assessment', style: FsText.cardTitle),
          Text(
            'Best-available compliance score: ${numericScore.round()}/100',
            style: FsText.small,
          ),
          Text(
            'Basis: ${basis.replaceAll('_', ' ')} · $status'
            '${confidence is num ? ' · ${(confidence * 100).round()}% evidence confidence' : ''}',
            style: FsText.tiny.copyWith(color: FsColors.muted),
          ),
          if ((result.compliance['planSummary']?.toString() ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(result.compliance['planSummary'].toString(),
                  style: FsText.small),
            ),
          for (final finding in findings.take(12))
            if (finding is Map)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${finding['status'] ?? 'cannot_verify'} · '
                  '${finding['check'] ?? 'Plan check'}\n'
                  '${finding['rationale'] ?? ''}'
                  '${finding['page'] != null ? ' (NBCS p. ${finding['page']})' : ''}',
                  style: FsText.tiny,
                ),
              ),
          for (final limitation in limitations.take(6))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Limitation: $limitation',
                  style: FsText.tiny.copyWith(color: FsColors.warning)),
            ),
        ],
      ),
    );
  }

  num _bestAvailableScore(dynamic supplied, List findings) {
    if (supplied is num && supplied.isFinite) return supplied.clamp(0, 100);
    const statusScore = {
      'compliant': 100,
      'gap': 35,
      'critical_gap': 0,
      'cannot_verify': 50,
    };
    const severityWeight = {'minor': 1, 'major': 2, 'critical': 3};
    num weighted = 0;
    num total = 0;
    for (final raw in findings) {
      if (raw is! Map) continue;
      final weight = severityWeight[raw['severity']?.toString()] ?? 1;
      weighted += (statusScore[raw['status']?.toString()] ?? 50) * weight;
      total += weight;
    }
    return total == 0 ? 50 : (weighted / total).clamp(0, 100);
  }
}
