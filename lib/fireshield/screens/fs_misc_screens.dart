/// Profile, Reports, Reference Library and AI Assistant.
///
/// Ports of pwa_app/src/screens/profile/ProfileScreen.jsx,
/// reports/ReportsScreen.jsx, reference/ReferenceLibrary.jsx and
/// ai/AiAssistant.jsx.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../data/checkpoint_model.dart';
import '../../data/nbc_bis_masterdata.dart';
import '../data/fs_mock_data.dart';
import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../services/fs_groq_service.dart';
import '../services/fs_persistence_service.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

// ─── Profile ───────────────────────────────────────────────────────────────

class FsProfileScreen extends StatelessWidget {
  const FsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FsAppState.instance.user;
    if (user == null) {
      return const EmptyState(
        icon: '👤',
        title: 'Not signed in',
        subtitle: 'Sign in to view your profile.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        FsCard(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FsColors.primary,
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                ),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: FsText.title),
                    const SizedBox(height: 2),
                    Text(user.role.label,
                        style:
                            FsText.small.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(user.email, style: FsText.tiny),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _row('Organisation', user.org),
              _row('Department', user.dept),
              _row('Facility', user.facility),
              _row('Role', user.role.label, last: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tile('🔔', 'Notifications', () {}),
              _tile('🔒', 'Security & MFA', () {}),
              _tile('📚', 'Reference Library', () => context.go('/reference')),
              _tile('🛠️', 'Copy Support Diagnostics',
                  () => _copyDiagnostics(context, user.role)),
              _tile('ℹ️', 'About FireShield AI', () {}, last: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              FsAppState.instance.logout();
              context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: FsColors.danger,
              side: const BorderSide(color: FsColors.danger),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FsRadius.xl),
              ),
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text('FireShield AI™ v2.0.0 · Powered by EY',
              style: FsText.micro),
        ),
      ],
    );
  }

  Future<void> _copyDiagnostics(BuildContext context, FsRole role) async {
    final persistence = FsPersistenceService();
    await persistence.buildSupportDiagnosticSnapshot(role);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Diagnostics ready — share the code with EY support.'),
    ));
  }

  Widget _row(String label, String value, {bool last = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: FsColors.border)),
        ),
        child: Row(
          children: [
            Text(label, style: FsText.small),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: FsText.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: FsColors.gray900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _tile(String icon, String label, VoidCallback onTap,
          {bool last = false}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: FsColors.border)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: FsText.small.copyWith(
                        fontWeight: FontWeight.w600, color: FsColors.gray900)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: FsColors.subtle),
            ],
          ),
        ),
      );
}

// ─── Reports ───────────────────────────────────────────────────────────────

class FsReportsScreen extends StatelessWidget {
  const FsReportsScreen({super.key});

  static const _reports = [
    (
      '📄',
      'Audit Summary Report',
      'PDF · 12–18 pages',
      'Full findings, scores and evidence index'
    ),
    (
      '🏆',
      'NOC Readiness Certificate',
      'PDF · Official Format',
      'Regulator-ready readiness statement'
    ),
    (
      '📊',
      'Risk Register',
      'NBC 2026 Gap Mapping',
      'Every open gap mapped to its clause'
    ),
    (
      '🏛️',
      'Govt Submission Package',
      'Regulatory Format',
      'Bundle for the local fire authority'
    ),
    ('📈', 'Compliance Trend', 'XLSX · 6 months', 'Score movement by facility'),
    (
      '⚠️',
      'CAPA Status Report',
      'PDF · Live',
      'Open, overdue and closed actions'
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('AVAILABLE REPORTS',
              style: FsText.xs
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          ..._reports.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FsCard(
                onTap: () => FsToast.show(
                  context,
                  '${r.$2} — export not wired up in this build.',
                  type: FsToastType.info,
                ),
                child: Row(
                  children: [
                    Text(r.$1, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.$2, style: FsText.cardTitle),
                          const SizedBox(height: 2),
                          Text(r.$4, style: FsText.tiny),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: FsColors.infoLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(r.$3,
                                style: FsText.micro
                                    .copyWith(color: FsColors.info)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.download_outlined,
                        size: 18, color: FsColors.subtle),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ─── Reference Library ─────────────────────────────────────────────────────

/// Browsable NBC/BIS reference, backed by the 226 real checkpoints generated
/// from the Excel masterdata.
class FsReferenceLibrary extends StatefulWidget {
  const FsReferenceLibrary({super.key});

  @override
  State<FsReferenceLibrary> createState() => _FsReferenceLibraryState();
}

class _FsReferenceLibraryState extends State<FsReferenceLibrary> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final c in allCheckpoints) {
      if (!categories.contains(c.category)) categories.add(c.category);
    }

    final q = _query.trim().toLowerCase();
    final results = allCheckpoints.where((c) {
      if (_category != null && c.category != _category) return false;
      if (q.isEmpty) return true;
      return '${c.id} ${c.title} ${c.description} ${c.category} ${c.subCategory}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          color: FsColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search ${allCheckpoints.length} NBC & BIS checkpoints',
              hintStyle: FsText.small,
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FsRadius.xl),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('All', _category == null,
                  () => setState(() => _category = null)),
              ...categories.map((c) => _chip(
                    c,
                    _category == c,
                    () => setState(() => _category = c),
                  )),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const EmptyState(
                  icon: '🔍',
                  title: 'No match',
                  subtitle: 'Try a different term or clear the filter.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final c = results[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FsCard(
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
                                Text(c.standardLabel,
                                    style: FsText.micro
                                        .copyWith(color: FsColors.info)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(c.title, style: FsText.cardTitle),
                            const SizedBox(height: 4),
                            Text(c.description, style: FsText.small),
                            const SizedBox(height: 6),
                            Text('Evidence: ${c.evidence}', style: FsText.tiny),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? FsColors.primary : FsColors.gray100,
              borderRadius: BorderRadius.circular(FsRadius.full),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : FsColors.muted,
              ),
            ),
          ),
        ),
      );
}

// ─── AI Assistant ──────────────────────────────────────────────────────────

class FsAiAssistant extends StatefulWidget {
  const FsAiAssistant({super.key});

  @override
  State<FsAiAssistant> createState() => _FsAiAssistantState();
}

class _FsAiAssistantState extends State<FsAiAssistant> {
  final _ctrl = TextEditingController();
  final _service = FsGroqService();
  bool _sending = false;
  final List<(bool, String)> _messages = [
    (
      false,
      'Ask me about NBCS 2026 Part F, BIS standards, or any checkpoint in the audit master.'
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _sending) return;
    setState(() {
      _messages.add((true, question));
      _ctrl.clear();
      _sending = true;
    });
    try {
      final history = _messages
          .skip(1)
          .map((m) => {
                'role': m.$1 ? 'user' : 'assistant',
                'content': m.$2,
              })
          .toList();
      final answer = await _service.chat(history);
      if (!mounted) return;
      setState(() => _messages.add((
            false,
            answer.isEmpty
                ? 'The AI service returned an empty response.'
                : answer
          )));
    } on FsServiceException catch (error) {
      if (!mounted) return;
      setState(() => _messages.add((
            false,
            error.status == 429
                ? 'The AI request limit was reached. Please wait about a minute and try again.'
                : 'AI assistant unavailable: ${error.message}'
          )));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final (mine, text) = _messages[i];
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: mine ? FsColors.primary : FsColors.card,
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                      border: Border.all(
                          color: mine ? FsColors.primary : FsColors.border),
                      boxShadow: mine ? null : FsShadows.card,
                    ),
                    child: mine
                        ? Text(text,
                            style: FsText.small
                                .copyWith(color: Colors.white, height: 1.5))
                        : MarkdownBody(
                            data: text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: FsText.small.copyWith(
                                  color: FsColors.gray900, height: 1.5),
                              h1: FsText.h2,
                              h2: FsText.cardTitle,
                              h3: FsText.small
                                  .copyWith(fontWeight: FontWeight.w700),
                              strong:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              blockquote: FsText.small
                                  .copyWith(color: FsColors.gray700),
                              blockquoteDecoration: const BoxDecoration(
                                color: FsColors.gray100,
                                border: Border(
                                  left: BorderSide(
                                      color: FsColors.primary, width: 3),
                                ),
                              ),
                              listBullet: FsText.small,
                              code: FsText.tiny.copyWith(
                                  fontFamily: 'monospace',
                                  backgroundColor: FsColors.gray100),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: FsColors.surface,
              border: Border(top: BorderSide(color: FsColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _send,
                    style: FsText.small,
                    decoration: InputDecoration(
                      hintText: 'Ask about a standard or checkpoint',
                      hintStyle: FsText.small,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FsRadius.full),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : () => _send(_ctrl.text),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _sending ? FsColors.gray400 : FsColors.primary,
                      borderRadius: BorderRadius.circular(FsRadius.full),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_upward,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ─── Facilities list (manager + orgadmin sub-routes) ───────────────────────

class FsFacilitiesScreen extends StatelessWidget {
  const FsFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const facilities = mockFacilities;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('FACILITIES · ${facilities.length}',
            style: FsText.xs
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 10),
        ...facilities.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(f.name,
                            style: FsText.cardTitle,
                            overflow: TextOverflow.ellipsis),
                      ),
                      StatusBadge(status: f.noc),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${f.type} · ${f.city}, ${f.state}', style: FsText.tiny),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ProgressBar(
                          value: f.compliance.toDouble(),
                          color: ScoreRing.colorFor(f.compliance.toDouble()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${f.compliance}%',
                          style: FsText.tiny
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${f.floors} floors · ${f.basements} basements · ${f.area} · ${f.occupancy} occupants',
                    style: FsText.micro,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
