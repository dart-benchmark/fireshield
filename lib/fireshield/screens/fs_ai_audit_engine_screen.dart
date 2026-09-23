/// AI Audit Engine — 8 phases, now backed by real services.
///
/// Phases 1–3 stay grounded in the local NBC/BIS checkpoint master + occupancy
/// taxonomy. Phases 4–8 are wired to the live pipeline:
///   • Photo AI   — image_picker capture → CLIPSeg (in-browser, if supported)
///                  + Qwen vision (Cloudflare Worker) → observed equipment.
///   • Findings / Compliance — gpt-oss-120b reasons over the observations,
///                  querying the NBCS 2026 Part F graph live for each mandatory
///                  system, and returns findings with clause+page citations.
///   • NOC Readiness — driven by the real compliance score + open criticals.
///
/// When the Worker URL is not configured, the AI phases show an explicit
/// "not configured" state — they never fabricate compliance results.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/nbc_bis_masterdata.dart';
import '../../data/occupancy_taxonomy.dart';
import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../services/fs_clipseg_service.dart';
import '../services/fs_groq_service.dart';
import '../services/fs_noc_submission_service.dart';
import '../services/fs_persistence_service.dart';
import '../services/fs_score_formula_evaluator.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

const _kPhases = [
  ('🏢', 'Building Intelligence'),
  ('📋', 'Regulations'),
  ('✅', 'AI Checklist'),
  ('📸', 'Photo AI'),
  ('🔍', 'Gap Analysis'),
  ('⚠️', 'Findings'),
  ('📊', 'Compliance'),
  ('🏛️', 'NOC Readiness'),
];

/// Fire-safety systems the reasoning model must assess, and the equipment
/// detection types that evidence them. Used by Gap Analysis to show what is
/// expected vs observed before the model runs.
const _kSystemEvidence = {
  'Fire Extinguishers': ['extinguisher'],
  'Automatic Sprinklers': ['sprinkler'],
  'Detection & Alarm': [
    'smoke_detector',
    'heat_detector',
    'manual_call_point',
    'alarm_sounder_strobe',
    'alarm_panel',
  ],
  'Hydrant / Wet Riser': [
    'hydrant_hose_reel',
    'landing_valve',
    'fire_department_connection',
    'fire_pump',
  ],
  'Exit Signage & Emergency Lighting': ['exit_sign', 'emergency_light'],
  'Fire Doors': ['fire_door', 'door_closer'],
  'Special Suppression': ['kitchen_suppression'],
  'Evacuation Information': ['evacuation_map'],
};

/// One captured area's evidence batch. The auditor can capture several of
/// these (e.g. "Ground Floor Lobby", then "Ward B") before generating a
/// single compliance report, or generate immediately after just one.
class _ZoneEvidence {
  final Map<String, dynamic> context;
  final List<DetectedEquipment> detected;
  final List<String> dataUrls;
  const _ZoneEvidence({
    required this.context,
    required this.detected,
    required this.dataUrls,
  });

  String get label {
    final level = context['level'] as String? ?? '';
    final zone = context['zone'] as String? ?? '';
    return [level, zone].where((s) => s.isNotEmpty).join(' · ');
  }

  Map<String, dynamic> toReasonZone() => {
        'label': label.isEmpty ? 'Unnamed zone' : label,
        'level': context['level'] as String? ?? '',
        'coverage': context['coverage'] as String? ?? '',
        'detected': detected.map((d) => d.toJson()).toList(),
      };
}

/// Merge detected equipment across every captured zone into one flat list —
/// same per-type max-count/best-evidence merge Phase 4 already does within a
/// single batch, applied across batches for the Gap Analysis / persistence
/// summary views that only need a whole-building view.
List<DetectedEquipment> _mergeZoneDetections(List<_ZoneEvidence> zones) {
  final merged = <String, DetectedEquipment>{};
  for (final zone in zones) {
    for (final d in zone.detected) {
      final prev = merged[d.type];
      merged[d.type] = prev == null
          ? d
          : DetectedEquipment(
              type: d.type,
              count: prev.count > d.count ? prev.count : d.count,
              source: prev.source == d.source ? d.source : 'merged',
              condition: d.condition.isNotEmpty ? d.condition : prev.condition,
              label: d.label.isNotEmpty ? d.label : prev.label,
              confidence: prev.confidence > d.confidence
                  ? prev.confidence
                  : d.confidence,
            );
    }
  }
  return merged.values.toList();
}

class FsAiAuditEngineScreen extends StatefulWidget {
  const FsAiAuditEngineScreen({super.key});

  @override
  State<FsAiAuditEngineScreen> createState() => _FsAiAuditEngineScreenState();
}

class _FsAiAuditEngineScreenState extends State<FsAiAuditEngineScreen> {
  final FsGroqService _svc = FsGroqService();
  final FsClipsegService _clip = FsClipsegService();
  final FsPersistenceService _persistence = FsPersistenceService();

  int _phase = 0;
  BuildingType? _building;
  Map<String, dynamic> _profile = const {};
  List<_ZoneEvidence> _zones = [];
  Key _photoAiKey = UniqueKey();
  FsAuditRun? _run;
  String? _storageStatus;
  String? _storageError;
  bool _saving = false;

  List<DetectedEquipment> get _detected => _mergeZoneDetections(_zones);
  Map<String, dynamic> get _evidenceContext => _zones.isEmpty
      ? const {}
      : {
          ..._zones.last.context,
          'zoneCount': _zones.length,
          'zoneLabels': _zones.map((z) => z.label).toList(),
        };
  List<String> get _evidenceDataUrls =>
      _zones.expand((z) => z.dataUrls).toList();

  @override
  void initState() {
    super.initState();
    // Pre-select whatever was classified in the Building Classification screen.
    _building = FsAppState.instance.classifiedBuilding;
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  String _groupOf(BuildingType t) => t.subdivision.split('-').first;

  void _acceptBuilding(BuildingType t, double? heightM, double? areaM2) {
    final group = _groupOf(t);
    final sub = OccupancyTaxonomy.subdivision(t.subdivision);
    final g = OccupancyTaxonomy.group(group);
    setState(() {
      _building = t;
      _profile = {
        'occupancyGroup': group,
        'occupancy': g?.name ?? '',
        'subdivision': t.subdivision,
        'subdivisionName': sub?.name ?? '',
        'buildingType': t.label,
        if (heightM != null) 'heightM': heightM,
        if (areaM2 != null) 'areaM2': areaM2,
        'authorities': OccupancyTaxonomy.authoritiesFor(t),
      };
      _phase = 1;
    });
  }

  Future<void> _acceptSiteRun(_SiteRunResult originalResult) async {
    setState(() {
      _saving = true;
      _storageStatus = null;
      _storageError = null;
    });
    // The reasoning model's own `score` is only ever the starting point —
    // an organisation that has configured its own weighting policy (Org
    // Admin → Overview → Scoring Policy) gets that policy applied here,
    // before the run is either shown or saved.
    final orgFormula = FsAppState.instance.customScoreFormula;
    final result = orgFormula == null
        ? originalResult
        : _SiteRunResult(
            originalResult.run.applyCustomScoreFormula(orgFormula),
            originalResult.latencyMs,
          );
    if (!_persistence.isSignedIn) {
      setState(() {
        _run = result.run;
        _phase = 6;
        _saving = false;
        _storageStatus =
            'Demo analysis completed. Sign in with an organisation '
            'account to store the photos, findings and audit history.';
      });
      return;
    }
    try {
      final organisationId = await _persistence.currentOrganisationId();
      final assessmentId = await _persistence.createAssessment(
        organisationId: organisationId,
        kind: 'site',
        title: '${_building?.label ?? 'Site assessment'} · '
            '${_zones.length} zone${_zones.length == 1 ? '' : 's'}'
            '${_zones.isNotEmpty ? ' (${_zones.map((z) => z.label).where((s) => s.isNotEmpty).join(', ')})' : ''}',
        buildingProfile: {..._profile, 'evidenceContext': _evidenceContext},
      );
      final artifactIds = <String>[];
      for (var i = 0; i < _evidenceDataUrls.length; i++) {
        final dataUrl = _evidenceDataUrls[i];
        final comma = dataUrl.indexOf(',');
        if (comma < 0) continue;
        final mime =
            RegExp(r'^data:([^;]+);base64,').firstMatch(dataUrl)?.group(1) ??
                'image/jpeg';
        final extension = mime == 'image/png'
            ? 'png'
            : mime == 'image/webp'
                ? 'webp'
                : 'jpg';
        artifactIds.add(await _persistence.uploadArtifact(
          organisationId: organisationId,
          assessmentId: assessmentId,
          filename: 'site_${i + 1}.$extension',
          kind: 'site_image',
          mimeType: mime,
          bytes: base64Decode(dataUrl.substring(comma + 1)),
        ));
      }
      final modelRunId = await _persistence.beginModelRun(
        assessmentId: assessmentId,
        provider: 'Hugging Face + Groq',
        model: 'CLIPSeg + qwen/qwen3.6-27b + openai/gpt-oss-120b',
        purpose: 'site_visual_nbcs_assessment',
        inputArtifactIds: artifactIds,
      );
      await _persistence.saveSiteResult(
        assessmentId: assessmentId,
        modelRunId: modelRunId,
        result: result.run,
        latencyMs: result.latencyMs,
      );
      if (!mounted) return;
      setState(() {
        _run = result.run;
        _phase = 6;
        _storageStatus =
            'Saved evidence photos, detections, findings and citations to audit history.';
      });
    } on FsPersistenceException catch (error) {
      if (!mounted) return;
      // Same multi-step-save wrap-and-forward shape as the floor-plan
      // screen's own _persist() catch — but the site-audit save path only
      // ever shows a fixed sentence; the real Postgrest/Storage detail is
      // captured for the console only.
      debugPrint(
          'Site audit database save failed: ${error.message}'); // SAFE_SINK: PLANTED-Dart-HR-482-safe
      setState(() {
        _run = result.run;
        _phase = 6;
        _storageError =
            'Analysis succeeded, but the audit history could not be saved. Please retry from Reports.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildPhaseBar(),
          if (_saving) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: switch (_phase) {
              0 => _Phase1BuildingIntel(
                  initial: _building,
                  onNext: _acceptBuilding,
                ),
              1 => _Phase2Regulations(
                  building: _building,
                  profile: _profile,
                  svc: _svc,
                  onNext: () => setState(() => _phase = 2),
                ),
              2 => _Phase3Checklist(
                  building: _building,
                  onNext: () => setState(() => _phase = 3),
                ),
              3 => _Phase4PhotoAi(
                  key: _photoAiKey,
                  svc: _svc,
                  clip: _clip,
                  priorZones: _zones,
                  onNext: (result) => setState(() {
                    _zones = [
                      ..._zones,
                      _ZoneEvidence(
                        context: result.context,
                        detected: result.detected,
                        dataUrls: result.dataUrls,
                      ),
                    ];
                    if (result.addAnother) {
                      // New key forces a fresh _Phase4PhotoAi state so the
                      // next zone starts with empty photos/fields instead of
                      // inheriting the just-finished zone's capture.
                      _photoAiKey = UniqueKey();
                    } else {
                      _phase = 4;
                    }
                  }),
                ),
              4 => _Phase5GapAnalysis(
                  zones: _zones,
                  detected: _detected,
                  evidenceContext: _evidenceContext,
                  onNext: () => setState(() => _phase = 5),
                ),
              5 => _Phase6Findings(
                  svc: _svc,
                  profile: _profile,
                  building: _building,
                  detected: _detected,
                  evidenceContext: _evidenceContext,
                  zones: _zones,
                  onNext: _acceptSiteRun,
                ),
              6 => _Phase7Compliance(
                  run: _run,
                  storageStatus: _storageStatus,
                  storageError: _storageError,
                  onNext: () => setState(() => _phase = 7),
                ),
              _ => _Phase8NocReadiness(
                  run: _run,
                  onRestart: () => setState(() {
                    _phase = 0;
                    _building = FsAppState.instance.classifiedBuilding;
                    _zones = [];
                    _photoAiKey = UniqueKey();
                    _run = null;
                    _storageStatus = null;
                    _storageError = null;
                  }),
                ),
            },
          ),
        ],
      );

  Widget _buildPhaseBar() => Container(
        color: FsColors.surface,
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _kPhases.length,
          itemBuilder: (_, i) {
            final active = i == _phase;
            final done = i < _phase;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done
                          ? FsColors.success
                          : active
                              ? FsColors.primary
                              : FsColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(_kPhases[i].$1,
                            style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'P${i + 1}',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: active ? FsColors.primary : FsColors.subtle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

// ─── Phase 1 — Building Intelligence ───────────────────────────────────────

class _Phase1BuildingIntel extends StatefulWidget {
  final BuildingType? initial;
  final void Function(BuildingType type, double? heightM, double? areaM2)
      onNext;
  const _Phase1BuildingIntel({required this.initial, required this.onNext});

  @override
  State<_Phase1BuildingIntel> createState() => _Phase1BuildingIntelState();
}

class _Phase1BuildingIntelState extends State<_Phase1BuildingIntel> {
  BuildingType? _selected;
  final _heightCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Select the building this audit covers. Applicable '
                  'regulations and which fire systems are mandatory are derived '
                  'from the occupancy, height and area.',
                  style: FsText.small,
                ),
                const SizedBox(height: 12),
                ...buildingTypes.take(12).map((t) {
                  final sel = _selected?.key == t.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = t),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFFFFBEB) : Colors.white,
                          borderRadius: BorderRadius.circular(FsRadius.xl2),
                          border: Border.all(
                              color: sel ? FsColors.eyYellow : FsColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.label, style: FsText.cardTitle),
                                  Text(t.subdivision, style: FsText.tiny),
                                ],
                              ),
                            ),
                            if (sel)
                              const Icon(Icons.check_circle,
                                  color: FsColors.eyDark, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _numField(_heightCtrl, 'Height (m)'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numField(_areaCtrl, 'Floor area (m²)'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Optional, but height/area decide whether sprinklers, wet '
                  'risers and refuge areas are mandatory.',
                  style: FsText.tiny,
                ),
              ],
            ),
          ),
          _nextBar(
            context,
            _selected != null,
            () => widget.onNext(
              _selected!,
              double.tryParse(_heightCtrl.text.trim()),
              double.tryParse(_areaCtrl.text.trim()),
            ),
          ),
        ],
      );

  Widget _numField(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FsRadius.xl)),
        ),
      );
}

// ─── Phase 2 — Regulations (live NBC 2026 query, with local fallback) ───────

class _Phase2Regulations extends StatefulWidget {
  final BuildingType? building;
  final Map<String, dynamic> profile;
  final FsGroqService svc;
  final VoidCallback onNext;
  const _Phase2Regulations({
    required this.building,
    required this.profile,
    required this.svc,
    required this.onNext,
  });

  @override
  State<_Phase2Regulations> createState() => _Phase2RegulationsState();
}

class _Phase2RegulationsState extends State<_Phase2Regulations> {
  bool _loading = false;
  String? _error;
  List<NbcClause> _clauses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.svc.isConfigured) return; // fall back to local standards list
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = widget.profile;
    final q = 'Fire protection systems and life safety requirements for '
        '${p['subdivisionName'] ?? p['occupancy'] ?? 'this'} '
        '(${p['occupancy'] ?? ''} occupancy)'
        '${p['heightM'] != null ? ' at ${p['heightM']} m height' : ''}'
        '${p['areaM2'] != null ? ', ${p['areaM2']} m² area' : ''}';
    final seed = '${p['occupancy'] ?? ''} ${widget.building?.label ?? ''} '
        'sprinkler hydrant detector extinguisher exit refuge';
    try {
      final clauses =
          await widget.svc.nbcQuery(q, seedTerms: seed, k: 10, hops: 1);
      if (mounted) setState(() => _clauses = clauses);
    } catch (e) {
      // Same `is FsServiceException` dispatch shape as the floor-plan
      // screen's own _convert() catch, but neither branch here echoes the
      // caught value — every path renders a fixed sentence, and the actual
      // failure (whichever type it turns out to be) only ever reaches
      // debugPrint.
      debugPrint(
          'Could not load NBC 2026 clauses: $e'); // SAFE_SINK: PLANTED-Dart-HR-483-safe
      if (mounted) {
        setState(() => _error = e is FsServiceException
            ? 'The regulations service is temporarily unavailable.'
            : 'Could not load NBC 2026 clauses. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.building;
    final authorities =
        t == null ? const ['BIS'] : OccupancyTaxonomy.authoritiesFor(t);

    // Local standards from the checkpoint master (always available).
    final checkpoints = t == null
        ? allCheckpoints
        : OccupancyTaxonomy.checkpointsFor(t, allCheckpoints);
    final standards = checkpoints.map((c) => c.standardLabel).toSet().toList()
      ..sort();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('APPLICABLE AUTHORITIES',
                  style: FsText.xs.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: authorities
                    .map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: FsColors.infoLight,
                            borderRadius: BorderRadius.circular(FsRadius.full),
                          ),
                          child: Text(a,
                              style: FsText.tiny.copyWith(
                                  color: FsColors.info,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (widget.svc.isConfigured) ...[
                Row(
                  children: [
                    Text('NBCS 2026 — LIVE CLAUSES',
                        style: FsText.xs.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(width: 8),
                    if (_loading)
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  _banner('Could not load NBC 2026 clauses: $_error'),
                ..._clauses.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FsCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('📖',
                                    style: TextStyle(fontSize: 15)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(c.title,
                                        style: FsText.small.copyWith(
                                            fontWeight: FontWeight.w700))),
                                if (c.page != null)
                                  Text('p${c.page}', style: FsText.tiny),
                              ],
                            ),
                            if (c.requirement.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(c.requirement,
                                  style: FsText.tiny.copyWith(height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              Text('LOCAL STANDARDS · ${standards.length}',
                  style: FsText.xs.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              ...standards.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FsCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Text('📘', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(s,
                                  style: FsText.small
                                      .copyWith(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        _nextBar(context, true, widget.onNext),
      ],
    );
  }
}

// ─── Phase 3 — AI Checklist ─────────────────────────────────────────────────

class _Phase3Checklist extends StatelessWidget {
  final BuildingType? building;
  final VoidCallback onNext;
  const _Phase3Checklist({required this.building, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = building;
    final checkpoints = t == null
        ? allCheckpoints
        : OccupancyTaxonomy.checkpointsFor(t, allCheckpoints);
    final byCategory = <String, int>{};
    for (final c in checkpoints) {
      byCategory[c.category] = (byCategory[c.category] ?? 0) + 1;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FsCard(
                child: Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${checkpoints.length} checkpoints generated',
                              style: FsText.cardTitle),
                          Text(
                            t == null
                                ? 'Full NBC 2016 + BIS master'
                                : 'Scoped to ${t.label}',
                            style: FsText.tiny,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ...byCategory.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FsCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(e.key,
                                  style: FsText.small
                                      .copyWith(fontWeight: FontWeight.w600))),
                          Text('${e.value}',
                              style: FsText.small
                                  .copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        _nextBar(context, true, onNext, label: 'Start Audit'),
      ],
    );
  }
}

// ─── Phase 4 — Photo AI (CLIPSeg + Qwen vision) ────────────────────────────

class _PhotoAiResult {
  final List<DetectedEquipment> detected;
  final Map<String, dynamic> context;
  final List<String> dataUrls;
  final bool addAnother;
  const _PhotoAiResult(this.detected, this.context, this.dataUrls,
      {this.addAnother = false});
}

class _Phase4PhotoAi extends StatefulWidget {
  final FsGroqService svc;
  final FsClipsegService clip;
  final List<_ZoneEvidence> priorZones;
  final ValueChanged<_PhotoAiResult> onNext;
  const _Phase4PhotoAi({
    super.key,
    required this.svc,
    required this.clip,
    this.priorZones = const [],
    required this.onNext,
  });

  @override
  State<_Phase4PhotoAi> createState() => _Phase4PhotoAiState();
}

class _Phase4PhotoAiState extends State<_Phase4PhotoAi> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _level = TextEditingController();
  final TextEditingController _zone = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final List<String> _dataUrls = [];
  String _purpose = 'general_area';
  String _coverage = 'spot_check';
  bool _busy = false;
  bool _analysed = false;
  String _status = '';
  String? _error;
  List<DetectedEquipment> _detected = const [];

  Map<String, dynamic> get _context => {
        'level': _level.text.trim(),
        'zone': _zone.text.trim(),
        'purpose': _purpose,
        'coverage': _coverage,
        'notes': _notes.text.trim(),
        'imageCount': _dataUrls.length,
      };

  @override
  void dispose() {
    _level.dispose();
    _zone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_level.text.trim().isEmpty || _zone.text.trim().isEmpty) {
      setState(() => _error =
          'Complete the floor/level and exact zone before adding photos.');
      return;
    }
    try {
      final List<XFile> files;
      if (source == ImageSource.camera) {
        final f = await _picker.pickImage(source: source, imageQuality: 70);
        files = f == null ? [] : [f];
      } else {
        files = await _picker.pickMultiImage(imageQuality: 70);
      }
      final remaining = 5 - _dataUrls.length;
      if (files.length > remaining) {
        setState(() => _error =
            'This evidence batch has room for $remaining more photo(s). '
                'Create a separate batch for another floor or zone.');
        return;
      }
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final mime = f.mimeType ?? 'image/jpeg';
        _dataUrls.add('data:$mime;base64,${base64Encode(bytes)}');
      }
      setState(() {
        _error = null;
        _analysed = false;
      });
    } catch (e) {
      setState(() => _error = 'Could not read image: $e');
    }
  }

  Future<void> _analyse() async {
    if (_dataUrls.isEmpty) return;
    if (_level.text.trim().isEmpty || _zone.text.trim().isEmpty) {
      setState(() =>
          _error = 'Enter the floor/level and exact zone before analysis.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _detected = const [];
      _analysed = false;
    });

    final merged = <String, DetectedEquipment>{};
    void add(DetectedEquipment d) {
      final prev = merged[d.type];
      if (prev == null) {
        merged[d.type] = d;
      } else {
        merged[d.type] = DetectedEquipment(
          type: d.type,
          count: prev.count > d.count ? prev.count : d.count,
          source: prev.source == d.source ? d.source : 'merged',
          condition: d.condition.isNotEmpty ? d.condition : prev.condition,
          label: d.label.isNotEmpty ? d.label : prev.label,
          confidence:
              prev.confidence > d.confidence ? prev.confidence : d.confidence,
        );
      }
    }

    try {
      // Qwen is the baseline. Optional CLIPSeg runs concurrently and is
      // bounded, so model loading can never hold the audit spinner open.
      setState(() => _status =
          'Analysing evidence (vision model + optional on-device segmentation)…');
      final clipFuture = widget.clip.supported
          ? widget.clip
              .detectBatch(_dataUrls)
              .timeout(const Duration(seconds: 12), onTimeout: () => const [])
          : Future.value(const <DetectedEquipment>[]);
      final visionFuture = widget.svc.isConfigured
          ? widget.svc.visionDetect(_dataUrls, evidenceContext: _context)
          : Future.value(const <DetectedEquipment>[]);
      final batches = await Future.wait([visionFuture, clipFuture]);
      for (final batch in batches) {
        for (final d in batch) {
          add(d);
        }
      }
      if (!widget.svc.isConfigured && merged.isEmpty) {
        throw const FsServiceException(
            'Vision service not configured — set FIRESHIELD_WORKER_URL.');
      }
      setState(() {
        _detected = merged.values.toList();
        _analysed = true;
      });
    } catch (e) {
      setState(() => _error = e is FsServiceException ? e.message : '$e');
    } finally {
      setState(() {
        _busy = false;
        _status = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAnalyse = _dataUrls.isNotEmpty && !_busy;
    final hasResult = _analysed;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Capture up to 5 photos of fire equipment (extinguishers, '
                'sprinklers, detectors, exit signs…). CLIPSeg counts them '
                'on-device where supported; the vision model reads type and '
                'condition.',
                style: FsText.small,
              ),
              if (widget.priorZones.isNotEmpty) ...[
                const SizedBox(height: 12),
                FsCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZONES CAPTURED SO FAR (${widget.priorZones.length})',
                        style: FsText.xs.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      for (final z in widget.priorZones)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${z.label.isEmpty ? 'Unnamed zone' : z.label} — '
                            '${z.detected.length} equipment type'
                            '${z.detected.length == 1 ? '' : 's'} detected',
                            style: FsText.tiny,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _level,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Floor / level *',
                  hintText: 'Example: Basement B1 or Level 3',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _zone,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Exact zone / location *',
                  hintText: 'Example: east corridor outside Stair 2',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _purpose,
                decoration: const InputDecoration(labelText: 'Photo purpose'),
                items: const [
                  DropdownMenuItem(
                      value: 'general_area',
                      child: Text('General area survey')),
                  DropdownMenuItem(
                      value: 'equipment_closeup',
                      child: Text('Equipment close-up')),
                  DropdownMenuItem(
                      value: 'egress_route',
                      child: Text('Exit / egress route')),
                  DropdownMenuItem(
                      value: 'plant_room', child: Text('Pump / plant room')),
                  DropdownMenuItem(
                      value: 'kitchen', child: Text('Kitchen suppression')),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _purpose = v ?? _purpose),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _coverage,
                decoration:
                    const InputDecoration(labelText: 'Evidence coverage'),
                items: const [
                  DropdownMenuItem(
                      value: 'spot_check',
                      child: Text('Spot check — absence proves nothing')),
                  DropdownMenuItem(
                      value: 'complete_area',
                      child: Text('Complete coverage of this zone')),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _coverage = v ?? _coverage),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                enabled: !_busy,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Auditor notes (optional)',
                  hintText:
                      'Access restrictions or context for this evidence batch',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _dataUrls.length >= 5
                          ? null
                          : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _dataUrls.length >= 5
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (_dataUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _dataUrls.length; i++) _thumb(i),
                  ],
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_status, style: FsText.small)),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _banner(_error!),
              ],
              if (hasResult) ...[
                const SizedBox(height: 16),
                Text('OBSERVED EQUIPMENT',
                    style: FsText.xs.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                ..._detected.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FsCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_prettyType(d.type),
                                      style: FsText.small.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  if (d.condition.isNotEmpty ||
                                      d.label.isNotEmpty)
                                    Text(
                                      [
                                        if (d.label.isNotEmpty) d.label,
                                        if (d.condition.isNotEmpty) d.condition,
                                      ].join(' · '),
                                      style: FsText.tiny,
                                    ),
                                  Text('via ${d.source}', style: FsText.tiny),
                                ],
                              ),
                            ),
                            Text('×${d.count}',
                                style: FsText.cardTitle
                                    .copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    )),
                if (_detected.isEmpty)
                  Text(
                    'No supported fire-safety equipment was detected in this '
                    'evidence batch. Continue to compliance review; a spot check '
                    'does not prove that equipment is absent.',
                    style: FsText.small,
                  ),
              ],
            ],
          ),
        ),
        if (!hasResult)
          _nextBar(context, canAnalyse, _analyse, label: 'Run detection')
        else
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: FsColors.surface,
              border: Border(top: BorderSide(color: FsColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onNext(_PhotoAiResult(
                        _detected, _context, List.unmodifiable(_dataUrls),
                        addAnother: true)),
                    child: const Text('+ Add Another Zone'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => widget.onNext(_PhotoAiResult(
                          _detected, _context, List.unmodifiable(_dataUrls),
                          addAnother: false)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FsColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FsRadius.xl),
                        ),
                      ),
                      child: Text(
                        widget.priorZones.isEmpty
                            ? 'Finish & Continue'
                            : 'Finish (${widget.priorZones.length + 1} zones)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _thumb(int i) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(FsRadius.xl),
            child: Image.network(
              _dataUrls[i],
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: FsColors.gray100,
                child: const Icon(Icons.image, size: 20),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IconButton(
              iconSize: 16,
              onPressed: () => setState(() {
                _dataUrls.removeAt(i);
                _analysed = false;
              }),
              icon: const Icon(Icons.cancel, color: FsColors.danger),
            ),
          ),
        ],
      );
}

// ─── Phase 5 — Gap Analysis (expected systems vs observed) ─────────────────

class _Phase5GapAnalysis extends StatelessWidget {
  final List<_ZoneEvidence> zones;
  final List<DetectedEquipment> detected;
  final Map<String, dynamic> evidenceContext;
  final VoidCallback onNext;
  const _Phase5GapAnalysis({
    required this.zones,
    required this.detected,
    required this.evidenceContext,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final counts = {for (final d in detected) d.type: d.count};
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Observed evidence mapped to the fire-safety systems the '
                'reasoning model will assess against NBCS 2026. A system with '
                'no evidence is flagged for the model to verify as a gap. '
                'Extinguishers/sprinklers/detectors are graded per zone, so '
                'coverage in one area does not mask a gap in another.',
                style: FsText.small,
              ),
              const SizedBox(height: 8),
              Text(
                zones.length <= 1
                    ? '${evidenceContext['level'] ?? ''} · ${evidenceContext['zone'] ?? ''} · '
                        '${evidenceContext['coverage'] == 'complete_area' ? 'complete zone coverage' : 'spot check'}'
                    : '${zones.length} zones captured: '
                        '${zones.map((z) => z.label.isEmpty ? 'Unnamed' : z.label).join(', ')}',
                style: FsText.tiny,
              ),
              const SizedBox(height: 12),
              ..._kSystemEvidence.entries.map((e) {
                final total = e.value
                    .map((t) => counts[t] ?? 0)
                    .fold<int>(0, (a, b) => a + b);
                final present = total > 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FsCard(
                    child: Row(
                      children: [
                        Icon(
                          present ? Icons.check_circle : Icons.help_outline,
                          color: present ? FsColors.success : FsColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key, style: FsText.cardTitle),
                              Text(
                                present
                                    ? '$total detected in photos'
                                    : 'No evidence captured — model will verify',
                                style: FsText.tiny,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        _nextBar(context, true, onNext, label: 'Run compliance analysis'),
      ],
    );
  }
}

// ─── Phase 6 — Findings (gpt-oss reasoning over the NBC 2026 graph) ─────────

class _SiteRunResult {
  final FsAuditRun run;
  final int latencyMs;
  const _SiteRunResult(this.run, this.latencyMs);
}

class _Phase6Findings extends StatefulWidget {
  final FsGroqService svc;
  final Map<String, dynamic> profile;
  final BuildingType? building;
  final List<DetectedEquipment> detected;
  final Map<String, dynamic> evidenceContext;
  final List<_ZoneEvidence> zones;
  final ValueChanged<_SiteRunResult> onNext;
  const _Phase6Findings({
    required this.svc,
    required this.profile,
    required this.building,
    required this.detected,
    required this.evidenceContext,
    required this.zones,
    required this.onNext,
  });

  @override
  State<_Phase6Findings> createState() => _Phase6FindingsState();
}

class _Phase6FindingsState extends State<_Phase6Findings> {
  bool _busy = false;
  String? _error;
  FsAuditRun? _run;
  int? _latencyMs;
  final _nocService = FsNocSubmissionService();
  bool _alertBusy = false;

  @override
  void dispose() {
    _nocService.dispose();
    super.dispose();
  }

  Future<void> _notifyRegulator(ComplianceFinding f, {required bool verified}) async {
    setState(() => _alertBusy = true);
    try {
      if (verified) {
        await _nocService.alertRegulatorViaVerifiedGateway(
          system: f.system,
          clauseId: f.clauseId,
        );
      } else {
        await _nocService.alertRegulatorOfCriticalGap(
          system: f.system,
          clauseId: f.clauseId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regulator notified for ${f.system}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Notify failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _alertBusy = false);
    }
  }

  Future<void> _run0() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final started = DateTime.now();
      final run = await widget.svc.reasonCompliance(
        occupancyGroup: widget.profile['occupancyGroup'] as String? ?? '',
        buildingProfile: widget.profile,
        detected: widget.detected,
        evidenceContext: widget.evidenceContext,
        zones: widget.zones.length > 1
            ? widget.zones.map((z) => z.toReasonZone()).toList()
            : const [],
      );
      setState(() {
        _run = run;
        _latencyMs = DateTime.now().difference(started).inMilliseconds;
      });
    } catch (e) {
      setState(() => _error = e is FsServiceException ? e.message : '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    final crit = run?.findings
            .where(
                (f) => f.severity == 'critical' || f.status == 'critical_gap')
            .length ??
        0;
    final major = run?.findings.where((f) => f.severity == 'major').length ?? 0;
    final minor = run?.findings.where((f) => f.severity == 'minor').length ?? 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (run == null && !_busy && _error == null)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text('⚖️', style: TextStyle(fontSize: 42)),
                    const SizedBox(height: 12),
                    const Text('NBCS 2026 compliance analysis',
                        style: FsText.title),
                    const SizedBox(height: 6),
                    const Text(
                      'The reasoning model determines which systems are '
                      'mandatory for this building, queries NBCS 2026 Part F '
                      'live for each requirement, and compares against what the '
                      'photos show.',
                      textAlign: TextAlign.center,
                      style: FsText.small,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _run0,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FsColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text('Analyse compliance'),
                    ),
                  ],
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Querying NBCS 2026 and reasoning…',
                            style: FsText.small),
                      ],
                    ),
                  ),
                ),
              if (_error != null) _banner(_error!),
              if (run != null) ...[
                Row(
                  children: [
                    Expanded(
                        child: KpiCard(
                            icon: '🔴',
                            label: 'Critical',
                            value: '$crit',
                            color: FsColors.danger)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: KpiCard(
                            icon: '🟠',
                            label: 'Major',
                            value: '$major',
                            color: FsColors.warning)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: KpiCard(
                            icon: '🔵',
                            label: 'Minor',
                            value: '$minor',
                            color: FsColors.info)),
                  ],
                ),
                const SizedBox(height: 14),
                ...run.findings.map(_findingCard),
              ],
            ],
          ),
        ),
        _nextBar(
          context,
          run != null && _latencyMs != null,
          () => widget.onNext(_SiteRunResult(run!, _latencyMs!)),
        ),
      ],
    );
  }

  Widget _findingCard(ComplianceFinding f) {
    final color = switch (f.status) {
      'compliant' => FsColors.success,
      'critical_gap' => FsColors.danger,
      'gap' => FsColors.warning,
      _ => FsColors.subtle,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(f.system, style: FsText.cardTitle)),
                Text(f.status.replaceAll('_', ' '),
                    style: FsText.tiny
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
            if (f.rationale.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(f.rationale, style: FsText.tiny.copyWith(height: 1.4)),
            ],
            if (f.required.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Required: ${f.required}', style: FsText.tiny),
            ],
            if (f.observed.isNotEmpty)
              Text('Observed: ${f.observed}', style: FsText.tiny),
            if (f.clauseId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'NBCS 2026 ${f.clauseId}${f.page != null ? ' · p${f.page}' : ''}',
                  style: FsText.tiny.copyWith(
                      color: FsColors.info, fontWeight: FontWeight.w700),
                ),
              ),
            // Only a `critical_gap` finding ever reaches the regulator feed —
            // `gap` / `cannot_verify` / `compliant` findings never show these
            // buttons at all, so the call is never even constructed for them.
            if (f.status == 'critical_gap') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _alertBusy
                          ? null
                          : () => _notifyRegulator(f, verified: false),
                      child: const Text('Notify Regulator'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _alertBusy
                          ? null
                          : () => _notifyRegulator(f, verified: true),
                      child: const Text('Notify Regulator (Verified)'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Phase 7 — Compliance score ─────────────────────────────────────────────

class _Phase7Compliance extends StatefulWidget {
  final FsAuditRun? run;
  final String? storageStatus;
  final String? storageError;
  final VoidCallback onNext;
  const _Phase7Compliance({
    required this.run,
    required this.storageStatus,
    required this.storageError,
    required this.onNext,
  });

  @override
  State<_Phase7Compliance> createState() => _Phase7ComplianceState();
}

class _Phase7ComplianceState extends State<_Phase7Compliance> {
  double? _recalculated;

  /// Lets an auditor re-run the organisation's *current* scoring-policy text
  /// against this run's findings without restarting the whole audit —
  /// useful right after an Org Admin tweaks the formula.
  void _recalculate() {
    final run = widget.run;
    final formula = FsAppState.instance.customScoreFormula;
    if (run == null || formula == null) return;
    final value = evaluateCustomScoreFormula(run, formula);
    if (value != null) setState(() => _recalculated = value);
  }

  void _recalculateSafe() {
    final run = widget.run;
    final formula = FsAppState.instance.customScoreFormula;
    if (run == null || formula == null) return;
    final value = evaluateCustomScoreFormulaSafe(run, formula);
    if (value != null) setState(() => _recalculated = value);
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final score = _recalculated ?? (run?.score ?? 0).toDouble();
    final hasFormula = FsAppState.instance.customScoreFormula != null;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.storageStatus != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(widget.storageStatus!,
                        textAlign: TextAlign.center, style: FsText.small),
                  ),
                if (widget.storageError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(widget.storageError!,
                        textAlign: TextAlign.center,
                        style: FsText.small.copyWith(color: FsColors.danger)),
                  ),
                ScoreRing(score: score, size: 120),
                const SizedBox(height: 16),
                const Text('Compliance score', style: FsText.title),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    run?.occupancySummary.isNotEmpty == true
                        ? run!.occupancySummary
                        : 'Severity-weighted across the assessed NBCS 2026 systems.',
                    textAlign: TextAlign.center,
                    style: FsText.small,
                  ),
                ),
                if (hasFormula && run != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: _recalculate,
                        child: const Text('Recalculate (org formula)'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _recalculateSafe,
                        child: const Text('Recalculate (validated)'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        _nextBar(context, true, widget.onNext, label: 'View NOC Readiness'),
      ],
    );
  }
}

// ─── Phase 8 — NOC Readiness (driven by real score + open criticals) ───────

class _Phase8NocReadiness extends StatefulWidget {
  final FsAuditRun? run;
  final VoidCallback onRestart;
  const _Phase8NocReadiness({required this.run, required this.onRestart});

  @override
  State<_Phase8NocReadiness> createState() => _Phase8NocReadinessState();
}

class _Phase8NocReadinessState extends State<_Phase8NocReadiness> {
  final _nocService = FsNocSubmissionService();
  bool _submitBusy = false;
  String? _submitMessage;
  bool _qrBusy = false;
  String? _qrUrl;

  @override
  void dispose() {
    _nocService.dispose();
    super.dispose();
  }

  String get _facilityId {
    final facility = FsAppState.instance.user?.facility ?? '';
    return facility.isNotEmpty ? facility : 'unspecified-facility';
  }

  String get _buildingType =>
      widget.run?.buildingProfile['buildingType']?.toString() ?? 'Unspecified';

  Future<void> _submit({required bool verified}) async {
    final run = widget.run;
    if (run == null) return;
    setState(() {
      _submitBusy = true;
      _submitMessage = null;
    });
    final openCriticals = run.findings
        .where((f) => f.status == 'critical_gap' || f.severity == 'critical')
        .length;
    // A regulatory NOC submission must never trust an org's raw formula
    // text unvalidated, so this re-derives the score through the validated
    // twin rather than reusing whatever `run.score` already holds.
    final orgFormula = FsAppState.instance.customScoreFormula;
    final scoredRun = orgFormula == null
        ? run
        : run.applyCustomScoreFormulaSafe(orgFormula);
    try {
      if (verified) {
        await _nocService.submitViaVerifiedGateway(
          facilityId: _facilityId,
          buildingType: _buildingType,
          score: scoredRun.score,
          openCriticals: openCriticals,
        );
      } else {
        await _nocService.submitForNocApproval(
          facilityId: _facilityId,
          buildingType: _buildingType,
          score: scoredRun.score,
          openCriticals: openCriticals,
        );
      }
      if (mounted) {
        setState(() => _submitMessage = verified
            ? 'Submitted via the verified gateway.'
            : 'Submitted for NOC approval.');
      }
    } catch (e) {
      // Same shared-helper shape as _generateQr's own failure toast above,
      // but the submission failure never repeats the caught NOC-gateway/HTTP
      // exception text — only a fixed sentence reaches the toast.
      if (mounted) FsToast.showSafeError(context, e, action: 'Submission');
    } finally {
      if (mounted) setState(() => _submitBusy = false);
    }
  }

  Future<void> _generateQr({required bool verified}) async {
    final run = widget.run;
    if (run == null) return;
    setState(() => _qrBusy = true);
    try {
      final url = verified
          ? await _nocService.buildVerifiedCertificateUrl(
              _facilityId, run.score.round())
          : _nocService.buildLocalCertificateVerificationUrl(
              _facilityId, run.score.round());
      if (mounted) setState(() => _qrUrl = url);
    } catch (e) {
      // Routed through the shared FsToast helper (fs_ui.dart) — the same
      // utility fs_manager_dashboard.dart, fs_upload_documents_screen.dart
      // and fs_misc_screens.dart already use for their own toasts.
      if (mounted) FsToast.showError(context, e, action: 'QR generation');
    } finally {
      if (mounted) setState(() => _qrBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final score = (run?.score ?? 0).round();
    final openCriticals = run?.findings
            .where(
                (f) => f.status == 'critical_gap' || f.severity == 'critical')
            .length ??
        0;
    final ready = openCriticals == 0 && score >= 80;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ready ? FsColors.successLight : FsColors.warningLight,
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                  border: Border.all(
                      color: (ready ? FsColors.success : FsColors.warning)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(ready ? '✅' : '⏳',
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOC readiness: $score%',
                              style: FsText.cardTitle.copyWith(
                                  color: ready
                                      ? FsColors.success
                                      : FsColors.amber700)),
                          Text(
                            ready
                                ? 'No open critical gaps — ready to submit for NOC.'
                                : openCriticals > 0
                                    ? 'Close $openCriticals critical gap(s) first — NOC needs zero open criticals.'
                                    : 'Raise the compliance score to 80%+ for NOC submission.',
                            style: FsText.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => context.go('/reports'),
                  child: const Text('Generate audit report'),
                ),
              ),
              if (ready && run != null) ...[
                const SizedBox(height: 16),
                Text('SUBMIT FOR NOC APPROVAL',
                    style: FsText.xs.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed:
                        _submitBusy ? null : () => _submit(verified: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FsColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Submit for NOC Approval'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed:
                        _submitBusy ? null : () => _submit(verified: true),
                    child: const Text('Submit via Verified Gateway'),
                  ),
                ),
                if (_submitMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_submitMessage!, style: FsText.small),
                ],
                const SizedBox(height: 16),
                Text('AUDIT CERTIFICATE QR',
                    style: FsText.xs.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _qrBusy
                            ? null
                            : () => _generateQr(verified: false),
                        child: const Text('Preview Certificate QR'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _qrBusy
                            ? null
                            : () => _generateQr(verified: true),
                        child: const Text('Generate Verified QR'),
                      ),
                    ),
                  ],
                ),
                if (_qrUrl != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: QrImageView(
                      data: _qrUrl!,
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: FsColors.surface,
            border: Border(top: BorderSide(color: FsColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: widget.onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: FsColors.gray900,
                foregroundColor: FsColors.eyYellow,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
              ),
              child: const Text('Run another audit',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────

String _prettyType(String type) => switch (type) {
      'extinguisher' => 'Fire Extinguisher',
      'sprinkler' => 'Sprinkler Head',
      'detector' => 'Smoke / Heat Detector',
      'manual_call_point' => 'Manual Call Point',
      'alarm_panel' => 'Fire Alarm Panel',
      'exit_sign' => 'Exit Sign',
      'emergency_light' => 'Emergency Light',
      'fire_door' => 'Fire Door',
      'hydrant_hose_reel' => 'Hydrant / Hose Reel',
      'fire_pump' => 'Fire Pump',
      _ => type.replaceAll('_', ' '),
    };

Widget _banner(String message) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FsColors.dangerLight,
        borderRadius: BorderRadius.circular(FsRadius.xl),
        border: Border.all(color: FsColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: FsColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: FsText.small)),
        ],
      ),
    );

Widget _nextBar(
  BuildContext context,
  bool canNext,
  VoidCallback onNext, {
  String label = 'Continue',
}) =>
    Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: FsColors.surface,
        border: Border(top: BorderSide(color: FsColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: canNext ? onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: FsColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: FsColors.primary.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FsRadius.xl),
            ),
          ),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
