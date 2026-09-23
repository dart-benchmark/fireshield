import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});
  @override
  State<CreateUserScreen> createState() => _State();
}

class _State extends State<CreateUserScreen> {
  String _role = 'Safety Manager';
  final _name        = TextEditingController();
  final _empId       = TextEditingController();
  final _designation = TextEditingController();
  final _department  = TextEditingController();
  final _email       = TextEditingController();
  final _mobile      = TextEditingController();
  final _qual        = TextEditingController();
  final _exp         = TextEditingController();
  String _facility   = 'Phoenix Marketcity Bengaluru';
  String _building   = 'Main Tower A';
  bool _submitted    = false;

  static const _roles       = ['Safety Manager', 'Auditor'];
  static const _facilities  = ['Phoenix Marketcity Bengaluru', 'Phoenix Mall of Asia', 'Phoenix One Bengaluru West'];
  static const _buildings   = ['Main Tower A', 'Main Tower B', 'Parking Block', 'Food Court Block', 'Multiplex Block'];
  static const _qualifications = ['Fire Safety Engineer', 'Diploma in Fire Safety', 'B.E. / B.Tech - Safety', 'NEBOSH Certificate', 'IOSH Certificate', 'Fire Inspector (State Board)', 'Other'];

  static const _floors = ['All Floors', 'Ground Floor', 'Basement 1', 'Basement 2', '1st Floor', '2nd Floor', '3rd Floor', '4th Floor', '5th Floor'];
  final Map<String, bool> _selectedFloors = {for (var f in _floors) f: false};

  void _submit() {
    if (_name.text.isEmpty || _email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(context, title: 'Create User', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _roleSelector(),
          const SizedBox(height: 20),
          _section('Personal Information'),
          _field('Full Name *', _name, hint: 'e.g. Arjun Sharma'),
          _field('Employee ID *', _empId, hint: 'e.g. SM-1001'),
          _field('Designation', _designation, hint: 'e.g. Deputy Safety Officer'),
          _field('Department', _department, hint: 'e.g. Safety & Compliance'),
          _section('Contact Details'),
          _field('Official Email *', _email, hint: 'employee@org.in', keyboard: TextInputType.emailAddress),
          _field('Mobile Number *', _mobile, hint: '+91 98765 43210', keyboard: TextInputType.phone),
          _section('Qualification & Experience'),
          _dropdown('Qualification *', _qual.text.isNotEmpty ? _qual.text : _qualifications[0], _qualifications, (v) => setState(() => _qual.text = v!)),
          _field('Years of Experience *', _exp, hint: '5', keyboard: TextInputType.number),
          _section('Facility Assignment'),
          _dropdown('Assigned Facility *', _facility, _facilities, (v) => setState(() => _facility = v!)),
          _dropdown('Primary Building', _building, _buildings, (v) => setState(() => _building = v!)),
          _section('Floor Access'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _floors.map((f) => FilterChip(
              label: Text(f, style: AppTextStyles.caption),
              selected: _selectedFloors[f]!,
              onSelected: (v) {
                setState(() {
                  if (f == 'All Floors') {
                    for (var k in _selectedFloors.keys) {
                      _selectedFloors[k] = v;
                    }
                  } else {
                    _selectedFloors[f] = v;
                  }
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
          _permissionsBox(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text('Create $_role'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Cancel'),
          ),
        ]),
      ),
    );
  }

  Widget _roleSelector() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Row(children: _roles.map((r) {
      final selected = r == _role;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _role = r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(r, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ),
      ));
    }).toList()),
  );

  Widget _permissionsBox() {
    final perms = _role == 'Safety Manager'
      ? ['View all facilities & buildings', 'Schedule audits', 'Assign tasks to auditors', 'View audit reports', 'Manage corrective actions', 'View equipment inventory']
      : ['Conduct site audits', 'Raise findings', 'Capture photographic evidence', 'Scan QR asset tags', 'Submit audit reports', 'View own audit history'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_rounded, color: AppColors.info, size: 16),
          const SizedBox(width: 6),
          Text('Default Permissions — $_role', style: AppTextStyles.label.copyWith(color: AppColors.info, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...perms.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            const Icon(Icons.check_rounded, color: AppColors.info, size: 14),
            const SizedBox(width: 8),
            Text(p, style: AppTextStyles.bodySmall),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSuccess() => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text('User Created', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('${_name.text} has been added as a $_role.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
              child: Column(children: [
                InfoRow(label: 'Name', value: _name.text),
                InfoRow(label: 'Role', value: _role),
                InfoRow(label: 'Employee ID', value: _empId.text.isNotEmpty ? _empId.text : 'Auto-generated'),
                InfoRow(label: 'Email', value: _email.text),
                InfoRow(label: 'Facility', value: _facility),
                const InfoRow(label: 'Status', value: 'Active — Credentials sent to email', isLast: true),
              ]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Dashboard'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() { _submitted = false; _name.clear(); _email.clear(); }),
              child: const Text('Create Another User'),
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
  );

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(controller: ctrl, keyboardType: keyboard, decoration: InputDecoration(labelText: label, hintText: hint)),
  );

  Widget _dropdown<T>(String label, T value, List<T> items, void Function(T?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: AppTextStyles.bodyMedium))).toList(),
      onChanged: onChanged,
    ),
  );
}
