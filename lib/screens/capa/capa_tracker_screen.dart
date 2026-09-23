import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/engine/audit_session.dart';
import '../../core/engine/capa_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/checkpoint_model.dart';

/// CAPA tracker — one action per failed checkpoint, with due dates driven by
/// severity and escalation that rises as actions go past due.
class CapaTrackerScreen extends StatefulWidget {
  const CapaTrackerScreen({super.key});

  @override
  State<CapaTrackerScreen> createState() => _CapaTrackerScreenState();
}

class _CapaTrackerScreenState extends State<CapaTrackerScreen> {
  final _session = AuditSession.instance;
  final _dateFmt = DateFormat('d MMM yyyy');
  String _filter = 'all';

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

  List<CapaAction> _apply(List<CapaAction> all, DateTime now) => switch (_filter) {
        'open' => all.where((c) => c.status.isOpen).toList(),
        'overdue' => all.where((c) => c.isOverdue(now)).toList(),
        'critical' =>
          all.where((c) => c.severity == Severity.critical).toList(),
        'closed' =>
          all.where((c) => c.status == CapaStatus.closed).toList(),
        _ => all,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = _session.capaActions;
    final shown = _apply(all, now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CAPA Tracker'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: all.isEmpty
          ? EmptyState(
              title: 'No CAPA actions',
              subtitle:
                  'Actions are raised from failed checkpoints on the risk screen.',
              icon: Icons.build_outlined,
              buttonLabel: 'Go to risk score',
              onButton: () => context.push('/risk-dashboard'),
            )
          : Column(
              children: [
                _buildSummary(all, now),
                _buildFilters(all, now),
                Expanded(
                  child: shown.isEmpty
                      ? const EmptyState(
                          title: 'Nothing in this filter',
                          subtitle: 'Switch to another filter to see actions.',
                          icon: Icons.filter_alt_off_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: shown.length,
                          itemBuilder: (_, i) => _buildCard(shown[i], now),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummary(List<CapaAction> all, DateTime now) {
    final overdue = CapaEngine.overdueCount(all, now);
    final closure = CapaEngine.closureRate(all) * 100;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Open',
              value: '${CapaEngine.openCount(all)}',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Overdue',
              value: '$overdue',
              icon: Icons.schedule_outlined,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Closure',
              value: '${closure.toStringAsFixed(0)}%',
              icon: Icons.task_alt,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<CapaAction> all, DateTime now) => Container(
        color: AppColors.surface,
        height: 46,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip('all', 'All ${all.length}'),
            _chip('open', 'Open ${CapaEngine.openCount(all)}'),
            _chip('overdue', 'Overdue ${CapaEngine.overdueCount(all, now)}'),
            _chip(
                'critical',
                'Critical '
                    '${all.where((c) => c.severity == Severity.critical).length}'),
            _chip('closed', 'Closed ${CapaEngine.closedCount(all)}'),
          ],
        ),
      );

  Widget _chip(String key, String label) {
    final active = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.inputFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
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
  }

  Widget _buildCard(CapaAction c, DateTime now) {
    final overdue = c.isOverdue(now);
    final days = c.daysRemaining(now);
    final esc = c.escalation(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
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
              StatusBadge(status: _statusKey(c.status)),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.title, style: AppTextStyles.h6),
          const SizedBox(height: 4),
          Text('${c.checkpointId} · ${c.standardRef}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondary)),
          const SizedBox(height: 10),
          Text(c.finding, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          _labelled('Corrective', c.corrective),
          const SizedBox(height: 8),
          _labelled('Preventive', c.preventive),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(c.owner, style: AppTextStyles.caption),
              const Spacer(),
              Icon(
                overdue ? Icons.error_outline : Icons.event_outlined,
                size: 15,
                color: overdue ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                overdue
                    ? '${c.overdueDays(now)}d overdue'
                    : c.status.stopsClock
                        ? _dateFmt.format(c.dueOn)
                        : '$days d left',
                style: AppTextStyles.caption.copyWith(
                  color: overdue ? AppColors.error : AppColors.textSecondary,
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
          if (esc != EscalationLevel.none) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      size: 15, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(esc.label,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _advance(c),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(_nextLabel(c.status),
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _assign(c),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text('Reassign',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 3),
          Text(body, style: AppTextStyles.bodySmall),
        ],
      );

  void _advance(CapaAction c) {
    final next = switch (c.status) {
      CapaStatus.open => CapaStatus.inProgress,
      CapaStatus.inProgress => CapaStatus.submitted,
      CapaStatus.submitted => CapaStatus.verified,
      CapaStatus.verified => CapaStatus.closed,
      CapaStatus.rejected => CapaStatus.inProgress,
      CapaStatus.closed => CapaStatus.closed,
    };
    _session.updateCapa(c.id, c.copyWith(status: next));
  }

  String _nextLabel(CapaStatus s) => switch (s) {
        CapaStatus.open => 'Start work',
        CapaStatus.inProgress => 'Submit',
        CapaStatus.submitted => 'Verify',
        CapaStatus.verified => 'Close',
        CapaStatus.rejected => 'Rework',
        CapaStatus.closed => 'Closed',
      };

  String _statusKey(CapaStatus s) => switch (s) {
        CapaStatus.open => 'OPEN',
        CapaStatus.inProgress => 'IN_PROGRESS',
        CapaStatus.submitted => 'SUBMITTED',
        CapaStatus.verified => 'PENDING_REVIEW',
        CapaStatus.closed => 'CLOSED',
        CapaStatus.rejected => 'ESCALATED',
      };

  Future<void> _assign(CapaAction c) async {
    const owners = [
      'Safety Manager',
      'Facility Engineer',
      'Fire Systems Technician',
      'Projects Team',
      'Unassigned',
    ];

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text('Assign ${c.id}', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            ...owners.map((o) => ListTile(
                  title: Text(o, style: AppTextStyles.bodyMedium),
                  trailing: o == c.owner
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null) {
      _session.updateCapa(c.id, c.copyWith(owner: picked));
    }
  }
}
