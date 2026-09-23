import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/regulation_engine.dart';

class RegisterOrgScreen extends StatefulWidget {
  const RegisterOrgScreen({super.key});
  @override
  State<RegisterOrgScreen> createState() => _State();
}

class _State extends State<RegisterOrgScreen> {
  int _step = 0;
  final _pageCtrl = PageController();

  // Step 1 — Organisation Details
  final _orgName       = TextEditingController();
  String _industry     = 'Real Estate & Commercial';
  String _bizCategory  = 'Private Limited Company';
  final _gst           = TextEditingController();
  final _pan           = TextEditingController();
  final _cin           = TextEditingController();
  final _email         = TextEditingController();
  final _website       = TextEditingController();
  final _address       = TextEditingController();
  String _state        = 'Karnataka';
  final String _district     = 'Bengaluru Urban';
  final _city          = TextEditingController();
  final _pin           = TextEditingController();
  final _emergency     = TextEditingController();
  final _coordinator   = TextEditingController();
  final _nodal         = TextEditingController();

  // Step 2 — Building Classification
  final _facilityName  = TextEditingController();
  final _buildingName  = TextEditingController();
  String _buildingType = 'shopping_mall';
  String _ownershipType= 'Owned';

  // Step 3 — Building Information
  final _plotNo        = TextEditingController();
  final _surveyNo      = TextEditingController();
  final _ctsNo         = TextEditingController();
  final _ward          = TextEditingController();
  final _zone          = TextEditingController();
  final _fireStnDist   = TextEditingController();
  final _lat           = TextEditingController();
  final _lng           = TextEditingController();
  final _builtArea     = TextEditingController();
  final _floors        = TextEditingController();
  final _basements     = TextEditingController();
  final _occupancy     = TextEditingController();
  final _footfall      = TextEditingController();

  // Step 4 — Fire Systems (checkboxes)
  final Map<String, bool> _systems = {
    'Fire Extinguishers': true,
    'Internal Hydrant System': true,
    'Automatic Sprinkler System': false,
    'Electric Fire Pump': true,
    'Diesel Backup Pump': true,
    'Jockey Pump': false,
    'Smoke Detection System': true,
    'Addressable Fire Alarm (FACP)': true,
    'Emergency Lighting': true,
    'Exit Signage': true,
    'Public Address System': false,
    'Fire Command Centre': false,
    'Refuge Area': false,
    'Staircase Pressurisation': false,
    'Smoke Exhaust System': false,
  };

  // Step 5 — NOC Details
  bool _nocAvailable = true;
  final _nocNo        = TextEditingController(text: 'KSFES/NOC/2026/0412');
  final _nocIssue     = TextEditingController(text: '27 Mar 2026');
  final _nocExpiry    = TextEditingController(text: '27 Mar 2027');
  String _nocAuthority= 'KSFES Bengaluru';

  // Step 6 — Documents
  final Map<String, String> _docStatus = {
    'Fire NOC': 'Uploaded',
    'Approved Fire Plan': 'Uploaded',
    'Architectural Drawings': 'Pending',
    'Fire Floor Plans': 'Uploaded',
    'CAD Files': 'Pending',
    'BIM Files': 'Pending',
    'Occupancy Certificate': 'Uploaded',
    'Electrical Safety Certificate': 'Expired',
    'Emergency Response Plan': 'Uploaded',
    'Evacuation Plan': 'Pending',
  };

  // Step 7 — Review
  final _appNo = 'FSA/KA/REG/2026/${DateTime.now().millisecond.toString().padLeft(5, '0')}';
  bool _submitted = false;

  static const _steps = [
    'Organisation\nDetails',
    'Building\nClassification',
    'Building\nInformation',
    'Fire\nSystems',
    'NOC\nDetails',
    'Documents',
    'Review &\nSubmit',
  ];

  static const _industries = ['Real Estate & Commercial', 'Healthcare & Hospitals', 'Information Technology', 'Manufacturing & EPC', 'Education', 'Ports & Logistics', 'Defence & Government', 'Retail', 'Hospitality', 'Banking & Finance'];
  static const _bizCategories = ['Private Limited Company', 'Public Limited Company', 'Partnership Firm', 'LLP', 'Government Body', 'Trust / Society', 'Sole Proprietorship'];
  static const _states = ['Karnataka', 'Maharashtra', 'Tamil Nadu', 'Gujarat', 'Delhi', 'Telangana', 'Uttar Pradesh', 'Rajasthan', 'Madhya Pradesh', 'Punjab'];
  static const _nocAuthorities = ['KSFES Bengaluru', 'MBFS Mumbai', 'TNFR Chennai', 'DGFS Delhi', 'GFS Gujarat', 'TFS Telangana'];
  static const _ownershipTypes = ['Owned', 'Leased', 'Government Allotted', 'Joint Venture'];

  void _next() {
    if (_step < 6) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildAcknowledgement();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(context, title: 'Register Organisation', showBack: true),
      body: Column(children: [
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
              _buildStep4(),
              _buildStep5(),
              _buildStep6(),
              _buildStep7(),
            ],
          ),
        ),
        _buildNavButtons(),
      ]),
    );
  }

  Widget _buildStepIndicator() => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_steps.length, (i) {
          final done = i < _step;
          final active = i == _step;
          return Row(children: [
            Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: done ? AppColors.success : active ? AppColors.primary : AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: Center(child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.textHint))),
              ),
              const SizedBox(height: 4),
              SizedBox(width: 52, child: Text(_steps[i], style: AppTextStyles.overline.copyWith(fontSize: 9, color: active ? AppColors.primary : done ? AppColors.success : AppColors.textHint), textAlign: TextAlign.center)),
            ]),
            if (i < _steps.length - 1)
              Container(width: 16, height: 1, color: i < _step ? AppColors.success : AppColors.borderLight, margin: const EdgeInsets.only(bottom: 20)),
          ]);
        }),
      ),
    ),
  );

  Widget _buildNavButtons() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderLight))),
    child: Row(children: [
      if (_step > 0) Expanded(child: OutlinedButton(
        onPressed: _prev,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: const Text('Back'),
      )),
      if (_step > 0) const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(
        onPressed: _step == 6 ? () => setState(() => _submitted = true) : _next,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(_step == 6 ? 'Submit Application' : 'Continue'),
      )),
    ]),
  );

  // ─── Step 1 — Organisation Details ───────────────────────────────────────
  Widget _buildStep1() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('Organisation Details', 'Legal entity information and contact details'),
      _field('Organisation Name *', _orgName, hint: 'e.g. Phoenix Malls Pvt. Ltd.'),
      _dropdown('Industry Type *', _industry, _industries, (v) => setState(() => _industry = v!)),
      _dropdown('Business Category *', _bizCategory, _bizCategories, (v) => setState(() => _bizCategory = v!)),
      _sectionTitle('Legal Identifiers'),
      _field('GST Number', _gst, hint: '29AACCP1234M1Z5'),
      _field('PAN Number', _pan, hint: 'AACCP1234M'),
      _field('CIN Number', _cin, hint: 'U45200KA2003PLC031683'),
      _sectionTitle('Contact Information'),
      _field('Corporate Email *', _email, hint: 'safety@organization.in', keyboard: TextInputType.emailAddress),
      _field('Website', _website, hint: 'https://www.organization.in'),
      _sectionTitle('Registered Address'),
      _field('Street / Locality *', _address, hint: 'Building No, Street Name, Area', maxLines: 2),
      _dropdown('State *', _state, _states, (v) => setState(() => _state = v!)),
      _field('District *', TextEditingController(text: _district), hint: 'e.g. Bengaluru Urban'),
      _field('City *', _city, hint: 'e.g. Bengaluru'),
      _field('PIN Code *', _pin, hint: '560001', keyboard: TextInputType.number),
      _sectionTitle('Key Personnel'),
      _field('Emergency Contact Number *', _emergency, hint: '+91 98765 43210', keyboard: TextInputType.phone),
      _field('Emergency Coordinator Name *', _coordinator, hint: 'Full name'),
      _field('Nodal Officer Name', _nodal, hint: 'Compliance nodal officer'),
    ]),
  );

  // ─── Step 2 — Building Classification ────────────────────────────────────
  Widget _buildStep2() {
    final btypes = RegulationEngine.getAllBuildingTypes();
    final cfg = RegulationEngine.getBuildingConfig(_buildingType);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stepHeader('Building Classification', 'Facility and building type — drives checklist generation'),
        _field('Facility Name *', _facilityName, hint: 'e.g. Phoenix Marketcity Bengaluru'),
        _field('Building Name *', _buildingName, hint: 'e.g. Main Tower A'),
        _sectionTitle('Building Type & Occupancy'),
        DropdownButtonFormField<String>(
          initialValue: _buildingType,
          decoration: _dec('Building Type *'),
          items: btypes.map((b) => DropdownMenuItem(value: b['key'], child: Text(b['label']!, style: AppTextStyles.bodyMedium))).toList(),
          onChanged: (v) => setState(() => _buildingType = v!),
        ),
        const SizedBox(height: 12),
        if (cfg != null) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NBC Classification', style: AppTextStyles.label.copyWith(color: AppColors.info, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            InfoRow(label: 'Occupancy Group', value: 'Group ${cfg['occupancyGroup']} — ${cfg['nbcCategory']}'),
            InfoRow(label: 'Min Exits', value: '${cfg['minExits']} exits (min ${cfg['exitWidthM']}m width)'),
            InfoRow(label: 'Applicable Standards', value: (cfg['applicableStandards'] as List).join(', '), isLast: true),
          ]),
        ),
        const SizedBox(height: 12),
        _dropdown('Primary Building Use *', cfg?['nbcCategory'] as String? ?? 'Commercial', ['Commercial', 'Institutional', 'Industrial', 'Assembly', 'Business', 'Mercantile', 'Mixed Use'], (v) {}),
        _dropdown('Ownership Type *', _ownershipType, _ownershipTypes, (v) => setState(() => _ownershipType = v!)),
      ]),
    );
  }

  // ─── Step 3 — Building Information ───────────────────────────────────────
  Widget _buildStep3() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('Building Information', 'Plot details, dimensions and location'),
      _sectionTitle('Survey & Plot Details'),
      _field('Plot Number', _plotNo, hint: 'Plot / Khasra No.'),
      _field('Survey Number', _surveyNo, hint: 'Survey / Gat No.'),
      _field('CTS Number', _ctsNo, hint: 'City Survey No.'),
      _field('Ward', _ward, hint: 'Ward No. / Name'),
      _field('Zone', _zone, hint: 'Planning Zone'),
      _sectionTitle('Emergency Response'),
      _field('Distance from Fire Station (km)', _fireStnDist, hint: '3.2', keyboard: TextInputType.number),
      _sectionTitle('GPS Coordinates'),
      Row(children: [
        Expanded(child: _field('Latitude *', _lat, hint: '12.9945', keyboard: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _field('Longitude *', _lng, hint: '77.6972', keyboard: TextInputType.number)),
      ]),
      _sectionTitle('Building Dimensions'),
      _field('Built-Up Area (sqft) *', _builtArea, hint: '7,50,000', keyboard: TextInputType.number),
      Row(children: [
        Expanded(child: _field('No. of Floors *', _floors, hint: '4', keyboard: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _field('No. of Basements', _basements, hint: '2', keyboard: TextInputType.number)),
      ]),
      _sectionTitle('Occupancy'),
      _field('Max Occupancy Capacity *', _occupancy, hint: '35,000', keyboard: TextInputType.number),
      _field('Average Daily Footfall', _footfall, hint: '15,000', keyboard: TextInputType.number),
      _sectionTitle('Special Areas'),
      _checkRow('Critical Areas Present (ICU, Data Room, DG Room)', true),
      _checkRow('Special Hazard Areas (Kitchen, Chemical Store, Fuel Storage)', false),
    ]),
  );

  // ─── Step 4 — Fire Systems ────────────────────────────────────────────────
  Widget _buildStep4() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('Fire Systems Installed', 'Select all fire safety systems present in the facility'),
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Checklist is auto-generated based on selected systems and building type.', style: AppTextStyles.caption.copyWith(color: AppColors.warning))),
        ]),
      ),
      ..._systems.entries.map((e) => _systemToggle(e.key, e.value)),
    ]),
  );

  // ─── Step 5 — NOC Details ─────────────────────────────────────────────────
  Widget _buildStep5() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('NOC Details', 'Fire No-Objection Certificate information'),
      _switchRow('Fire NOC Available', _nocAvailable, (v) => setState(() => _nocAvailable = v)),
      if (_nocAvailable) ...[
        _field('NOC Number *', _nocNo),
        _field('Issue Date *', _nocIssue, hint: 'DD MMM YYYY'),
        _field('Expiry Date *', _nocExpiry, hint: 'DD MMM YYYY'),
        _dropdown('Issuing Authority *', _nocAuthority, _nocAuthorities, (v) => setState(() => _nocAuthority = v!)),
        _sectionTitle('Inspection History'),
        _field('Previous Inspection Date', TextEditingController(text: '15 Feb 2026'), hint: 'DD MMM YYYY'),
        _sectionTitle('Deficiency History'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('No deficiency history on record', style: AppTextStyles.bodySmall)),
          ]),
        ),
      ] else Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⚠️ NOC Required', style: AppTextStyles.h6.copyWith(color: AppColors.error)),
          const SizedBox(height: 4),
          Text('A valid Fire NOC is mandatory to operate this facility. Initiate the NOC application process immediately.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ]),
      ),
    ]),
  );

  // ─── Step 6 — Documents ──────────────────────────────────────────────────
  Widget _buildStep6() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('Document Upload', 'Upload all required compliance documents'),
      ..._docStatus.entries.map((e) => _docRow(e.key, e.value)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
        child: Text('Accepted formats: PDF, CAD (.dwg), BIM (.rvt), JPG, PNG. Max 50 MB per file.', style: AppTextStyles.caption.copyWith(color: AppColors.info)),
      ),
    ]),
  );

  // ─── Step 7 — Review & Submit ─────────────────────────────────────────────
  Widget _buildStep7() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('Review & Submit', 'Verify all details before submitting'),
      _reviewSection('Organisation', {
        'Name': _orgName.text.isNotEmpty ? _orgName.text : 'Phoenix Malls Pvt. Ltd.',
        'Industry': _industry,
        'GST': _gst.text.isNotEmpty ? _gst.text : '29AACCP1234M1Z5',
        'Email': _email.text.isNotEmpty ? _email.text : 'compliance@phoenixmalls.com',
        'State': _state,
      }),
      _reviewSection('Building', {
        'Facility Name': _facilityName.text.isNotEmpty ? _facilityName.text : 'Phoenix Marketcity Bengaluru',
        'Building Type': RegulationEngine.getBuildingConfig(_buildingType)?['label'] as String? ?? _buildingType,
        'Floors': _floors.text.isNotEmpty ? _floors.text : '4',
        'Basements': _basements.text.isNotEmpty ? _basements.text : '3',
        'Occupancy': _occupancy.text.isNotEmpty ? _occupancy.text : '35,000',
      }),
      _reviewSection('NOC', {
        'Status': _nocAvailable ? 'Valid' : 'Not Available',
        'NOC Number': _nocNo.text,
        'Expiry': _nocExpiry.text,
        'Authority': _nocAuthority,
      }),
      _reviewSection('Documents', {
        'Uploaded': '${_docStatus.values.where((v) => v == "Uploaded").length} of ${_docStatus.length}',
        'Pending': '${_docStatus.values.where((v) => v == "Pending").length} documents',
        'Expired': '${_docStatus.values.where((v) => v == "Expired").length} document',
      }),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Application Number', style: AppTextStyles.label),
          const SizedBox(height: 2),
          Text(_appNo, style: AppTextStyles.h5.copyWith(color: AppColors.primary, fontFamily: 'monospace')),
          const SizedBox(height: 6),
          const Text('Generated on submission. Save this for reference.', style: AppTextStyles.caption),
        ]),
      ),
      const SizedBox(height: 12),
      const Row(children: [
        Icon(Icons.check_box_rounded, color: AppColors.success, size: 16),
        SizedBox(width: 8),
        Expanded(child: Text('I declare that all information provided is true and accurate.', style: AppTextStyles.bodySmall)),
      ]),
    ]),
  );

  // ─── Acknowledgement ─────────────────────────────────────────────────────
  Widget _buildAcknowledgement() => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          const Text('Registration Submitted', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Your organisation has been registered on FireShield AI.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
            child: Column(children: [
              InfoRow(label: 'Application No.', value: _appNo),
              InfoRow(label: 'Organisation', value: _orgName.text.isNotEmpty ? _orgName.text : 'Phoenix Malls Pvt. Ltd.'),
              const InfoRow(label: 'Submitted On', value: '22 Jun 2026, 10:41 AM'),
              const InfoRow(label: 'Status', value: 'Under Review', valueColor: AppColors.warning),
              const InfoRow(label: 'Next Step', value: 'Login credentials will be sent to registered email within 24 hours', isLast: true),
            ]),
          ),
          const SizedBox(height: 24),
          // Timeline
          _timelineStep('Application Submitted', '22 Jun 2026', true),
          _timelineStep('Document Verification', '23–24 Jun 2026', false),
          _timelineStep('Organisation Admin Created', '25 Jun 2026', false),
          _timelineStep('Platform Access Granted', '25 Jun 2026', false),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Return to Dashboard'),
          ),
        ]),
      ),
    ),
  );

  Widget _timelineStep(String label, String date, bool done) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: done ? AppColors.success : AppColors.borderLight, shape: BoxShape.circle),
        child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: done ? AppColors.textPrimary : AppColors.textHint))),
      Text(date, style: AppTextStyles.caption),
    ]),
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _stepHeader(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Step ${_step + 1} of 7', style: AppTextStyles.overline.copyWith(color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(title, style: AppTextStyles.h4),
      const SizedBox(height: 4),
      Text(subtitle, style: AppTextStyles.bodySmall),
    ]),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
  );

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  Widget _dropdown<T>(String label, T value, List<T> items, void Function(T?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _dec(label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: AppTextStyles.bodyMedium))).toList(),
      onChanged: onChanged,
    ),
  );

  Widget _checkRow(String label, bool val) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(val ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: val ? AppColors.primary : AppColors.textHint, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
    ]),
  );

  Widget _systemToggle(String name, bool val) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: val ? AppColors.primaryLight : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: val ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight),
    ),
    child: SwitchListTile(
      value: val,
      title: Text(name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: val ? FontWeight.w600 : FontWeight.w400)),
      activeThumbColor: AppColors.primary,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onChanged: (v) => setState(() => _systems[name] = v),
    ),
  );

  Widget _switchRow(String label, bool val, ValueChanged<bool> onChanged) => SwitchListTile(
    value: val,
    title: Text(label, style: AppTextStyles.bodyMedium),
    activeThumbColor: AppColors.primary,
    contentPadding: EdgeInsets.zero,
    onChanged: onChanged,
  );

  Widget _docRow(String name, String status) {
    final (icon, color) = switch (status) {
      'Uploaded' => (Icons.check_circle_rounded, AppColors.success),
      'Expired'  => (Icons.error_rounded,        AppColors.error),
      _          => (Icons.upload_file_rounded,   AppColors.textHint),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
        TextButton(
          onPressed: () => setState(() => _docStatus[name] = 'Uploaded'),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(status == 'Uploaded' ? 'View' : 'Upload', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _reviewSection(String title, Map<String, String> data) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.h6),
      const Divider(height: 16),
      ...data.entries.toList().asMap().entries.map((e) => InfoRow(label: e.value.key, value: e.value.value, isLast: e.key == data.length - 1)),
    ]),
  );
}
