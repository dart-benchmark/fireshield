/// Port of pwa_app/src/screens/manager/TrainingDrills.jsx
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class _Drill {
  final String id, date, type, evacTime, assembly, attendance, conductedBy;
  final List<String> issues;
  const _Drill(this.id, this.date, this.type, this.evacTime, this.assembly,
      this.attendance, this.conductedBy, this.issues);
}

const _kDrills = [
  _Drill('DR-001', '15 Jan 2026', 'Full Evacuation Drill', '4m 22s',
      'Assembly Point A — South Parking', '287/312 (92%)', 'Rajesh Kumar', [
    'Staircase S3 door was obstructed on F2 during drill',
    'Assembly point A was partially blocked by delivery vehicles',
  ]),
  _Drill('DR-002', '10 Jul 2025', 'Partial Evacuation — Floors F1–F3',
      '2m 58s', 'Assembly Point B — North Exit', '179/185 (97%)',
      'Rajesh Kumar', ['None identified']),
];

class _Training {
  final String id, date, topic, trainer, dept;
  final int trainees;
  final bool certIssued;
  const _Training(this.id, this.date, this.topic, this.trainer, this.trainees,
      this.dept, this.certIssued);
}

const _kTraining = [
  _Training('TR-001', '20 Jan 2026', 'Fire Extinguisher Operation',
      'Agni Fire Services', 45, 'Retail Operations', true),
  _Training('TR-002', '22 Jan 2026', 'Fire Warden Certification — Level 1',
      'SafetyFirst Institute', 28, 'All Departments', true),
  _Training('TR-003', '05 Oct 2025', 'Emergency Response Plan Briefing',
      'In-House', 312, 'All Staff', false),
  _Training('TR-004', '15 Jul 2025', 'Kitchen Fire Safety', 'Agni Fire Services',
      22, 'Food Court Vendors', true),
];

class _Warden {
  final String name, floor, dept, phone;
  final bool trained;
  const _Warden(this.name, this.floor, this.dept, this.trained, this.phone);
}

const _kWardens = [
  _Warden('Anita Sharma', 'GF Atrium', 'Retail Ops', true, '98801 23456'),
  _Warden('Mohammed Irfan', 'F1 Retail', 'Retail Ops', true, '98802 34567'),
  _Warden('Preethi Rao', 'F2 Food Court', 'F&B Ops', true, '98803 45678'),
  _Warden('Sunil Verma', 'F3 Cinema', 'Entertainment', false, '98804 56789'),
  _Warden('Kavitha Nair', 'B1 Parking', 'Parking Ops', true, '98805 67890'),
  _Warden('Ramesh Gupta', 'B2 Parking', 'Parking Ops', false, '98806 78901'),
];

const _kScheduled = [
  ('15 Jul 2026', 'Full Evacuation Drill', 'All floors', true),
  ('01 Apr 2026', 'Fire Pump Test Drill', 'Plant room + pump house', true),
  ('15 Mar 2026', 'Tabletop Exercise', 'Fire wardens only', false),
];

class FsTrainingDrillsScreen extends StatefulWidget {
  const FsTrainingDrillsScreen({super.key});

  @override
  State<FsTrainingDrillsScreen> createState() =>
      _FsTrainingDrillsScreenState();
}

class _FsTrainingDrillsScreenState extends State<FsTrainingDrillsScreen> {
  static const _tabs = ['Drills', 'Training', 'Wardens', 'Schedule'];
  int _tab = 0;
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final trained = _kWardens.where((w) => w.trained).length;

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
              1 => _training(),
              2 => _wardens(trained),
              3 => _schedule(),
              _ => _drills(),
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _drills() => List.generate(_kDrills.length, (i) {
        final d = _kDrills[i];
        final open = _expanded == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FsCard(
            onTap: () => setState(() => _expanded = open ? null : i),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(d.type, style: FsText.cardTitle)),
                    const StatusBadge(status: 'CLOSED'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${d.date} · Evacuation ${d.evacTime}', style: FsText.tiny),
                const SizedBox(height: 4),
                Text('Attendance ${d.attendance} · ${d.assembly}',
                    style: FsText.tiny),
                if (open) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: FsColors.border),
                  const SizedBox(height: 10),
                  Text('Conducted by ${d.conductedBy}', style: FsText.small),
                  const SizedBox(height: 6),
                  Text('Issues noted',
                      style:
                          FsText.small.copyWith(fontWeight: FontWeight.w700)),
                  ...d.issues.map((iss) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• $iss', style: FsText.tiny),
                      )),
                ],
              ],
            ),
          ),
        );
      });

  List<Widget> _training() => _kTraining
      .map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FsCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.topic, style: FsText.cardTitle),
                        const SizedBox(height: 2),
                        Text('${t.trainer} · ${t.dept}', style: FsText.tiny),
                        Text('${t.date} · ${t.trainees} trainees',
                            style: FsText.micro),
                      ],
                    ),
                  ),
                  StatusBadge(status: t.certIssued ? 'APPROVED' : 'OPEN'),
                ],
              ),
            ),
          ))
      .toList();

  List<Widget> _wardens(int trained) => [
        Row(
          children: [
            Expanded(
              child: KpiCard(
                  icon: '✅',
                  label: 'Trained',
                  value: '$trained',
                  color: FsColors.success),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KpiCard(
                  icon: '⚠️',
                  label: 'Not Trained',
                  value: '${_kWardens.length - trained}',
                  color: FsColors.danger),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._kWardens.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (w.trained ? FsColors.success : FsColors.danger)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child: Text(
                        w.name.split(' ').map((n) => n[0]).take(2).join(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: w.trained
                                ? FsColors.success
                                : FsColors.danger),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: FsText.cardTitle),
                          Text('${w.floor} · ${w.dept}', style: FsText.tiny),
                        ],
                      ),
                    ),
                    StatusBadge(status: w.trained ? 'Valid' : 'Expired'),
                  ],
                ),
              ),
            )),
      ];

  List<Widget> _schedule() => _kScheduled
      .map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FsCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2, style: FsText.cardTitle),
                        Text('${s.$1} · ${s.$3}', style: FsText.tiny),
                      ],
                    ),
                  ),
                  if (s.$4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: FsColors.red100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Mandatory',
                          style: FsText.micro.copyWith(color: FsColors.red700)),
                    ),
                ],
              ),
            ),
          ))
      .toList();
}
