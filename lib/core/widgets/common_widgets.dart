import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Stat Card ────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(subtitle!, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTextStyles.numeric.copyWith(fontSize: 26, color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.h6),
      const Divider(height: 16),
      child,
    ]),
  );
}

// ─── Section Header ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h5),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _resolveStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  (Color, Color, String) _resolveStatus(String s) => switch (s) {
    'OPERATIONAL' => (AppColors.success, AppColors.successLight, 'Operational'),
    'MAINTENANCE_DUE' => (AppColors.warning, AppColors.warningLight, 'Service Due'),
    'DEFECTIVE' => (AppColors.error, AppColors.errorLight, 'Defective'),
    'DECOMMISSIONED' => (AppColors.textSecondary, AppColors.borderLight, 'Decommissioned'),
    'IN_PROGRESS' => (AppColors.info, AppColors.infoLight, 'In Progress'),
    'SCHEDULED' => (AppColors.secondary, AppColors.secondaryLight, 'Scheduled'),
    'SUBMITTED' => (AppColors.warning, AppColors.warningLight, 'Submitted'),
    'APPROVED' => (AppColors.success, AppColors.successLight, 'Approved'),
    'COMPLETED' => (AppColors.success, AppColors.successLight, 'Completed'),
    'CANCELLED' => (AppColors.textSecondary, AppColors.borderLight, 'Cancelled'),
    'OPEN' => (AppColors.warning, AppColors.warningLight, 'Open'),
    'OVERDUE' => (AppColors.error, AppColors.errorLight, 'Overdue'),
    'ESCALATED' => (AppColors.error, AppColors.errorLight, 'Escalated'),
    'CLOSED' => (AppColors.success, AppColors.successLight, 'Closed'),
    'PENDING_REVIEW' => (AppColors.info, AppColors.infoLight, 'Pending Review'),
    'Valid' => (AppColors.success, AppColors.successLight, 'Valid'),
    'Expired' => (AppColors.error, AppColors.errorLight, 'Expired'),
    'Expiring Soon' => (AppColors.warning, AppColors.warningLight, 'Expiring Soon'),
    _ => (AppColors.textSecondary, AppColors.borderLight, s),
  };
}

// ─── Severity Badge ───────────────────────────────────────────
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (severity) {
      'CRITICAL' => (AppColors.riskCritical, AppColors.errorLight),
      'MAJOR' => (AppColors.warning, AppColors.warningLight),
      'MINOR' => (AppColors.info, AppColors.infoLight),
      _ => (AppColors.textSecondary, AppColors.borderLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(severity, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

// ─── Score Ring ───────────────────────────────────────────────
class ScoreRing extends StatelessWidget {
  final double score, size;
  final String label;
  final double strokeWidth;
  const ScoreRing({super.key, required this.score, required this.label, this.size = 100, this.strokeWidth = 10});

  Color get _color => score >= 85 ? AppColors.success : score >= 70 ? AppColors.info : score >= 55 ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: strokeWidth,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${score.toStringAsFixed(0)}%', style: AppTextStyles.h5.copyWith(color: _color, fontSize: size * 0.2)),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: size * 0.1), textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Risk Tag ─────────────────────────────────────────────────
class RiskTag extends StatelessWidget {
  final String level;
  const RiskTag({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (level) {
      'CRITICAL' => (AppColors.riskCritical, AppColors.errorLight),
      'HIGH' => (AppColors.riskHigh, AppColors.errorLight),
      'MEDIUM' => (AppColors.riskMedium, AppColors.warningLight),
      'LOW' => (AppColors.riskLow, AppColors.successLight),
      _ => (AppColors.textSecondary, AppColors.borderLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(level, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Loading Shimmer ──────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double width, height, borderRadius;
  const ShimmerBox({super.key, this.width = double.infinity, this.height = 16, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButton;
  const EmptyState({super.key, required this.title, required this.subtitle, required this.icon, this.buttonLabel, this.onButton});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.h5, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onButton, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool isLast;
  const InfoRow({super.key, required this.label, required this.value, this.valueColor, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 140, child: Text(label, style: AppTextStyles.label)),
              Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

// ─── App Bar with Avatar ──────────────────────────────────────
PreferredSizeWidget buildAppBar(BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
  bool showBack = false,
}) {
  return AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h5),
        if (subtitle != null) Text(subtitle, style: AppTextStyles.caption),
      ],
    ),
    leading: showBack ? IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.of(context).pop()) : null,
    actions: actions,
    bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
  );
}

// ─── Progress Bar ─────────────────────────────────────────────
class LabeledProgressBar extends StatelessWidget {
  final String label, value;
  final double progress;
  final Color color;
  const LabeledProgressBar({super.key, required this.label, required this.value, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            Text(value, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
