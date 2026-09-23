/// Port of pwa_app/src/components/BottomNav.jsx — per-role tab bars.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_models.dart';
import '../theme/fs_tokens.dart';

class FsNavTab {
  final String path;
  final String icon;
  final String label;
  const FsNavTab(this.path, this.icon, this.label);
}

/// Tab sets keyed by role, matching the PWA's `tabs` map exactly.
const Map<FsRole, List<FsNavTab>> fsNavTabs = {
  FsRole.admin: [
    FsNavTab('/admin', '⊞', 'Dashboard'),
    FsNavTab('/admin/orgs', '🏢', 'Orgs'),
    FsNavTab('/admin/analytics', '📊', 'Analytics'),
    FsNavTab('/ai-workspace', '🤖', 'AI'),
    FsNavTab('/profile', '👤', 'Profile'),
  ],
  FsRole.manager: [
    FsNavTab('/manager', '⊞', 'Dashboard'),
    FsNavTab('/manager/audits', '📋', 'Audits'),
    FsNavTab('/reference', '📚', 'Reference'),
    FsNavTab('/reports', '📄', 'Reports'),
    FsNavTab('/ai-workspace', '🤖', 'AI'),
    FsNavTab('/profile', '👤', 'Profile'),
  ],
  FsRole.auditor: [
    FsNavTab('/auditor', '⊞', 'Dashboard'),
    FsNavTab('/auditor/audits', '📋', 'My Audits'),
    FsNavTab('/reference', '📚', 'Reference'),
    FsNavTab('/ai-workspace', '🤖', 'AI'),
    FsNavTab('/profile', '👤', 'Profile'),
  ],
  FsRole.orgadmin: [
    FsNavTab('/orgadmin', '⊞', 'Dashboard'),
    FsNavTab('/orgadmin/facilities', '🏢', 'Facilities'),
    FsNavTab('/orgadmin/team', '👥', 'Team'),
    FsNavTab('/orgadmin/audits', '📋', 'Audits'),
    FsNavTab('/ai-workspace', '🤖', 'AI'),
    FsNavTab('/profile', '👤', 'Profile'),
  ],
  FsRole.govt: [
    FsNavTab('/govt', '⊞', 'Dashboard'),
    FsNavTab('/reference', '📚', 'Reference'),
    FsNavTab('/reports', '📄', 'Reports'),
    FsNavTab('/ai-workspace', '🤖', 'AI'),
    FsNavTab('/profile', '👤', 'Profile'),
  ],
};

class FsBottomNav extends StatelessWidget {
  final FsRole role;

  /// Current router location, used to highlight the active tab.
  final String location;

  const FsBottomNav({
    super.key,
    required this.role,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = fsNavTabs[role] ?? fsNavTabs[FsRole.auditor]!;

    return Container(
      decoration: const BoxDecoration(
        color: FsColors.surface,
        border: Border(top: BorderSide(color: FsColors.gray100)),
        boxShadow: FsShadows.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: tabs.map((t) {
              // Exact match, or a deeper path under a non-root tab.
              final active = location == t.path ||
                  (t.path.length > 3 && location.startsWith('${t.path}/'));
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(t.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: active ? 1 : 0.4,
                        child: Transform.scale(
                          scale: active ? 1.1 : 1.0,
                          child: Text(t.icon,
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? FsColors.red600
                              : FsColors.subtle,
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: FsColors.red600,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
