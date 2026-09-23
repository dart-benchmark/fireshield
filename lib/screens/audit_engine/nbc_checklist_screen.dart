import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/audit_session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/checkpoint_model.dart';

/// Checklist entry against NBC 2016 Part 4 and the BIS standards.
///
/// One tab per category. Each checkpoint takes Yes / No / N/A plus optional
/// remarks. N/A is a real answer here — it drops out of scoring rather than
/// counting as a pass.
class NbcChecklistScreen extends StatefulWidget {
  const NbcChecklistScreen({super.key});

  @override
  State<NbcChecklistScreen> createState() => _NbcChecklistScreenState();
}

class _NbcChecklistScreenState extends State<NbcChecklistScreen> {
  final _session = AuditSession.instance;
  int _categoryIndex = 0;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.isStarted) return _buildNoAudit();

    final categories = _session.categories;
    final category = categories[_categoryIndex.clamp(0, categories.length - 1)];
    final checkpoints = _session.checkpointsIn(category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audit Checklist', style: AppTextStyles.h5),
            Text(_session.facilityName, style: AppTextStyles.caption),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/risk-dashboard'),
            child: const Text('Score'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgress(),
          _buildCategoryTabs(categories),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: checkpoints.length,
              itemBuilder: (_, i) => _buildCheckpointCard(checkpoints[i]),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(categories),
    );
  }

  Widget _buildNoAudit() => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Audit Checklist'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: EmptyState(
          title: 'No audit started',
          subtitle:
              'Pick a building type first — it decides which checkpoints apply.',
          icon: Icons.assignment_outlined,
          buttonLabel: 'Choose building type',
          onButton: () => context.push('/building-classification'),
        ),
      );

  Widget _buildProgress() {
    final done = _session.answeredCount;
    final total = _session.checkpoints.length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$done of $total answered', style: AppTextStyles.label),
              Text('${(_session.progress * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.label
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _session.progress,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<String> categories) => Container(
        color: AppColors.surface,
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final active = i == _categoryIndex;
            final cps = _session.checkpointsIn(categories[i]);
            final answered = cps
                .where((c) =>
                    _session.responseFor(c.id) != Response.unanswered)
                .length;
            final complete = answered == cps.length;

            return GestureDetector(
              onTap: () => setState(() => _categoryIndex = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    if (complete)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(Icons.check_circle,
                            size: 14,
                            color: active
                                ? Colors.white
                                : AppColors.success),
                      ),
                    Text(
                      '${categories[i]}  $answered/${cps.length}',
                      style: AppTextStyles.label.copyWith(
                        color:
                            active ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _buildCheckpointCard(Checkpoint c) {
    final response = _session.responseFor(c.id);
    final open = _expanded.contains(c.id);
    final answer = _session.answers[c.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: response == Response.no
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.id,
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    SeverityBadge(severity: c.severity.label.toUpperCase()),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        open ? _expanded.remove(c.id) : _expanded.add(c.id);
                      }),
                      child: Icon(
                        open ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.title, style: AppTextStyles.h6),
                const SizedBox(height: 4),
                Text(c.subCategory, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 10),
                  Text(c.description, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Evidence: ${c.evidence}',
                            style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(c.standardLabel,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.secondary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: answer?.remarks ?? '',
                    onChanged: (v) => _session.setRemarks(c.id, v),
                    maxLines: 2,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Observation / remarks',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                _responseButton(c, Response.yes, 'Yes', AppColors.success),
                const SizedBox(width: 8),
                _responseButton(c, Response.no, 'No', AppColors.error),
                const SizedBox(width: 8),
                _responseButton(
                    c, Response.notApplicable, 'N/A', AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _responseButton(
      Checkpoint c, Response value, String label, Color color) {
    final active = _session.responseFor(c.id) == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _session.answer(c.id, active ? Response.unanswered : value),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : AppColors.inputFill,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<String> categories) {
    final isLast = _categoryIndex >= categories.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_categoryIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _categoryIndex--),
                child: const Text('Back'),
              ),
            ),
          if (_categoryIndex > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  context.push('/risk-dashboard');
                } else {
                  setState(() => _categoryIndex++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isLast ? 'View risk score' : 'Next section'),
            ),
          ),
        ],
      ),
    );
  }
}
