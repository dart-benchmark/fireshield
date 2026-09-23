/// Audit execution and summary.
///
/// Ports of pwa_app/src/screens/audit/AuditExecution.jsx and AuditSummary.jsx.
///
/// The checklist is backed by the real NBC 2016 / BIS masterdata generated
/// from "NBC_BIS Fire safety masterdata .xlsx" (226 checkpoints), so this
/// screen exercises actual regulation content rather than placeholder rows.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/checkpoint_model.dart';
import '../../data/nbc_bis_masterdata.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

/// Holds answers for the audit currently open. In-memory, like the PWA.
class FsAuditRun {
  FsAuditRun._();
  static final FsAuditRun instance = FsAuditRun._();

  final Map<String, Response> answers = {};
  final Map<String, String> remarks = {};

  List<Checkpoint> get checkpoints => allCheckpoints;

  List<String> get categories {
    final seen = <String>[];
    for (final c in checkpoints) {
      if (!seen.contains(c.category)) seen.add(c.category);
    }
    return seen;
  }

  List<Checkpoint> inCategory(String c) =>
      checkpoints.where((x) => x.category == c).toList();

  int get answered =>
      answers.values.where((r) => r != Response.unanswered).length;

  int get passed => answers.values.where((r) => r == Response.yes).length;
  int get failed => answers.values.where((r) => r == Response.no).length;
  int get na =>
      answers.values.where((r) => r == Response.notApplicable).length;

  int get criticalFailures => checkpoints
      .where((c) =>
          c.severity == Severity.critical && answers[c.id] == Response.no)
      .length;

  double get progress =>
      checkpoints.isEmpty ? 0 : answered / checkpoints.length;

  /// Severity-weighted compliance across answered checkpoints only.
  double get score {
    var avail = 0, earned = 0;
    for (final c in checkpoints) {
      final r = answers[c.id];
      if (r == Response.yes) {
        avail += c.severity.weight;
        earned += c.severity.weight;
      } else if (r == Response.no) {
        avail += c.severity.weight;
      }
    }
    return avail == 0 ? 0 : (earned / avail) * 100;
  }

  void reset() {
    answers.clear();
    remarks.clear();
  }
}

// ─── Audit Execution ───────────────────────────────────────────────────────

class FsAuditExecution extends StatefulWidget {
  const FsAuditExecution({super.key});

  @override
  State<FsAuditExecution> createState() => _FsAuditExecutionState();
}

class _FsAuditExecutionState extends State<FsAuditExecution> {
  final _run = FsAuditRun.instance;
  int _category = 0;
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final categories = _run.categories;
    final category = categories[_category.clamp(0, categories.length - 1)];
    final items = _run.inCategory(category);

    return Column(
      children: [
        _buildProgress(),
        _buildCategoryTabs(categories),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            itemBuilder: (_, i) => _checkpointCard(items[i]),
          ),
        ),
        _buildBottomBar(categories),
      ],
    );
  }

  Widget _buildProgress() => Container(
        color: FsColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_run.answered} of ${_run.checkpoints.length} answered',
                    style: FsText.small),
                Text('${(_run.progress * 100).round()}%',
                    style: FsText.small
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar(value: _run.progress * 100),
          ],
        ),
      );

  Widget _buildCategoryTabs(List<String> categories) => Container(
        color: FsColors.surface,
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final active = i == _category;
            final items = _run.inCategory(categories[i]);
            final done = items
                .where((c) =>
                    (_run.answers[c.id] ?? Response.unanswered) !=
                    Response.unanswered)
                .length;
            return GestureDetector(
              onTap: () => setState(() => _category = i),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? FsColors.primary : FsColors.gray100,
                  borderRadius: BorderRadius.circular(FsRadius.full),
                ),
                child: Text(
                  '${categories[i]}  $done/${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : FsColors.muted,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _checkpointCard(Checkpoint c) {
    final response = _run.answers[c.id] ?? Response.unanswered;
    final open = _expanded.contains(c.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: FsColors.card,
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          border: Border.all(
            color: response == Response.no
                ? FsColors.danger.withValues(alpha: 0.4)
                : FsColors.border,
          ),
          boxShadow: FsShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.id,
                          style: FsText.tiny
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      StatusBadge(
                          status: c.severity.label.toUpperCase()),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => open
                            ? _expanded.remove(c.id)
                            : _expanded.add(c.id)),
                        child: Icon(
                          open ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: FsColors.subtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c.title, style: FsText.cardTitle),
                  const SizedBox(height: 2),
                  Text(c.subCategory, style: FsText.tiny),
                ],
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: FsColors.border),
                    const SizedBox(height: 10),
                    Text(c.description, style: FsText.small),
                    const SizedBox(height: 8),
                    Text('Evidence: ${c.evidence}', style: FsText.tiny),
                    const SizedBox(height: 6),
                    Text(c.standardLabel,
                        style:
                            FsText.tiny.copyWith(color: FsColors.info)),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: _run.remarks[c.id] ?? '',
                      onChanged: (v) => _run.remarks[c.id] = v,
                      maxLines: 2,
                      style: FsText.small,
                      decoration: InputDecoration(
                        hintText: 'Observation / remarks',
                        hintStyle: FsText.small,
                        filled: true,
                        fillColor: const Color(0xFFF8F9FC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(FsRadius.xl),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  _answerButton(c, Response.yes, 'Yes', FsColors.success),
                  const SizedBox(width: 8),
                  _answerButton(c, Response.no, 'No', FsColors.danger),
                  const SizedBox(width: 8),
                  _answerButton(
                      c, Response.notApplicable, 'N/A', FsColors.muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(
      Checkpoint c, Response value, String label, Color color) {
    final active = (_run.answers[c.id] ?? Response.unanswered) == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          if (active) {
            _run.answers.remove(c.id);
          } else {
            _run.answers[c.id] = value;
          }
        }),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(FsRadius.xl),
            border: Border.all(color: active ? color : FsColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : FsColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<String> categories) {
    final isLast = _category >= categories.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: FsColors.surface,
        border: Border(top: BorderSide(color: FsColors.border)),
      ),
      child: Row(
        children: [
          if (_category > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _category--),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  context.go('/audit/summary');
                } else {
                  setState(() => _category++);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FsColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
              ),
              child: Text(isLast ? 'Finish & Review' : 'Next Section'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Audit Summary ─────────────────────────────────────────────────────────

class FsAuditSummary extends StatelessWidget {
  const FsAuditSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final run = FsAuditRun.instance;
    final score = run.score;
    final nocOk = run.criticalFailures == 0 &&
        score >= 80 &&
        run.answered == run.checkpoints.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        FsCard(
          child: Column(
            children: [
              Row(
                children: [
                  ScoreRing(score: score, size: 90),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Compliance Score',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: FsColors.gray900)),
                        const SizedBox(height: 4),
                        Text(
                          '${run.answered} of ${run.checkpoints.length} checkpoints answered',
                          style: FsText.tiny,
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(
                          status: score >= 80
                              ? 'APPROVED'
                              : score >= 60
                                  ? 'SUBMITTED'
                                  : 'OVERDUE',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: FsColors.border),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _stat('Passed', run.passed, FsColors.success)),
                  Expanded(child: _stat('Failed', run.failed, FsColors.danger)),
                  Expanded(child: _stat('N/A', run.na, FsColors.muted)),
                  Expanded(child: _stat('Critical', run.criticalFailures,
                      FsColors.red600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (nocOk ? FsColors.success : FsColors.danger)
                .withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(
              color: (nocOk ? FsColors.success : FsColors.danger)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nocOk ? '✅' : '⛔',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nocOk ? 'NOC criteria met' : 'NOC not recommended',
                      style: FsText.cardTitle.copyWith(
                        color:
                            nocOk ? FsColors.success : FsColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      run.answered < run.checkpoints.length
                          ? '${run.checkpoints.length - run.answered} checkpoints still unanswered.'
                          : run.criticalFailures > 0
                              ? '${run.criticalFailures} critical failure(s) must be closed first.'
                              : score < 80
                                  ? 'Compliance ${score.toStringAsFixed(0)}% is below the 80% threshold.'
                                  : 'No critical failures and compliance above 80%.',
                      style: FsText.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go('/reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FsColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FsRadius.xl),
              ),
            ),
            child: const Text('Generate Report'),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) => Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label, style: FsText.tiny),
        ],
      );
}
