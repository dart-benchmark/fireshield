/// Shared mobile-first UI components — Flutter port of
/// pwa_app/src/components/ui.jsx. Same names, same props, same visuals.
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';

// ─── StatusBadge ───────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static const Map<String, (Color, Color, String)> _map = {
    'IN_PROGRESS': (FsColors.blue100, FsColors.blue700, 'In Progress'),
    'SCHEDULED': (FsColors.purple100, FsColors.purple700, 'Scheduled'),
    'SUBMITTED': (FsColors.amber100, FsColors.amber700, 'Submitted'),
    'APPROVED': (FsColors.green100, FsColors.green700, 'Approved'),
    'OVERDUE': (FsColors.red100, FsColors.red700, 'Overdue'),
    'OPEN': (FsColors.orange100, FsColors.orange700, 'Open'),
    'CLOSED': (FsColors.green100, FsColors.green700, 'Closed'),
    'Valid': (FsColors.green100, FsColors.green700, 'NOC Valid'),
    'Expiring': (FsColors.amber100, FsColors.amber700, 'Expiring Soon'),
    'Expired': (FsColors.red100, FsColors.red700, 'NOC Expired'),
    'HIGH': (FsColors.red100, FsColors.red700, 'High Risk'),
    'MEDIUM': (FsColors.amber100, FsColors.amber700, 'Medium Risk'),
    'CRITICAL': (FsColors.red100, FsColors.red700, 'Critical'),
    'MAJOR': (FsColors.orange100, FsColors.orange700, 'Major'),
    'MINOR': (FsColors.blue100, FsColors.blue700, 'Minor'),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) =
        _map[status] ?? (FsColors.gray100, FsColors.muted, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FsRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: FsText.family,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── RiskDot ───────────────────────────────────────────────────────────────

class RiskDot extends StatelessWidget {
  final String risk;
  const RiskDot({super.key, required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = switch (risk) {
      'CRITICAL' => FsColors.red600,
      'HIGH' => FsColors.red400,
      'MEDIUM' => FsColors.amber400,
      'LOW' => FsColors.green500,
      _ => FsColors.subtle,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── ProgressBar ───────────────────────────────────────────────────────────

class ProgressBar extends StatelessWidget {
  /// 0–100.
  final double value;
  final Color color;
  const ProgressBar({super.key, required this.value, this.color = FsColors.primary});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(FsRadius.full),
        child: LinearProgressIndicator(
          value: (value.clamp(0, 100)) / 100,
          minHeight: 6,
          backgroundColor: FsColors.gray100,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
}

// ─── ScoreRing ─────────────────────────────────────────────────────────────

class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  const ScoreRing({super.key, required this.score, this.size = 64});

  static Color colorFor(double score) => score >= 80
      ? FsColors.success
      : score >= 60
          ? FsColors.warning
          : FsColors.danger;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(score);
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
              strokeWidth: 4,
              backgroundColor: FsColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${score.round()}%',
            style: TextStyle(
              fontFamily: FsText.family,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KpiCard ───────────────────────────────────────────────────────────────

class KpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.color = FsColors.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FsColors.card,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          border: Border.all(color: FsColors.border),
          boxShadow: FsShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(FsRadius.xl),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Text(value, style: FsText.kpiValue),
            const SizedBox(height: 2),
            Text(label, style: FsText.xs, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub!,
                style: FsText.tiny.copyWith(
                  color: FsColors.green700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
}

// ─── SectionHeader ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: FsText.cardTitle),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action!,
                  style: FsText.small.copyWith(
                    color: FsColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── FsCard ────────────────────────────────────────────────────────────────

/// `Card` in the PWA. Renamed to avoid colliding with Material's Card.
class FsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const FsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: FsColors.card,
        borderRadius: BorderRadius.circular(FsRadius.xl2),
        border: Border.all(color: FsColors.border),
        boxShadow: FsShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── TopBar ────────────────────────────────────────────────────────────────

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? right;

  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.right,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: FsColors.surface,
          border: Border(bottom: BorderSide(color: FsColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (onBack != null) ...[
                  GestureDetector(
                    onTap: onBack,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: FsColors.gray700),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: FsText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: FsText.small,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (right != null) right!,
              ],
            ),
          ),
        ),
      );
}

// ─── EmptyState ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: FsText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FsColors.gray700,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: FsText.small),
            ],
          ),
        ),
      );
}

// ─── FAB ───────────────────────────────────────────────────────────────────

class FsFab extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;
  final String? label;

  const FsFab({
    super.key,
    required this.onTap,
    this.icon = '+',
    this.label,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: FsColors.primary,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            boxShadow: FsShadows.cardMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon,
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w300)),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// ─── Toast ─────────────────────────────────────────────────────────────────

enum FsToastType { success, error, warning, info }

class FsToast {
  const FsToast._();

  static void show(
    BuildContext context,
    String message, {
    FsToastType type = FsToastType.success,
  }) {
    final (bg, icon) = switch (type) {
      FsToastType.success => (FsColors.green700, '✅'),
      FsToastType.error => (FsColors.red600, '❌'),
      FsToastType.warning => (FsColors.amber400, '⚠️'),
      FsToastType.info => (FsColors.roleManager, 'ℹ️'),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 8,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FsRadius.xl2),
          ),
          content: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Shared "an action just failed" toast, reused by every screen that wraps
  /// a NOC/regulator/vendor gateway call (AI Audit Engine Phase 8, NOC
  /// Readiness). [error] is interpolated verbatim — callers that catch a raw
  /// HTTP/library exception and want it shown exactly as caught use this;
  /// callers that want a safe, generic failure toast use [showSafeError]
  /// below instead.
  static void showError(BuildContext context, Object error,
          {required String action}) =>
      show(context, '$action failed: $error', // SINK: PLANTED-Dart-HR-484
          type: FsToastType.error);

  /// Same shared toast mechanism as [showError], but never repeats the
  /// caught value in the UI — only a fixed, generic sentence is shown; the
  /// real detail is left to the caller to log (e.g. via `debugPrint`).
  static void showSafeError(BuildContext context, Object error,
          {required String action}) =>
      show(
          context,
          '$action failed. Please try again.', // SAFE_SINK: PLANTED-Dart-HR-484-safe
          type: FsToastType.error);
}

// ─── SkeletonCard ──────────────────────────────────────────────────────────

class SkeletonCard extends StatefulWidget {
  final int lines;
  const SkeletonCard({super.key, this.lines = 2});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Opacity(
          opacity: 0.5 + (_c.value * 0.5),
          child: FsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(widthFactor: 0.75, height: 12, color: const Color(0xFFE5E7EB)),
                const SizedBox(height: 12),
                for (var i = 0; i < widget.lines; i++) ...[
                  _bar(
                    widthFactor: i == widget.lines - 1 ? 0.5 : 1.0,
                    height: 10,
                    color: FsColors.gray100,
                  ),
                  if (i != widget.lines - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _bar({
    required double widthFactor,
    required double height,
    required Color color,
  }) =>
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(FsRadius.full),
          ),
        ),
      );
}
