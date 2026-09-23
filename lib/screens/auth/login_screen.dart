import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  late AnimationController _anim;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _anim.dispose(); super.dispose(); }

  void _handleSignIn() {
    final email = _emailCtrl.text.trim().toLowerCase();
    final knownEmails = demoUsers.map((u) => u.email.toLowerCase()).toSet();
    if (email.isNotEmpty && !knownEmails.contains(email)) {
      _showAccountNotFound();
      return;
    }
    _showRolePicker();
  }

  void _showAccountNotFound() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
          child: const Icon(Icons.person_off_rounded, color: AppColors.error, size: 32),
        ),
        title: const Text('Account Not Found', style: AppTextStyles.h4, textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('No account exists for this email address on the Fire Audit Platform.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Contact Platform Administrator', style: AppTextStyles.label.copyWith(color: AppColors.info, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _contactRow(Icons.person_rounded, 'Kartikey Upadhyay'),
              const SizedBox(height: 4),
              _contactRow(Icons.phone_rounded, '7678677191'),
              const SizedBox(height: 4),
              _contactRow(Icons.email_rounded, 'kartikey.upadhyay@in.ey.com'),
            ]),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Try Another Email')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label) => Row(children: [
    Icon(icon, size: 13, color: AppColors.info),
    const SizedBox(width: 6),
    Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
  ]);

  void _showForgotPassword() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(Icons.lock_reset_rounded, color: AppColors.info, size: 36),
      title: const Text('Password Reset', style: AppTextStyles.h4, textAlign: TextAlign.center),
      content: Text('Password reset is managed by your organisation administrator.\n\nContact:\nkartikey.upadhyay@in.ey.com\n+91 76786 77191', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
    ),
  );

  void _showRolePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RolePickerSheet(onSelect: _loginAs),
    );
  }

  void _loginAs(MockUser user) async {
    Navigator.of(context).pop();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _loading = false);
    switch (user.role) {
      case 'Platform Admin': context.go('/admin', extra: user); break;
      case 'Safety Manager': context.go('/safety-manager', extra: user); break;
      case 'Auditor': context.go('/auditor', extra: user); break;
      case 'Government Officer': context.go('/government', extra: user); break;
      case 'Organisation Admin': context.go('/org-admin', extra: user); break;
      default: context.go('/safety-manager', extra: user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildAzureButton(),
                  const SizedBox(height: 32),
                  _buildDemoNote(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(children: [
    Container(
      width: 84, height: 84,
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))]),
      child: const Icon(Icons.local_fire_department_rounded, size: 44, color: Colors.white),
    ),
    const SizedBox(height: 20),
    const Text('FireShield AI', style: AppTextStyles.h2, textAlign: TextAlign.center),
    const SizedBox(height: 4),
    Text('Self Fire Audit Readiness & Compliance Platform', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
    const SizedBox(height: 2),
    Text('Developed by EY', style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        const Text('NBC 2016  ·  BIS  ·  OISD  ·  PESO  ·  DGCA', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
      ]),
    ),
  ]);

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Sign In', style: AppTextStyles.h3),
      const SizedBox(height: 6),
      Text('Access your compliance dashboard', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email Address', hintText: 'you@organization.in', prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary)),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passCtrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textSecondary), onPressed: () => setState(() => _obscure = !_obscure)),
        ),
      ),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPassword, child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 13)))),
      const SizedBox(height: 8),
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _handleSignIn,
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Sign In'),
        ),
      ),
    ],
  );

  Widget _buildDivider() => Row(children: [
    const Expanded(child: Divider()),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700))),
    const Expanded(child: Divider()),
  ]);

  Widget _buildAzureButton() => OutlinedButton.icon(
    onPressed: _loading ? null : _showRolePicker,
    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.border)),
    icon: Container(width: 20, height: 20, color: const Color(0xFF0078D4), child: const Icon(Icons.language, size: 14, color: Colors.white)),
    label: const Text('Continue with Microsoft / Azure AD', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
  );

  Widget _buildDemoNote() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.info),
        const SizedBox(width: 8),
        Text('Demo Mode', style: AppTextStyles.h6.copyWith(color: AppColors.info)),
      ]),
      const SizedBox(height: 8),
      Text('Tap Sign In to select a demo role and explore all modules.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.info)),
    ]),
  );
}

class _RolePickerSheet extends StatelessWidget {
  final void Function(MockUser) onSelect;
  const _RolePickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Select Demo Role', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text('Choose a user to explore different platform views', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...demoUsers.map((u) => _RoleTile(user: u, onTap: () => onSelect(u))),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final MockUser user;
  final VoidCallback onTap;
  const _RoleTile({required this.user, required this.onTap});

  Color get _roleColor => switch (user.role) {
    'Platform Admin' => AppColors.riskCritical,
    'Safety Manager' => AppColors.secondary,
    'Auditor' => AppColors.warning,
    'Government Officer' => AppColors.success,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _roleColor.withValues(alpha: 0.15),
        child: Text(user.photoInitials, style: TextStyle(color: _roleColor, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
      title: Text(user.name, style: AppTextStyles.h6),
      subtitle: Text('${user.role}  ·  ${user.facility}', style: AppTextStyles.caption),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
    );
  }
}
