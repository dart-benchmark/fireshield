/// Shared gradient dashboard header used by every role dashboard.
///
/// The PWA repeats this block per screen with a different gradient and
/// eyebrow; this factors it into one widget so the role screens stay short.
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';

class FsDashboardHeader extends StatelessWidget {
  final LinearGradient gradient;

  /// Small uppercase role label, e.g. "SAFETY MANAGER".
  final String eyebrow;
  final String org;
  final String title;
  final String subtitle;
  final String initials;

  /// Optional large content under the identity block (FRI ring, KPI hero).
  final Widget? hero;

  /// (value, label, optional value colour).
  final List<(String, String, Color?)> kpis;

  final List<String> tabs;
  final int activeTab;
  final ValueChanged<int>? onTab;

  /// Makes the title row tappable — used for the facility picker.
  final VoidCallback? onTitleTap;

  const FsDashboardHeader({
    super.key,
    required this.gradient,
    required this.eyebrow,
    required this.org,
    required this.title,
    required this.subtitle,
    required this.initials,
    this.hero,
    this.kpis = const [],
    this.tabs = const [],
    this.activeTab = 0,
    this.onTab,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    eyebrow,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      org,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFFDE68A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: onTitleTap,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (onTitleTap != null) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.expand_more,
                                          size: 16,
                                          color: Color(0xFFBFDBFE)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFBFDBFE),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FsColors.eyYellow,
                            borderRadius: BorderRadius.circular(FsRadius.xl),
                          ),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: FsColors.eyDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hero != null) ...[
                      const SizedBox(height: 14),
                      hero!,
                    ],
                    if (kpis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0; i < kpis.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(FsRadius.xl),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      kpis[i].$1,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: kpis[i].$3 ?? Colors.white,
                                      ),
                                    ),
                                    Text(
                                      kpis[i].$2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFBFDBFE),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (tabs.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTab?.call(i),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 2,
                                    color: i == activeTab
                                        ? FsColors.eyYellow
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Text(
                                tabs[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: i == activeTab
                                      ? FsColors.eyYellow
                                      : const Color(0xFFBFDBFE),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}
