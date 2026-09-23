/// Port of pwa_app/src/screens/admin/CreateUser.jsx
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/fs_mock_data.dart';
import '../theme/fs_tokens.dart';
import '../widgets/fs_wizard.dart';

const _kRoles = [
  ('auditor', 'Field Auditor', 'Conduct on-site fire safety audits', '🔍'),
  ('manager', 'Safety Manager', 'Manage facility safety operations', '🛡️'),
  ('admin', 'Platform Admin', 'Full platform administration access', '⚙️'),
];

const _kDepts = [
  'Fire Safety', 'Compliance', 'Operations', 'Administration',
  'Security', 'Engineering', 'EHS', 'Platform',
];

class FsCreateUserScreen extends StatefulWidget {
  const FsCreateUserScreen({super.key});

  @override
  State<FsCreateUserScreen> createState() => _FsCreateUserScreenState();
}

class _FsCreateUserScreenState extends State<FsCreateUserScreen> {
  final _form = <String, String>{'role': ''};
  bool _sendInvite = true;
  bool _saving = false;
  bool _created = false;

  bool get _canSave =>
      (_form['firstName'] ?? '').isNotEmpty &&
      (_form['email'] ?? '').isNotEmpty &&
      (_form['role'] ?? '').isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _created = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      final name = '${_form['firstName'] ?? ''} ${_form['lastName'] ?? ''}'.trim();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FsSuccessSheet(
            title: name,
            subtitle: 'has been created successfully'
                '${_sendInvite ? '\nLogin credentials sent to ${_form['email']}' : ''}',
            details: [
              ('Role', _kRoles.firstWhere((r) => r.$1 == _form['role']).$2),
              ('Department', _form['dept'] ?? '—'),
              ('Temporary password', 'Welcome@123'),
            ],
            onClose: () => context.pop(),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('ROLE',
                  style: FsText.xs.copyWith(
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              ..._kRoles.map((r) {
                final selected = _form['role'] == r.$1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _form['role'] = r.$1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFFBEB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(FsRadius.xl2),
                        border: Border.all(
                          color: selected
                              ? FsColors.eyYellow
                              : FsColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(r.$4, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(r.$2, style: FsText.cardTitle),
                                Text(r.$3, style: FsText.tiny),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle,
                                color: FsColors.eyDark, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FsField(
                      label: 'First Name',
                      required: true,
                      child: TextField(
                        decoration: fsInputDecoration('First name'),
                        onChanged: (v) => _form['firstName'] = v,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FsField(
                      label: 'Last Name',
                      child: TextField(
                        decoration: fsInputDecoration('Last name'),
                        onChanged: (v) => _form['lastName'] = v,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FsField(
                label: 'Email',
                required: true,
                child: TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: fsInputDecoration('name@organisation.com'),
                  onChanged: (v) => _form['email'] = v,
                ),
              ),
              const SizedBox(height: 14),
              FsField(
                label: 'Phone',
                child: TextField(
                  keyboardType: TextInputType.phone,
                  decoration: fsInputDecoration('+91 XXXXX XXXXX'),
                  onChanged: (v) => _form['phone'] = v,
                ),
              ),
              const SizedBox(height: 14),
              FsField(
                label: 'Department',
                child: FsDropdown(
                  value: _form['dept'],
                  hint: 'Select department',
                  options: _kDepts,
                  onChanged: (v) => setState(() => _form['dept'] = v ?? ''),
                ),
              ),
              const SizedBox(height: 14),
              FsField(
                label: 'Organisation',
                child: FsDropdown(
                  value: _form['org'],
                  hint: 'Select organisation',
                  options: organizations.map((o) => o.name).toList(),
                  onChanged: (v) => setState(() => _form['org'] = v ?? ''),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _sendInvite = !_sendInvite),
                child: Row(
                  children: [
                    Icon(
                      _sendInvite
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: _sendInvite
                          ? FsColors.eyDark
                          : FsColors.subtle,
                    ),
                    const SizedBox(width: 8),
                    const Text('Send login invite by email', style: FsText.small),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: FsColors.surface,
            border: Border(top: BorderSide(color: FsColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _canSave && !_saving ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: FsColors.eyYellow,
                foregroundColor: FsColors.gray900,
                disabledBackgroundColor:
                    FsColors.eyYellow.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
              ),
              child: Text(_saving ? 'Creating…' : 'Create User',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }
}
