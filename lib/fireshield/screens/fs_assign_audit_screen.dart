/// Port of pwa_app/src/screens/manager/AssignAudit.jsx
///
/// Facility + audit type → auditor selection (single or multiple, with
/// per-auditor floor assignment) → review & confirm.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_mock_data.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_wizard.dart';

const _kAuditors = [
  ('A1', 'Priya Nair', 'EY-FSA-2021-047', 'Certified Fire Safety Auditor L2', 'B.E. Fire Engineering, NEBOSH IGC', 3, true, ''),
  ('A2', 'Vikram Singh', 'EY-FSA-2019-023', 'Certified Fire Safety Auditor L3', 'B.Tech Safety, OISD Certified', 1, false, 'Annual Leave till 22 Jun'),
  ('A3', 'Divya Menon', 'EY-FSA-2022-061', 'Certified Fire Safety Auditor L2', 'M.Sc. Safety Management, NEBOSH', 5, true, ''),
  ('A4', 'Kavitha Rajan', 'EY-FSA-2020-038', 'Fire Safety Auditor L1', 'Diploma Safety Engineering', 7, true, ''),
  ('A5', 'Sanjay Mehta', 'EY-FSA-2023-078', 'NBC 2016 Trained Auditor', 'B.E. Civil, NBC 2016 Certified', 2, true, ''),
];

const _kAuditTypes = [
  'Annual Fire Safety Audit', 'Pre-Inspection Audit (NOC Renewal)',
  'Self Audit', 'Follow-up Audit', 'Post-Incident Audit', 'Surprise Audit',
  'NABH Compliance Audit', 'OISD Compliance Audit', 'PESO Compliance Audit',
];

const _kPriorities = ['NORMAL', 'HIGH', 'URGENT'];

const _kFloors = [
  'Basement 2 (Car Park)', 'Basement 1 (Car Park)', 'Ground Floor (Retail)',
  'First Floor (Food Court)', 'Second Floor (Multiplex)', 'Third Floor / Terrace',
];

class FsAssignAuditScreen extends StatefulWidget {
  const FsAssignAuditScreen({super.key});

  @override
  State<FsAssignAuditScreen> createState() => _FsAssignAuditScreenState();
}

class _FsAssignAuditScreenState extends State<FsAssignAuditScreen> {
  static const _steps = ['Facility & Type', 'Assign Auditors', 'Floors', 'Review'];
  int _step = 0;
  final _form = <String, String>{'priority': 'NORMAL'};
  String _mode = 'single';
  final Set<String> _selectedAuditors = {};
  final Map<String, Set<String>> _floorAssignments = {};
  bool _saving = false;
  bool _done = false;

  bool get _canNext => switch (_step) {
        0 => (_form['facility'] ?? '').isNotEmpty &&
            (_form['type'] ?? '').isNotEmpty,
        1 => _selectedAuditors.isNotEmpty,
        _ => true,
      };

  void _toggleAuditor(String id) {
    setState(() {
      if (_mode == 'single') {
        _selectedAuditors
          ..clear()
          ..add(id);
      } else {
        _selectedAuditors.contains(id)
            ? _selectedAuditors.remove(id)
            : _selectedAuditors.add(id);
      }
    });
  }

  void _toggleFloor(String auditorId, String floor) {
    setState(() {
      final set = _floorAssignments.putIfAbsent(auditorId, () => {});
      set.contains(floor) ? set.remove(floor) : set.add(floor);
    });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FsSuccessSheet(
            title: 'Audit assigned',
            subtitle: '${_form['type']} at ${_form['facility']}',
            details: [
              ('Auditors', '${_selectedAuditors.length}'),
              ('Priority', _form['priority'] ?? 'NORMAL'),
              ('Start date', _form['startDate']?.isNotEmpty == true
                  ? _form['startDate']!
                  : 'Not set'),
            ],
            onClose: () => context.pop(),
          ),
        ),
      );
    }

    return Column(
      children: [
        FsStepBar(steps: _steps, current: _step),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: switch (_step) {
              0 => _facilityAndType(),
              1 => _auditors(),
              2 => _floors(),
              _ => _review(),
            },
          ),
        ),
        FsWizardBar(
          showBack: _step > 0,
          canNext: _canNext && !_saving,
          nextLabel: _step == _steps.length - 1
              ? (_saving ? 'Assigning…' : 'Confirm Assignment')
              : 'Next',
          onBack: () => setState(() => _step--),
          onNext: () {
            if (_step == _steps.length - 1) {
              _confirm();
            } else {
              setState(() => _step++);
            }
          },
        ),
      ],
    );
  }

  List<Widget> _facilityAndType() => [
        FsField(
          label: 'Facility',
          required: true,
          child: FsDropdown(
            value: _form['facility'],
            hint: 'Select facility',
            options: mockFacilities.map((f) => f.name).toList(),
            onChanged: (v) => setState(() => _form['facility'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Audit Type',
          required: true,
          child: FsDropdown(
            value: _form['type'],
            hint: 'Select audit type',
            options: _kAuditTypes,
            onChanged: (v) => setState(() => _form['type'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FsField(
                label: 'Start Date',
                child: TextField(
                  decoration: fsInputDecoration('DD/MM/YYYY'),
                  onChanged: (v) => _form['startDate'] = v,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FsField(
                label: 'Deadline',
                child: TextField(
                  decoration: fsInputDecoration('DD/MM/YYYY'),
                  onChanged: (v) => _form['deadline'] = v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Priority',
          child: Row(
            children: _kPriorities
                .map((p) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _form['priority'] = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _form['priority'] == p
                                ? FsColors.primary
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(FsRadius.xl),
                            border: Border.all(
                              color: _form['priority'] == p
                                  ? FsColors.primary
                                  : FsColors.border,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _form['priority'] == p
                                  ? Colors.white
                                  : FsColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ];

  List<Widget> _auditors() => [
        Row(
          children: [
            Expanded(
              child: _modeButton('single', 'Single auditor'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _modeButton('multiple', 'Multiple auditors'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._kAuditors.map((a) {
          final selected = _selectedAuditors.contains(a.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: a.$7 ? () => _toggleAuditor(a.$1) : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !a.$7
                      ? FsColors.gray100
                      : selected
                          ? const Color(0xFFFFFBEB)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                  border: Border.all(
                    color: selected ? FsColors.eyYellow : FsColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.$2, style: FsText.cardTitle),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: FsColors.infoLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${a.$6} audits',
                              style: FsText.micro
                                  .copyWith(color: FsColors.info)),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle,
                              color: FsColors.eyDark, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${a.$3} · ${a.$4}', style: FsText.tiny),
                    Text(a.$5, style: FsText.micro),
                    if (!a.$7) ...[
                      const SizedBox(height: 4),
                      Text('Unavailable — ${a.$8}',
                          style:
                              FsText.tiny.copyWith(color: FsColors.danger)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ];

  Widget _modeButton(String mode, String label) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        if (mode == 'single' && _selectedAuditors.length > 1) {
          final first = _selectedAuditors.first;
          _selectedAuditors
            ..clear()
            ..add(first);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? FsColors.gray900 : Colors.white,
          borderRadius: BorderRadius.circular(FsRadius.xl),
          border: Border.all(color: active ? FsColors.gray900 : FsColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? FsColors.eyYellow : FsColors.muted,
          ),
        ),
      ),
    );
  }

  List<Widget> _floors() => [
        const Text(
          'Assign floors to each selected auditor. Unassigned floors default'
          ' to the first auditor.',
          style: FsText.small,
        ),
        const SizedBox(height: 14),
        ..._selectedAuditors.map((id) {
          final auditor = _kAuditors.firstWhere((a) => a.$1 == id);
          final assigned = _floorAssignments[id] ?? {};
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auditor.$2, style: FsText.cardTitle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kFloors.map((f) {
                    final selected = assigned.contains(f);
                    return GestureDetector(
                      onTap: () => _toggleFloor(id, f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? FsColors.primary
                              : FsColors.gray100,
                          borderRadius:
                              BorderRadius.circular(FsRadius.full),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : FsColors.muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ];

  List<Widget> _review() => [
        FsField(
            label: 'Facility',
            child: Text(_form['facility'] ?? '—', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(
            label: 'Audit Type',
            child: Text(_form['type'] ?? '—', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(
          label: 'Auditors',
          child: Text(
            _selectedAuditors
                .map((id) => _kAuditors.firstWhere((a) => a.$1 == id).$2)
                .join(', '),
            style: FsText.body,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
            label: 'Priority',
            child: Text(_form['priority'] ?? 'NORMAL', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(
          label: 'Deadline',
          child: Text(
              _form['deadline']?.isNotEmpty == true
                  ? _form['deadline']!
                  : 'Not set',
              style: FsText.body),
        ),
      ];
}
