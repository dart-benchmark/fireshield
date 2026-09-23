import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/engine/audit_session.dart';
import '../../core/engine/risk_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/occupancy_taxonomy.dart';

/// Weighted risk score for the audit in progress.
///
/// Shows compliance, residual risk after the occupancy hazard factor, the
/// per-section breakdown and whether the building clears the NOC bar.
class RiskDashboardScreen extends StatefulWidget {
  const RiskDashboardScreen({super.key});

  @override
  State<RiskDashboardScreen> createState() => _RiskDashboardScreenState();
}

class _RiskDashboardScreenState extends State<RiskDashboardScreen> {
  final _session = AuditSession.instance;

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
    final a = _session.assessment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Risk Score'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: a == null
          ? EmptyState(
              title: 'No audit to score',
              subtitle: 'Start an audit and answer a few checkpoints first.',
              icon: Icons.speed_outlined,
              buttonLabel: 'Choose building type',
              onButton: () => context.push('/building-classification'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildHeadline(a),
                const SizedBox(height: 16),
                _buildFailureBreakdown(a),
                const SizedBox(height: 16),
                _buildNocCard(a),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Section breakdown'),
                const SizedBox(height: 8),
                ...a.sections.map(_buildSectionRow),
              ],
            ),
      bottomSheet: a == null ? null : _buildCapaBar(a),
    );
  }

  Widget _buildHeadline(RiskAssessment a) {
    final color = _riskColor(a.level);
    final sub = OccupancyTaxonomy.subdivision(a.buildingType.subdivision);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(
                score: a.complianceScore,
                label: 'Compliance',
                size: 108,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Residual risk', style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text(
                      a.riskScore.toStringAsFixed(0),
                      style: AppTextStyles.numeric.copyWith(color: color),
                    ),
                    const SizedBox(height: 6),
                    RiskTag(level: _riskTagLabel(a.level)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          InfoRow(
            label: 'Facility',
            value: _session.facilityName,
          ),
          InfoRow(
            label: 'Occupancy',
            value: sub == null
                ? a.buildingType.subdivision
                : '${sub.code} · ${sub.name}',
          ),
          InfoRow(
            label: 'Hazard factor',
            value: '×${a.hazardFactor.toStringAsFixed(1)}',
          ),
          InfoRow(
            label: 'Answered',
            value:
                '${_session.answeredCount} of ${_session.checkpoints.length}',
            isLast: true,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              a.level.action,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureBreakdown(RiskAssessment a) => Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Critical',
              value: '${a.criticalFailures}',
              icon: Icons.dangerous_outlined,
              color: AppColors.riskCritical,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Major',
              value: '${a.majorFailures}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Minor',
              value: '${a.minorFailures}',
              icon: Icons.info_outline,
              color: AppColors.info,
            ),
          ),
        ],
      );

  Widget _buildNocCard(RiskAssessment a) {
    final ok = a.nocRecommended;
    final color = ok ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.verified_outlined : Icons.gpp_bad_outlined,
              color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'NOC criteria met' : 'NOC not recommended',
                  style: AppTextStyles.h6.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(a.nocReason, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow(SectionScore s) {
    final score = s.score;
    final color = score == null
        ? AppColors.textSecondary
        : score >= 85
            ? AppColors.success
            : score >= 70
                ? AppColors.info
                : score >= 50
                    ? AppColors.warning
                    : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: s.criticalFailures > 0
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.category, style: AppTextStyles.h6)),
              Text(
                // An unscored section is not a zero — say so.
                score == null ? 'Not scored' : '${score.toStringAsFixed(0)}%',
                style: AppTextStyles.h6.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score ?? 0) / 100,
              minHeight: 5,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tiny('${s.passed} pass', AppColors.success),
              _tiny('${s.failed} fail', AppColors.error),
              if (s.notApplicable > 0)
                _tiny('${s.notApplicable} N/A', AppColors.textSecondary),
              if (!s.isComplete)
                _tiny('${s.total - s.answered - s.notApplicable} open',
                    AppColors.warning),
              if (s.criticalFailures > 0)
                _tiny('${s.criticalFailures} critical',
                    AppColors.riskCritical),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tiny(String text, Color color) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(text, style: AppTextStyles.caption),
          ],
        ),
      );

  Widget _buildCapaBar(RiskAssessment a) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: a.totalFailures == 0
                ? null
                : () {
                    _session.generateCapa();
                    context.push('/capa-tracker');
                  },
            icon: const Icon(Icons.build_outlined, size: 20),
            label: Text(a.totalFailures == 0
                ? 'No findings to action'
                : 'Raise ${a.totalFailures} CAPA action(s)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );

  static Color _riskColor(RiskLevel l) => switch (l) {
        RiskLevel.low => AppColors.riskLow,
        RiskLevel.moderate => AppColors.riskMedium,
        RiskLevel.high => AppColors.riskHigh,
        RiskLevel.critical => AppColors.riskCritical,
      };

  /// RiskTag uses MEDIUM where the engine says moderate.
  static String _riskTagLabel(RiskLevel l) =>
      l == RiskLevel.moderate ? 'MEDIUM' : l.label.toUpperCase();
}
