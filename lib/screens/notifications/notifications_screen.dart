import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _State();
}

class _State extends State<NotificationsScreen> {
  final Set<String> _read = {};

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: buildAppBar(
      context,
      title: 'Notifications',
      showBack: true,
      actions: [
        TextButton(onPressed: () => setState(() => _read.addAll(mockNotifications.map((n) => n.id))), child: const Text('Mark all read', style: AppTextStyles.caption)),
      ],
    ),
    body: ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mockNotifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final n = mockNotifications[i];
        final isRead = _read.contains(n.id);
        return GestureDetector(
          onTap: () => setState(() => _read.add(n.id)),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isRead ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _typeColor(n.type).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700))),
                    if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.body, style: AppTextStyles.caption.copyWith(height: 1.4)),
                  const SizedBox(height: 6),
                  Text(n.time, style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 10)),
                ])),
              ],
            ),
          ),
        );
      },
    ),
  );

  Color _typeColor(String type) => switch (type) {
    'CRITICAL_FINDING' => AppColors.error,
    'AUDIT_ASSIGNED' => AppColors.secondary,
    'CA_OVERDUE' => AppColors.warning,
    'NOC_ALERT' => AppColors.riskHigh,
    _ => AppColors.info,
  };

  IconData _typeIcon(String type) => switch (type) {
    'CRITICAL_FINDING' => Icons.warning_rounded,
    'AUDIT_ASSIGNED' => Icons.assignment_rounded,
    'CA_OVERDUE' => Icons.assignment_late_rounded,
    'NOC_ALERT' => Icons.shield_rounded,
    _ => Icons.notifications_rounded,
  };
}
