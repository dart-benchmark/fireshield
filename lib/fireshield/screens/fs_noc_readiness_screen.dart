/// Port of pwa_app/src/screens/manager/NOCReadiness.jsx
///
/// The PWA computes a weighted readiness score from four components: last
/// audit score (40%), document completeness (20%), open critical CAPAs
/// (25%), AMC validity (15%). Ported with the same weights and data.
library;

import 'package:flutter/material.dart';

import '../data/fs_mock_data.dart';
import '../services/fs_noc_submission_service.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class _Doc {
  final String name;
  final bool required;
  final String status;
  final String expiry;
  const _Doc(this.name, this.required, this.status, this.expiry);
}

const _kDocs = [
  _Doc('Fire NOC', true, 'VALID', '15 Mar 2027'),
  _Doc('Occupancy Certificate', true, 'VALID', '01 Jan 2030'),
  _Doc('Approved Fire Plan', true, 'VALID', '30 Jun 2026'),
  _Doc('Electrical Safety Certificate', true, 'EXPIRED', '31 Dec 2023'),
  _Doc('Emergency Response Plan', true, 'VALID', '31 Dec 2025'),
  _Doc('Fire Drill Record', true, 'VALID', '—'),
  _Doc('AMC Certificate — Fire Detection', false, 'VALID', '30 Sep 2024'),
  _Doc('AMC Certificate — Hydrant / Sprinkler', false, 'MISSING', '—'),
];

class _Amc {
  final String system;
  final String vendor;
  final bool valid;
  final String expiry;
  const _Amc(this.system, this.vendor, this.valid, this.expiry);
}

const _kAmc = [
  _Amc('Fire Detection & Alarm', 'Securitas India Pvt Ltd', true, '31 Dec 2026'),
  _Amc('Fire Fighting (Hydrant)', 'Globe Fire Sprinklers', false, '30 Sep 2025'),
  _Amc('Sprinkler System', 'Globe Fire Sprinklers', false, '30 Sep 2025'),
  _Amc('Emergency Lighting', 'Havells India Ltd', true, '31 Aug 2026'),
  _Amc('Fire Extinguishers', 'Agni Fire Services', true, '30 Nov 2026'),
];

class FsNocReadinessScreen extends StatefulWidget {
  const FsNocReadinessScreen({super.key});

  @override
  State<FsNocReadinessScreen> createState() => _FsNocReadinessScreenState();
}

class _FsNocReadinessScreenState extends State<FsNocReadinessScreen> {
  static const _tabs = ['Overview', 'Documents', 'CAPAs', 'AMC'];
  int _tab = 0;
  final _nocService = FsNocSubmissionService();
  final Set<String> _notifying = {};

  /// Vendor CRM integration token supplied by an org admin at runtime — kept
  /// in memory for this session only. Never bundled with the app; the
  /// verified renewal path refuses to run until this is set.
  String? _vendorToken;

  @override
  void dispose() {
    _nocService.dispose();
    super.dispose();
  }

  Future<void> _notifyVendor(_Amc a, {required bool verified}) async {
    setState(() => _notifying.add(a.system));
    try {
      if (verified) {
        final token = _vendorToken;
        if (token == null || token.trim().isEmpty) {
          final entered = await _promptForVendorToken(context);
          if (entered == null || entered.trim().isEmpty) return;
          _vendorToken = entered;
        }
        await _nocService.notifyVendorForRenewalWithToken(
          system: a.system,
          vendor: a.vendor,
          adminSuppliedToken: _vendorToken!,
        );
      } else {
        await _nocService.notifyVendorForRenewal(
          system: a.system,
          vendor: a.vendor,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Renewal request sent to ${a.vendor}.')),
        );
      }
    } catch (e) {
      // Same shape as fs_govt_dashboard.dart's own escalation failure handler
      // (verified vs. direct branch, one shared catch) — but this path never
      // repeats the vendor CRM's own exception text to the org admin; the raw
      // value only ever reaches the console.
      debugPrint(
          'Renewal request failed: $e'); // SAFE_SINK: PLANTED-Dart-HR-481-safe
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Renewal request failed. Please try again or contact support.')));
      }
    } finally {
      if (mounted) setState(() => _notifying.remove(a.system));
    }
  }

  Future<String?> _promptForVendorToken(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Vendor Integration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Vendor CRM API token',
            hintText: 'Not stored — used for this session only',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save for this session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const auditScore = 74.0;
    final docValid =
        _kDocs.where((d) => d.required && d.status == 'VALID').length;
    final docTotal = _kDocs.where((d) => d.required).length;
    final docCompleteness = (docValid / docTotal) * 100;
    final criticalCapas =
        correctiveActions.where((c) => c.severity == 'CRITICAL' && c.isOpen).length;
    final amcAllCurrent = _kAmc.every((a) => a.valid);

    // Same weighting as calculateNOCReadiness in the PWA: 40/20/25/15.
    const auditComponent = (auditScore / 100) * 40;
    final docComponent = (docCompleteness / 100) * 20;
    final capaComponent = criticalCapas == 0
        ? 25.0
        : (25 - criticalCapas * 8).clamp(0, 25).toDouble();
    final amcComponent = amcAllCurrent ? 15.0 : 5.0;
    final readiness =
        auditComponent + docComponent + capaComponent + amcComponent;

    return Column(
      children: [
        Container(
          color: FsColors.surface,
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: List.generate(
              _tabs.length,
              (i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == _tab ? FsColors.primary : FsColors.gray100,
                      borderRadius: BorderRadius.circular(FsRadius.full),
                    ),
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: i == _tab ? Colors.white : FsColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: switch (_tab) {
              1 => _documents(),
              2 => _capas(criticalCapas),
              3 => _amc(),
              _ => _overview(readiness, auditComponent, docComponent,
                  capaComponent, amcComponent, docCompleteness, criticalCapas),
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _overview(
    double readiness,
    double auditC,
    double docC,
    double capaC,
    double amcC,
    double docCompleteness,
    int criticalCapas,
  ) =>
      [
        FsCard(
          child: Column(
            children: [
              ScoreRing(score: readiness, size: 96),
              const SizedBox(height: 10),
              Text(
                readiness >= 80
                    ? 'NOC Ready'
                    : readiness >= 60
                        ? 'Action Needed'
                        : 'Not Ready',
                style: FsText.title,
              ),
              const SizedBox(height: 2),
              const Text('Composite readiness across audit, documents, CAPAs and AMC',
                  textAlign: TextAlign.center, style: FsText.tiny),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('SCORE COMPONENTS',
            style: FsText.xs
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _component('Last Audit Score', 40, auditC, const Color(0xFF2563EB)),
        _component('Document Completeness', 20, docC, const Color(0xFF7C3AED)),
        _component('Open Critical CAPAs', 25, capaC,
            criticalCapas == 0 ? FsColors.success : FsColors.danger),
        _component('AMC Validity', 15, amcC,
            amcC >= 15 ? FsColors.success : FsColors.warning),
      ];

  Widget _component(String label, int weight, double contribution, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: FsText.cardTitle)),
                  Text('${contribution.toStringAsFixed(1)} / $weight',
                      style: FsText.small.copyWith(
                          fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              const SizedBox(height: 8),
              ProgressBar(
                value: (contribution / weight) * 100,
                color: color,
              ),
            ],
          ),
        ),
      );

  List<Widget> _documents() => [
        Text('${_kDocs.where((d) => d.status == 'VALID').length} of ${_kDocs.length} valid',
            style: FsText.small),
        const SizedBox(height: 10),
        ..._kDocs.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(d.name,
                                      style: FsText.cardTitle,
                                      overflow: TextOverflow.ellipsis)),
                              if (d.required)
                                Text('required',
                                    style: FsText.micro
                                        .copyWith(color: FsColors.subtle)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Expires ${d.expiry}', style: FsText.tiny),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: d.status == 'EXPIRED' ? 'Expired' : d.status == 'MISSING' ? 'OPEN' : 'Valid'),
                  ],
                ),
              ),
            )),
      ];

  List<Widget> _capas(int critical) => [
        Text('$critical critical CAPA(s) blocking NOC readiness',
            style: FsText.small.copyWith(
                color: critical > 0 ? FsColors.danger : FsColors.success)),
        const SizedBox(height: 10),
        ...correctiveActions.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(status: c.severity),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(c.title,
                                style: FsText.cardTitle,
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Due ${c.due}', style: FsText.tiny),
                  ],
                ),
              ),
            )),
      ];

  List<Widget> _amc() => [
        Text('${_kAmc.where((a) => a.valid).length} of ${_kAmc.length} contracts current',
            style: FsText.small),
        const SizedBox(height: 10),
        ..._kAmc.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.system, style: FsText.cardTitle),
                              Text(a.vendor, style: FsText.tiny),
                              Text('Expires ${a.expiry}', style: FsText.micro),
                            ],
                          ),
                        ),
                        StatusBadge(status: a.valid ? 'Valid' : 'Expired'),
                      ],
                    ),
                    if (!a.valid) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _notifying.contains(a.system)
                                  ? null
                                  : () => _notifyVendor(a, verified: false),
                              child: const Text('Notify Vendor for Renewal'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _notifying.contains(a.system)
                                  ? null
                                  : () => _notifyVendor(a, verified: true),
                              child: const Text('Notify (Configured Integration)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ];
}
