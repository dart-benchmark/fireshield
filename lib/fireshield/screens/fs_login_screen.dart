import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fs_mock_data.dart';
import '../data/fs_models.dart';
import '../fs_app_state.dart';
import '../services/fs_persistence_service.dart';
import '../theme/fs_tokens.dart';

/// Port of pwa_app/src/screens/LoginScreen.jsx
///
/// Two modes: Quick Login (role cards) and Email Login. An unrecognised email
/// opens the "Account Not Found" sheet with support contact details.
class FsLoginScreen extends StatefulWidget {
  const FsLoginScreen({super.key});

  @override
  State<FsLoginScreen> createState() => _FsLoginScreenState();
}

class _FsLoginScreenState extends State<FsLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();

  bool _demoMode = true;
  bool _showPass = false;
  bool _registerMode = false;
  bool _rememberMe = false;
  bool _loading = false;
  int? _loadingId;
  String _error = '';
  String _info = '';
  final _persistence = FsPersistenceService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  static const Map<FsRole, (String, Color, String)> _roleConfig = {
    FsRole.manager: (
      '📊',
      FsColors.roleManager,
      'Manage facilities, assign audits, track corrective actions'
    ),
    FsRole.auditor: (
      '🔍',
      FsColors.roleAuditor,
      'Execute NBC 2026 checklists, record findings, capture evidence'
    ),
    FsRole.admin: (
      '🛡️',
      FsColors.roleAdmin,
      'Manage organisations, users, analytics and platform settings'
    ),
    FsRole.orgadmin: (
      '🏢',
      FsColors.roleOrgAdmin,
      'Manage org facilities, create Safety Managers & Auditors, track compliance'
    ),
  };

  Future<void> _selectUser(FsUser user) async {
    setState(() => _loadingId = user.id);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    FsAppState.instance.login(user);
    context.go('/${user.role.key}');
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Enter email and password');
      return;
    }
    setState(() {
      _error = '';
      _info = '';
      _loading = true;
    });

    try {
      await _persistence.signInWithPassword(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      final user = await _persistence.currentAppUser();
      if (!mounted) return;
      FsAppState.instance.login(user);
      if (_rememberMe) {
        // "Remember me": re-populate the sign-in form next time so the user
        // doesn't have to retype everything after a session expiry.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'fs_remember_password', _passCtrl.text); // SINK: PLANTED-Dart-HR-430
      } else {
        await _cacheEmailForNextVisit();
      }
      context.go('/${user.role.key}');
    } on FsPersistenceException catch (error) {
      if (!mounted) return;
      // The wrapped Supabase AuthException/PostgrestException message is a
      // driver-crafted string (e.g. rate-limit detail, or — once past sign-in
      // — an RLS/query rejection surfaced by currentAppUser()) that can name
      // implementation detail a caregiver was never meant to see.
      setState(() => _error = error.message); // SINK: PLANTED-Dart-HR-480
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The "don't remember my password" path: only the email address is kept
  /// locally, purely so the sign-in field is pre-filled next visit. Actual
  /// re-authentication continuity is Supabase's own already-secured session,
  /// never a bespoke password cache.
  Future<void> _cacheEmailForNextVisit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fs_last_login_email',
        _emailCtrl.text.trim()); // SAFE_SINK: PLANTED-Dart-HR-430-safe
  }

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _orgCtrl.text.trim().length < 2 ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.length < 8) {
      setState(() => _error =
          'Enter your name, organisation, email and a password of at least 8 characters.');
      return;
    }
    setState(() {
      _error = '';
      _info = '';
      _loading = true;
    });
    try {
      final signedIn = await _persistence.signUpOrganisationAdmin(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
        organisationName: _orgCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!signedIn) {
        setState(() {
          _registerMode = false;
          _info = 'Check your email to confirm the account, then sign in. '
              'Your organisation will be created on first sign-in.';
        });
        return;
      }
      final user = await _persistence.currentAppUser();
      if (!mounted) return;
      FsAppState.instance.login(user);
      context.go('/${user.role.key}');
    } on FsPersistenceException catch (error) {
      // Same wrapped-exception shape as _handleLogin's own catch above, but
      // the sign-up form deliberately never repeats Supabase's own message —
      // only a fixed, generic sentence reaches the UI; the real detail is
      // still captured, but only for DevTools/the console.
      debugPrint(
          'Registration failed: ${error.message}'); // SAFE_SINK: PLANTED-Dart-HR-480-safe
      if (mounted) {
        setState(() => _error =
            'Could not create your account. Please check your details and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: FsColors.darkGradient),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _demoMode ? _buildDemoMode() : _buildEmailMode(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _buildSupportCard(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      '© 2026 EY · FireShield AI™ · All Rights Reserved',
                      style: FsText.tiny.copyWith(color: FsColors.gray700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // ─── Hero ───────────────────────────────────────────────────────────────

  Widget _buildHero() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: FsColors.flameGradient,
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 36)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FsColors.heroYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'EY',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: FsColors.gray900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: FsText.family,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'FireShield '),
                  TextSpan(
                    text: 'AI™',
                    style: TextStyle(color: FsColors.heroYellow),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Next-Generation Fire Audit Readiness Platform',
              textAlign: TextAlign.center,
              style: FsText.small.copyWith(color: FsColors.gray400),
            ),
            const SizedBox(height: 20),
            _buildModeToggle(),
          ],
        ),
      );

  Widget _buildModeToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(FsRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeButton('⚡ Quick Login', true),
            const SizedBox(width: 4),
            _modeButton('✉️ Email Login', false),
          ],
        ),
      );

  Widget _modeButton(String label, bool demo) {
    final active = _demoMode == demo;
    return GestureDetector(
      onTap: () => setState(() => _demoMode = demo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FsColors.heroYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? FsColors.gray900 : FsColors.gray400,
          ),
        ),
      ),
    );
  }

  // ─── Demo mode ──────────────────────────────────────────────────────────

  Widget _buildDemoMode() => Column(
        children: [
          Text(
            'Choose your role to explore the platform',
            style: FsText.small.copyWith(color: FsColors.gray500),
          ),
          const SizedBox(height: 12),
          ...demoUsers.map(_buildRoleCard),
          const SizedBox(height: 8),
          Text(
            'Demo roles run live AI but do not write shared history. Use an '
            'organisation account for persistent uploads and assessments.',
            textAlign: TextAlign.center,
            style: FsText.tiny.copyWith(color: FsColors.gray500),
          ),
        ],
      );

  Widget _buildRoleCard(FsUser u) {
    final (icon, color, desc) =
        _roleConfig[u.role] ?? ('👤', FsColors.muted, '');
    final isLoading = _loadingId == u.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: _loadingId != null ? null : () => _selectUser(u),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(FsRadius.xl2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                      boxShadow: FsShadows.cardMd,
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    FsColors.heroYellow.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEMO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: FsColors.heroYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.role.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: FsColors.gray300,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: FsText.tiny.copyWith(color: FsColors.gray500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                FsColors.heroYellow),
                          )
                        : const Icon(Icons.chevron_right,
                            color: FsColors.gray600, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _cred('USERNAME', u.initials),
                  _divider(),
                  _cred('PASSWORD', 'demo123'),
                  _divider(),
                  Expanded(
                    child: Text(
                      u.facility,
                      style: FsText.micro.copyWith(color: FsColors.gray500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cred(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FsText.micro.copyWith(
              color: FsColors.gray500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: FsColors.heroYellow,
            ),
          ),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white.withValues(alpha: 0.1),
      );

  // ─── Email mode ─────────────────────────────────────────────────────────

  Widget _buildEmailMode() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _registerMode = false),
                  child: Text(_registerMode ? 'Sign in' : '• Sign in'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _registerMode = true),
                  child: Text(
                      _registerMode ? '• Create account' : 'Create account'),
                ),
              ),
            ],
          ),
          if (_info.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(FsRadius.xl),
              ),
              child: Text(
                _info,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6EE7B7)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_error.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(FsRadius.xl),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error,
                style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_registerMode) ...[
            _fieldLabel('Full Name'),
            _darkField(controller: _nameCtrl, hint: 'Your name'),
            const SizedBox(height: 16),
            _fieldLabel('Organisation'),
            _darkField(controller: _orgCtrl, hint: 'Organisation name'),
            const SizedBox(height: 16),
          ],
          _fieldLabel('Email Address'),
          _darkField(
            controller: _emailCtrl,
            hint: 'your@organisation.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Password'),
          _darkField(
            controller: _passCtrl,
            hint: '••••••••',
            obscure: !_showPass,
            suffix: GestureDetector(
              onTap: () => setState(() => _showPass = !_showPass),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _showPass ? 'Hide' : 'Show',
                  style: FsText.small.copyWith(
                    color: FsColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (!_registerMode) ...[
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: FsColors.heroYellow,
                    checkColor: FsColors.gray900,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Remember me on this device',
                    style: FsText.small.copyWith(color: FsColors.gray400)),
              ],
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : (_registerMode ? _handleRegister : _handleLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: FsColors.heroYellow,
                foregroundColor: FsColors.gray900,
                disabledBackgroundColor:
                    FsColors.heroYellow.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                ),
              ),
              child: _loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(FsColors.gray900),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Working...',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Text(
                      _registerMode ? 'Create Organisation Account' : 'Sign In',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _showAccountNotFound,
              child: RichText(
                text: TextSpan(
                  style: FsText.small.copyWith(color: FsColors.gray600),
                  children: [
                    const TextSpan(text: "Don't have access? "),
                    TextSpan(
                      text: 'Contact Admin',
                      style: FsText.small.copyWith(
                        color: FsColors.heroYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: FsText.small.copyWith(
            color: FsColors.gray400,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _darkField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) =>
      SizedBox(
        height: 48,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: FsColors.gray600, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            suffixIcon: suffix,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FsRadius.xl),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FsRadius.xl),
              borderSide: BorderSide(
                color: FsColors.heroYellow.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );

  // ─── Support ────────────────────────────────────────────────────────────

  Widget _buildSupportCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PLATFORM SUPPORT',
              style: FsText.micro.copyWith(
                color: FsColors.gray500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FsColors.heroYellow,
                    borderRadius: BorderRadius.circular(FsRadius.xl),
                  ),
                  child: const Text(
                    'KU',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: FsColors.gray900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kartikey Upadhyay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Smart Fire Solution Consultant · EY',
                        style: FsText.tiny.copyWith(color: FsColors.gray400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _contactChip('📞', '+91 76786 77191')),
                const SizedBox(width: 8),
                Expanded(child: _contactChip('✉️', 'Email')),
              ],
            ),
          ],
        ),
      );

  Widget _contactChip(String icon, String label) => Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(FsRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: FsText.tiny.copyWith(
                  color: FsColors.gray300,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  void _showAccountNotFound() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FsRadius.xl3)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FsColors.red100,
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                ),
                child: const Text('🔒', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Not Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: FsColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This email is not registered on FireShield AI.',
                textAlign: TextAlign.center,
                style: FsText.small.copyWith(color: FsColors.gray500),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(FsRadius.xl2),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTACT TO GET ACCESS',
                      style: FsText.tiny.copyWith(
                        color: FsColors.amber700,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FsColors.amber400,
                            borderRadius: BorderRadius.circular(FsRadius.xl),
                          ),
                          child: const Text(
                            'KU',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kartikey Upadhyay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: FsColors.gray900,
                                ),
                              ),
                              Text(
                                'Smart Fire Solution Consultant · EY',
                                style: FsText.tiny
                                    .copyWith(color: FsColors.gray500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _sheetContact('📞', '+91 7678677191'),
                    const SizedBox(height: 8),
                    _sheetContact('✉️', 'kartikey.upadhyay@in.ey.com'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'FireShield AI™ · Powered by EY · Smart Fire Safety',
                style: FsText.tiny.copyWith(color: FsColors.subtle),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FsColors.gray900,
                    foregroundColor: FsColors.heroYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetContact(String icon, String label) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FsRadius.xl),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      );
}
