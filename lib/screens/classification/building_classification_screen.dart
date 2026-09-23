import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/audit_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/nbc_bis_masterdata.dart';
import '../../data/occupancy_taxonomy.dart';

/// Pick the building type an audit runs against. The choice drives which
/// checkpoints apply, which authorities have jurisdiction, and the hazard
/// factor used in risk scoring.
class BuildingClassificationScreen extends StatefulWidget {
  const BuildingClassificationScreen({super.key});

  @override
  State<BuildingClassificationScreen> createState() =>
      _BuildingClassificationScreenState();
}

class _BuildingClassificationScreenState
    extends State<BuildingClassificationScreen> {
  final _searchCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  String _query = '';
  String? _groupFilter;
  BuildingType? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _facilityCtrl.dispose();
    super.dispose();
  }

  List<BuildingType> get _results {
    var list = OccupancyTaxonomy.search(_query);
    final g = _groupFilter;
    if (g != null) {
      final subs =
          OccupancyTaxonomy.subdivisionsOf(g).map((s) => s.code).toSet();
      list = list.where((b) => subs.contains(b.subdivision)).toList();
    }
    return list;
  }

  void _startAudit() {
    final t = _selected;
    if (t == null) return;
    AuditSession.instance.start(
      type: t,
      facilityName: _facilityCtrl.text.trim().isEmpty
          ? t.label
          : _facilityCtrl.text.trim(),
    );
    context.push('/nbc-checklist');
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Building Classification'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildGroupChips(),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    title: 'No building type matches',
                    subtitle:
                        'Try a different term, or clear the group filter above.',
                    icon: Icons.search_off,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: results.length,
                    itemBuilder: (_, i) => _buildTypeCard(results[i]),
                  ),
          ),
        ],
      ),
      bottomSheet: _selected == null ? null : _buildConfirmBar(),
    );
  }

  Widget _buildSearchBar() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search 85 building types, e.g. hospital, refinery',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Widget _buildGroupChips() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.only(bottom: 12),
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip('All', _groupFilter == null,
                () => setState(() => _groupFilter = null)),
            ...occupancyGroups.map((g) => _chip(
                  '${g.code} · ${g.name}',
                  _groupFilter == g.code,
                  () => setState(() => _groupFilter = g.code),
                )),
          ],
        ),
      );

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );

  Widget _buildTypeCard(BuildingType type) {
    final sub = OccupancyTaxonomy.subdivision(type.subdivision);
    final grp = sub == null ? null : OccupancyTaxonomy.group(sub.groupCode);
    final selected = _selected?.key == type.key;
    final hazard = OccupancyTaxonomy.hazardFactor(type);

    return GestureDetector(
      onTap: () => setState(() => _selected = selected ? null : type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hazardColor(hazard).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type.subdivision,
                    style: AppTextStyles.label.copyWith(
                      color: _hazardColor(hazard),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label, style: AppTextStyles.h6),
                      const SizedBox(height: 2),
                      Text(
                        grp == null
                            ? type.subdivision
                            : 'Group ${grp.code} · ${grp.name}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 22),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 12),
              if (sub != null) ...[
                Text(sub.name, style: AppTextStyles.h6),
                const SizedBox(height: 4),
                Text(sub.description, style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _pill('Hazard ×${hazard.toStringAsFixed(1)}',
                      _hazardColor(hazard)),
                  const SizedBox(width: 8),
                  _pill(
                    '${OccupancyTaxonomy.checkpointsFor(type, allCheckpoints).length} checkpoints',
                    AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Regulatory authorities', style: AppTextStyles.label),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: OccupancyTaxonomy.authoritiesFor(type)
                    .map((a) => _pill(a, AppColors.info))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static Color _hazardColor(double h) {
    if (h >= 2.0) return AppColors.riskCritical;
    if (h >= 1.5) return AppColors.riskHigh;
    if (h >= 1.2) return AppColors.riskMedium;
    return AppColors.riskLow;
  }

  Widget _buildConfirmBar() => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _facilityCtrl,
              decoration: InputDecoration(
                labelText: 'Facility name (optional)',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _startAudit,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text('Start audit — ${_selected!.label}',
                    overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
