/// Port of pwa_app/src/screens/facility/AddFacilityScreen.jsx — a 5-step
/// facility registration (Building Info, Location, Technical, Contact,
/// Review), with the real building types, occupancy classes, states and
/// NOC statuses from the PWA.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/fs_recent_contacts_cache.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_wizard.dart';

const _kBuildingTypes = [
  'Shopping Mall', 'Office Complex', 'Hospital / Healthcare',
  'Hotel / Hospitality', 'Residential Complex', 'Industrial / Warehouse',
  'Educational Institution', 'Mixed Use Development',
  'Government / Civic', 'Other',
];

const _kOccupancyClasses = [
  'F-1 · Mercantile (Shops < 500 sqm)',
  'F-2 · Mercantile (Shops ≥ 500 sqm)',
  'A-1 · Residential (Tenements)',
  'A-2 · Dormitories',
  'B-1 · Educational (Schools)',
  'B-2 · Educational (Colleges)',
  'C · Institutional (Hospitals)',
  'D · Assembly (< 1000 persons)',
  'E · Business / Office',
  'G-1 · Industrial (Low Hazard)',
  'G-2 · Industrial (Moderate Hazard)',
  'H · Storage (Low Hazard)',
  'J · Hazardous',
];

const _kStates = [
  'Karnataka', 'Maharashtra', 'Delhi', 'Tamil Nadu', 'Gujarat', 'Telangana',
  'Uttar Pradesh', 'West Bengal', 'Rajasthan', 'Haryana',
];

const _kNocStatuses = [
  'Valid — Existing',
  'Applied — Pending',
  'Expired — Renewal Required',
  'Not Applied',
];

class FsAddFacilityScreen extends StatefulWidget {
  const FsAddFacilityScreen({super.key});

  @override
  State<FsAddFacilityScreen> createState() => _FsAddFacilityScreenState();
}

class _FsAddFacilityScreenState extends State<FsAddFacilityScreen> {
  static const _steps = ['Building', 'Location', 'Technical', 'Contact', 'Review'];
  int _step = 0;
  final _form = <String, String>{};
  bool _submitted = false;

  bool get _canNext => switch (_step) {
        0 => (_form['name'] ?? '').isNotEmpty &&
            (_form['type'] ?? '').isNotEmpty,
        1 => (_form['address'] ?? '').isNotEmpty &&
            (_form['city'] ?? '').isNotEmpty &&
            (_form['state'] ?? '').isNotEmpty,
        2 => (_form['area'] ?? '').isNotEmpty &&
            (_form['floors'] ?? '').isNotEmpty &&
            (_form['occupancyClass'] ?? '').isNotEmpty,
        3 => (_form['contactName'] ?? '').isNotEmpty &&
            (_form['contactPhone'] ?? '').isNotEmpty,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FsSuccessSheet(
            title: '${_form['name'] ?? 'Facility'} added',
            subtitle: 'The facility is now live on your dashboard.',
            details: [
              ('Type', _form['type'] ?? '—'),
              ('City', _form['city'] ?? '—'),
              ('NOC status', _form['nocStatus'] ?? '—'),
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
              0 => _building(),
              1 => _location(),
              2 => _technical(),
              3 => _contact(),
              _ => _review(),
            },
          ),
        ),
        FsWizardBar(
          showBack: _step > 0,
          canNext: _canNext,
          nextLabel: _step == _steps.length - 1 ? 'Submit' : 'Next',
          onBack: () => setState(() => _step--),
          onNext: () {
            if (_step == _steps.length - 1) {
              final contactPhone = _form['contactPhone'] ?? '';
              if (contactPhone.isNotEmpty) {
                FsRecentContactsCache.remember(
                  facilityName: _form['name'] ?? '',
                  name: _form['contactName'] ?? '',
                  phone: contactPhone,
                  email: _form['contactEmail'] ?? '',
                );
              }
              FsRecentContactsCache.rememberFacilityOnly(
                facilityName: _form['name'] ?? '',
              );
              setState(() => _submitted = true);
            } else {
              setState(() => _step++);
            }
          },
        ),
      ],
    );
  }

  List<Widget> _building() => [
        FsField(
          label: 'Facility Name',
          required: true,
          child: TextField(
            decoration: fsInputDecoration('e.g. Phoenix Marketcity Chennai'),
            onChanged: (v) => _form['name'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Building Type',
          required: true,
          child: FsDropdown(
            value: _form['type'],
            hint: 'Select type',
            options: _kBuildingTypes,
            onChanged: (v) => setState(() => _form['type'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Description',
          child: TextField(
            maxLines: 3,
            decoration: fsInputDecoration('Short description of the facility'),
            onChanged: (v) => _form['description'] = v,
          ),
        ),
      ];

  List<Widget> _location() => [
        FsField(
          label: 'Address',
          required: true,
          child: TextField(
            maxLines: 2,
            decoration: fsInputDecoration('Street address'),
            onChanged: (v) => _form['address'] = v,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FsField(
                label: 'City',
                required: true,
                child: TextField(
                  decoration: fsInputDecoration('City'),
                  onChanged: (v) => _form['city'] = v,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FsField(
                label: 'PIN Code',
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('560001'),
                  onChanged: (v) => _form['pin'] = v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'State',
          required: true,
          child: FsDropdown(
            value: _form['state'],
            hint: 'Select state',
            options: _kStates,
            onChanged: (v) => setState(() => _form['state'] = v ?? ''),
          ),
        ),
      ];

  List<Widget> _technical() => [
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
                label: 'Max Occupancy',
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: fsInputDecoration('e.g. 8000'),
                  onChanged: (v) => _form['occupancy'] = v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Occupancy Class',
          required: true,
          child: FsDropdown(
            value: _form['occupancyClass'],
            hint: 'Select occupancy class',
            options: _kOccupancyClasses,
            onChanged: (v) =>
                setState(() => _form['occupancyClass'] = v ?? ''),
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'NOC Status',
          required: true,
          child: FsDropdown(
            value: _form['nocStatus'],
            hint: 'Select NOC status',
            options: _kNocStatuses,
            onChanged: (v) => setState(() => _form['nocStatus'] = v ?? ''),
          ),
        ),
      ];

  List<Widget> _contact() => [
        FsField(
          label: 'Contact Name',
          required: true,
          child: TextField(
            decoration: fsInputDecoration('Facility contact person'),
            onChanged: (v) => _form['contactName'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Contact Phone',
          required: true,
          child: TextField(
            keyboardType: TextInputType.phone,
            decoration: fsInputDecoration('+91 XXXXX XXXXX'),
            onChanged: (v) => _form['contactPhone'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Contact Email',
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: fsInputDecoration('contact@facility.com'),
            onChanged: (v) => _form['contactEmail'] = v,
          ),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Notes',
          child: TextField(
            maxLines: 3,
            decoration: fsInputDecoration('Anything else worth noting'),
            onChanged: (v) => _form['notes'] = v,
          ),
        ),
      ];

  List<Widget> _review() => [
        FsField(label: 'Facility', child: Text(_form['name'] ?? '—', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(label: 'Type', child: Text(_form['type'] ?? '—', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(
          label: 'Location',
          child: Text('${_form['city'] ?? '—'}, ${_form['state'] ?? '—'}',
              style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(
          label: 'Area / Floors',
          child: Text(
              '${_form['area'] ?? '—'} sqm · ${_form['floors'] ?? '—'} floors',
              style: FsText.body),
        ),
        const SizedBox(height: 14),
        FsField(label: 'NOC Status', child: Text(_form['nocStatus'] ?? '—', style: FsText.body)),
        const SizedBox(height: 14),
        FsField(label: 'Contact', child: Text(_form['contactName'] ?? '—', style: FsText.body)),
      ];
}
