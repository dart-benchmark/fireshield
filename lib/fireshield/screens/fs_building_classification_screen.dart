/// Port of pwa_app/src/screens/admin/BuildingClassification.jsx
///
/// The PWA re-derives its own occupancy taxonomy inline. This screen points
/// at the real one instead — [OccupancyTaxonomy] in the NBC/BIS audit
/// module, built from "NBC_BIS Fire safety masterdata .xlsx" — so admins
/// classify against the same 9 groups / 35 subdivisions / 85 building types
/// the audit checklist actually uses, rather than a second, disconnected
/// classification.
library;

import 'package:flutter/material.dart';

import '../../data/occupancy_taxonomy.dart';
import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';
import '../widgets/fs_wizard.dart';

class FsBuildingClassificationScreen extends StatefulWidget {
  const FsBuildingClassificationScreen({super.key});

  @override
  State<FsBuildingClassificationScreen> createState() =>
      _FsBuildingClassificationScreenState();
}

class _FsBuildingClassificationScreenState
    extends State<FsBuildingClassificationScreen> {
  static const _steps = ['Occupancy Group', 'Building Type', 'Profile'];
  int _step = 0;
  String? _group;
  BuildingType? _type;
  final _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FsStepBar(steps: _steps, current: _step),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                switch (_step) {
                  0 => _groupStep(),
                  1 => _typeStep(),
                  _ => _profileStep(),
                },
              ],
            ),
          ),
          if (_step < 2)
            FsWizardBar(
              showBack: _step > 0,
              canNext: _step == 0 ? _group != null : _type != null,
              onBack: () => setState(() => _step--),
              onNext: () {
                // Reaching the profile step confirms the classification —
                // persist it so the AI Audit Engine starts pre-scoped.
                if (_step == 1 && _type != null) {
                  FsAppState.instance.setClassifiedBuilding(_type);
                }
                setState(() => _step++);
              },
            ),
        ],
      );

  Widget _groupStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NBC 2016 Part 4, Cl. 3.1', style: FsText.small),
          const SizedBox(height: 12),
          ...occupancyGroups.map((g) {
            final selected = _group == g.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _group = g.code;
                  _type = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFFBEB) : Colors.white,
                    borderRadius: BorderRadius.circular(FsRadius.xl2),
                    border: Border.all(
                        color: selected ? FsColors.eyYellow : FsColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: FsColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(FsRadius.xl),
                        ),
                        child: Text(g.code,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: FsColors.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Group ${g.code} — ${g.name}',
                                style: FsText.cardTitle),
                            Text(g.description, style: FsText.tiny),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _typeStep() {
    final types = OccupancyTaxonomy.typesOfGroup(_group!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${types.length} building types in this group',
            style: FsText.small),
        const SizedBox(height: 12),
        ...types.map((t) {
          final sub = OccupancyTaxonomy.subdivision(t.subdivision);
          final selected = _type?.key == t.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFFBEB) : Colors.white,
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                  border: Border.all(
                      color: selected ? FsColors.eyYellow : FsColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.label, style: FsText.cardTitle),
                          Text(
                            '${t.subdivision} · ${sub?.name ?? ''}',
                            style: FsText.tiny,
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: FsColors.eyDark, size: 18),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _profileStep() {
    final type = _type!;
    final sub = OccupancyTaxonomy.subdivision(type.subdivision)!;
    final group = OccupancyTaxonomy.group(sub.groupCode)!;
    final authorities = OccupancyTaxonomy.authoritiesFor(type);
    final h = double.tryParse(_heightCtrl.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.label, style: FsText.title),
              const SizedBox(height: 4),
              Text('${sub.code} · ${sub.name}', style: FsText.small),
              const SizedBox(height: 4),
              Text(sub.description, style: FsText.tiny),
              const SizedBox(height: 12),
              Row(
                children: [
                  _pill('Group ${group.code}', FsColors.info),
                  const SizedBox(width: 8),
                  _pill('Hazard ×${sub.hazardFactor.toStringAsFixed(1)}',
                      sub.hazardFactor >= 2
                          ? FsColors.danger
                          : sub.hazardFactor >= 1.5
                              ? FsColors.warning
                              : FsColors.success),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('REGULATORY AUTHORITIES',
            style: FsText.xs
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
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
        const SizedBox(height: 14),
        FsField(
          label: 'Building height (m) — for height-triggered checks',
          child: TextField(
            controller: _heightCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: fsInputDecoration('e.g. 24'),
          ),
        ),
        const SizedBox(height: 12),
        if (h >= 15)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FsColors.warningLight,
              borderRadius: BorderRadius.circular(FsRadius.xl2),
            ),
            child: Text(
              h >= 45
                  ? 'Height ≥ 45m: fire lift, refuge area and pressurised staircase are mandatory (NBC 2016 Cl. 4.7–4.9).'
                  : 'Height ≥ 15m: sprinkler system and PA/voice evacuation become mandatory (NBC 2016 Cl. 4.6).',
              style: FsText.small.copyWith(color: FsColors.amber700),
            ),
          ),
      ],
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}
