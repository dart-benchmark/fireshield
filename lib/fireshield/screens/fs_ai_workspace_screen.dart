/// Shared AI capability hub for every authenticated FireShield role.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';

class FsAiWorkspaceScreen extends StatelessWidget {
  const FsAiWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = FsAppState.instance.user?.role.label ?? 'FireShield user';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: FsColors.darkGradient,
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            boxShadow: FsShadows.cardMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI WORKSPACE',
                  style: TextStyle(
                    color: FsColors.eyYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 8),
              const Text('One place for every AI workflow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 6),
              Text(
                'Available to $role · grounded in NBCS 2026 · provider keys stay server-side',
                style: const TextStyle(
                    color: FsColors.gray400, fontSize: 11, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ToolCard(
          icon: '💬',
          title: 'Compliance Assistant',
          subtitle:
              'Ask questions grounded in the NBCS 2026 graph with page citations.',
          badge: 'GPT-OSS',
          color: FsColors.info,
          onTap: () => context.go('/ai'),
        ),
        const SizedBox(height: 10),
        _ToolCard(
          icon: '📷',
          title: 'AI Audit Engine',
          subtitle:
              'Detect fire-safety equipment, identify gaps and produce cited findings.',
          badge: 'QWEN + GPT-OSS',
          color: FsColors.primary,
          onTap: () => context.go('/ai-engine'),
        ),
        const SizedBox(height: 10),
        _ToolCard(
          icon: '📐',
          title: 'Floor Plan → DXF',
          subtitle:
              'Upload a PDF or image, review Qwen-guided reconstruction and download DXF/JSON.',
          badge: 'NEW',
          color: FsColors.roleOrgAdmin,
          onTap: () => context.go('/floorplan'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FsColors.warningLight,
            borderRadius: BorderRadius.circular(FsRadius.xl),
            border: Border.all(color: FsColors.amber100),
          ),
          child: const Text(
            'AI output supports professional review; it does not replace statutory approval or a competent fire-safety professional.',
            style: TextStyle(
              color: FsColors.amber700,
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: FsColors.surface,
        borderRadius: BorderRadius.circular(FsRadius.xl2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FsRadius.xl2),
              border: Border.all(color: FsColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(FsRadius.xl),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 23)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: FsText.cardTitle)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(FsRadius.full),
                            ),
                            child: Text(badge,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: FsText.xs.copyWith(height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: FsColors.subtle),
              ],
            ),
          ),
        ),
      );
}
