/// Port of pwa_app/src/screens/admin/RegisterOrg.jsx
///
/// The PWA's 7 steps are Org Details, Building Classification, Building
/// Information, Fire Systems, NOC Details, Documents, Review. This keeps all
/// seven and the real option lists (occupancy groups, NBC categories, states,
/// NOC authorities, fire systems, required documents) but condenses the
/// visual flourish of each step into one consistent form layout.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/fs_tokens.dart';
import '../widgets/fs_wizard.dart';

const _kOccupancyGroups = [
  'Group A — Residential',
  'Group B — Educational',
  'Group C — Institutional / Healthcare',
  'Group D — Assembly / Auditorium',
  'Group E — Business / Office',
  'Group F — Mercantile / Retail / Mall',
  'Group G — Industrial / Factory',
  'Group H — Storage / Warehouse',
  'Group J — Hazardous',
];

const _kNbcCategories = [
  'Category A (Height > 15m and ≤ 45m)',
  'Category B (Height > 45m)',
  'Category C (Basement area > 200 sqm)',
  'Category D (Hazardous occupancy)',
  'Category E (Assembly > 300 persons)',
  'Standard (Height ≤ 15m, non-hazardous)',
];

const _kOwnership = [
  'Owned (Freehold)',
  'Leased',
  'Government Allotted',
  'Joint Venture',
  'PPP / BOOT',
  'Leave & License',
];

const _kFireSystems = [
  ('sprinkler', 'Automatic Sprinkler System (IS 15105)', true),
  ('hydrant', 'Wet Riser / Hydrant System (IS 3844)', true),
  ('detection', 'Fire Detection & Alarm System (IS 2189)', true),
  ('extinguisher', 'Portable Fire Extinguishers (IS 2190)', true),
  ('pa_system', 'Public Address / Voice Evacuation System', false),
  ('smoke_mgmt', 'Smoke Management / Pressurisation System', false),
  ('gas_suppression', 'Gas Suppression System (IS 15493)', false),
  ('fire_door', 'Fire Rated Doors / Rolling Shutters', true),
  ('fire_lift', "Fireman's Lift", false),
];

const _kNocAuthorities = [
  'MP Fire Services (ePalika)',
  'Maharashtra Fire Services (MBFS)',
  'Karnataka State Fire & Emergency Services (KSFES)',
  'Delhi Fire Services (DFS)',
  'Tamil Nadu Fire & Rescue Services (TNFR)',
  'Gujarat Fire Prevention & Life Safety Measures (GFS)',
  'Other State Fire Department',
];

const _kDocuments = [
  ('Approved Fire Fighting Plan', true),
  ('Architectural / Building Drawings', true),
  ('Floor Plans (All floors)', true),
  ('Occupancy Certificate', true),
  ('Electrical Safety Certificate', true),
  ('Emergency Response Plan (ERP)', true),
  ('Evacuation Plan', true),
  ('Land / Ownership Document', true),
  ('Approved Layout Plan', true),
  ('Existing Fire NOC (if any)', false),
  ('CAD File (.dwg / .dxf)', false),
  ('Building Insurance Policy', false),
];

const _kStates = [
  'Karnataka', 'Maharashtra', 'Delhi', 'Tamil Nadu', 'Gujarat', 'Telangana',
  'Uttar Pradesh', 'West Bengal', 'Rajasthan', 'Haryana',
];

class FsRegisterOrgScreen extends StatefulWidget {
  const FsRegisterOrgScreen({super.key});

  @override
  State<FsRegisterOrgScreen> createState() => _FsRegisterOrgScreenState();
}

class _FsRegisterOrgScreenState extends State<FsRegisterOrgScreen> {
  static const _steps = [
    'Org Details',
    'Classification',
    'Building Info',
    'Fire Systems',
    'NOC Details',
    'Documents',
    'Review',
  ];

  int _step = 0;
  final _form = <String, String>{};
  final Set<String> _systems = {};
  final Set<String> _docs = {};
  bool _saving = false;
  bool _done = false;

  bool get _canNext => switch (_step) {
        0 => (_form['name'] ?? '').isNotEmpty &&
            (_form['gst'] ?? '').isNotEmpty,
        1 => (_form['occupancy'] ?? '').isNotEmpty,
        2 => (_form['area'] ?? '').isNotEmpty &&
            (_form['floors'] ?? '').isNotEmpty,
        4 => (_form['nocAuthority'] ?? '').isNotEmpty,
        _ => true,
      };

  Future<void> _submit() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildDone();

    return Column(
      children: [
        FsStepBar(steps: _steps, current: _step),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: switch (_step) {
              0 => _orgDetails(),
              1 => _classification(),
              2 => _buildingInfo(),
              3 => _fireSystems(),
              4 => _nocDetails(),
              5 => _documents(),
              _ => _review(),
            },
          ),
        ),
        FsWizardBar(
          showBack: _step > 0,
          canNext: _canNext && !_saving,
          nextLabel: _step == _steps.length - 1
              ? (_saving ? 'Submitting…' : 'Submit Registration')
              : 'Next',
          onBack: () => setState(() => _step--),
          onNext: () {
            if (_step == _steps.length - 1) {
              _submit();
            } else {
              setState(() => _step++);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDone() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FsSuccessSheet(
            title: '${_form['name'] ?? 'Organisation'} registered',
            subtitle: 'Submitted for platform review.',
            details: [
              ('GST', _form['gst'] ?? '—'),
              ('Occupancy', _form['occupancy'] ?? '—'),
              ('NOC Authority', _form['nocAuthority'] ?? '—'),
              ('Fire systems selected', '${_systems.length}'),
              ('Documents attached', '${_docs.length}'),
            ],
            onClose: () => context.go('/admin/orgs'),
          ),
        ),
      );

  List<Widget> _orgDetails() => [
        FsField(
          label: 'Organisation Name',
          required: true,
          child: TextField(
            decoration: fsInputDecoration('e.g. Phoenix Group'),
            onChanged: (v) => _form['name'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Industry',
          child: TextField(
            decoration: fsInputDecoration('e.g. Retail & Commercial'),
            onChanged: (v) => _form['industry'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'GSTIN',
          required: true,
          child: TextField(
            decoration: fsInputDecoration('29AABCP1234Q1ZX'),
            onChanged: (v) => _form['gst'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Corporate Email',
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: fsInputDecoration('safety@organisation.com'),
            onChanged: (v) => _form['email'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'State',
          child: FsDropdown(
            value: _form['state'],
            hint: 'Select state',
            options: _kStates,
            onChanged: (v) => setState(() => _form['state'] = v ?? ''),
          ),
        ),
      ];

  List<Widget> _classification() => [
        FsField(
          label: 'Occupancy Group (NBC 2016 Cl. 3.1)',
          required: true,
          child: FsDropdown(
            value: _form['occupancy'],
            hint: 'Select occupancy group',
            options: _kOccupancyGroups,
            onChanged: (v) => setState(() => _form['occupancy'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'NBC Category',
          child: FsDropdown(
            value: _form['nbcCategory'],
            hint: 'Select category',
            options: _kNbcCategories,
            onChanged: (v) =>
                setState(() => _form['nbcCategory'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Ownership Type',
          child: FsDropdown(
            value: _form['ownership'],
            hint: 'Select ownership',
            options: _kOwnership,
            onChanged: (v) =>
                setState(() => _form['ownership'] = v ?? ''),
          ),
        ),
      ];

  List<Widget> _buildingInfo() => [
        Row(
          children: [
            Expanded(
              child: FsField(
                label: 'Built-up Area (sqm)',
                required: true,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('e.g. 185000'),
                  onChanged: (v) => _form['area'] = v,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FsField(
                label: 'Floors',
                required: true,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('e.g. 5'),
                  onChanged: (v) => _form['floors'] = v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FsField(
                label: 'Basements',
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('e.g. 2'),
                  onChanged: (v) => _form['basements'] = v,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FsField(
                label: 'Height (m)',
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('e.g. 24'),
                  onChanged: (v) => _form['height'] = v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Maximum Occupancy',
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: fsInputDecoration('e.g. 8000'),
            onChanged: (v) => _form['occupants'] = v,
          ),
        ),
      ];

  List<Widget> _fireSystems() => [
        const Text(
          'Select the systems installed at this facility. Required systems'
          ' are marked for the selected occupancy.',
          style: FsText.small,
        ),
        const SizedBox(height: 12),
        ..._kFireSystems.map((s) {
          final selected = _systems.contains(s.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                selected ? _systems.remove(s.$1) : _systems.add(s.$1);
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFFBEB) : Colors.white,
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                  border: Border.all(
                    color: selected ? FsColors.eyYellow : FsColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: selected ? FsColors.eyDark : FsColors.subtle,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.$2,
                          style: FsText.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: FsColors.gray900)),
                    ),
                    if (s.$3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FsColors.red100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Required',
                            style: FsText.micro
                                .copyWith(color: FsColors.red700)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ];

  List<Widget> _nocDetails() => [
        FsField(
          label: 'NOC Authority',
          required: true,
          child: FsDropdown(
            value: _form['nocAuthority'],
            hint: 'Select authority',
            options: _kNocAuthorities,
            onChanged: (v) =>
                setState(() => _form['nocAuthority'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Existing NOC Number (if any)',
          child: TextField(
            decoration: fsInputDecoration('e.g. NOC/2024/00123'),
            onChanged: (v) => _form['nocNumber'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Last Inspection Date',
          child: TextField(
            decoration: fsInputDecoration('DD/MM/YYYY'),
            onChanged: (v) => _form['inspectionDate'] = v,
          ),
        ),
      ];

  List<Widget> _documents() => [
        Text('${_docs.length} of ${_kDocuments.length} attached',
            style: FsText.small),
        const SizedBox(height: 10),
        ..._kDocuments.map((d) {
          final attached = _docs.contains(d.$1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                attached ? _docs.remove(d.$1) : _docs.add(d.$1);
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                  border: Border.all(color: FsColors.border),
                ),
                child: Row(
                  children: [
                    Text(attached ? '📎' : '⬜',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(d.$1,
                          style: FsText.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: FsColors.gray900)),
                    ),
                    if (d.$2 && !attached)
                      Text('required',
                          style: FsText.micro
                              .copyWith(color: FsColors.red600)),
                    if (attached)
                      Text('attached',
                          style: FsText.micro
                              .copyWith(color: FsColors.green700)),
                  ],
                ),
              ),
            ),
          );
        }),
      ];

  List<Widget> _review() => [
        FsField(
          label: 'Organisation',
          child: Text(_form['name'] ?? '—', style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Occupancy',
          child: Text(_form['occupancy'] ?? '—', style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Built-up Area / Floors',
          child: Text(
              '${_form['area'] ?? '—'} sqm · ${_form['floors'] ?? '—'} floors',
              style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Fire Systems',
          child: Text('${_systems.length} selected', style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'NOC Authority',
          child: Text(_form['nocAuthority'] ?? '—', style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Documents',
          child: Text('${_docs.length} attached', style: FsText.body),
        ),
      ];
}
