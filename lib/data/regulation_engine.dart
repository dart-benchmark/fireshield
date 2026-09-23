/// FireShield AI — Configuration-Driven Regulation Engine
///
/// All regulations are stored as data (Map/List), not code.
/// Adding a new regulation = adding a new entry to the data maps below.
/// No code changes. No redevelopment.
///
/// Sources: NBC 2016 Part 4, IS 2189, IS 15105, IS 2190, IS 3844, OISD-116, PESO
library;

// ─── Regulation Master ─────────────────────────────────────────────────────
const List<Map<String, dynamic>> regulationMaster = [
  {
    'id': 'NBC_2016_P4',
    'code': 'NBC 2016 Part 4',
    'fullName': 'National Building Code of India 2016 — Part 4: Fire and Life Safety',
    'authority': 'Bureau of Indian Standards (BIS)',
    'applicableFrom': '2016-01-01',
    'status': 'ACTIVE',
    'type': 'NATIONAL',
    'url': 'https://bis.gov.in',
  },
  {
    'id': 'IS_2189',
    'code': 'IS 2189:2008',
    'fullName': 'Selection, Installation and Maintenance of First-Aid Fire Extinguishing Equipment',
    'authority': 'Bureau of Indian Standards',
    'applicableFrom': '2008-01-01',
    'status': 'ACTIVE',
    'type': 'STANDARD',
    'url': 'https://bis.gov.in',
  },
  {
    'id': 'IS_15105',
    'code': 'IS 15105:2002',
    'fullName': 'Design and Installation of Fixed Automatic Sprinkler Fire Extinguishing Systems',
    'authority': 'Bureau of Indian Standards',
    'applicableFrom': '2002-01-01',
    'status': 'ACTIVE',
    'type': 'STANDARD',
  },
  {
    'id': 'IS_2190',
    'code': 'IS 2190:2010',
    'fullName': 'Code of Practice for Selection, Installation and Maintenance of First-Aid Fire Extinguishing Equipment',
    'authority': 'Bureau of Indian Standards',
    'applicableFrom': '2010-01-01',
    'status': 'ACTIVE',
    'type': 'STANDARD',
  },
  {
    'id': 'IS_3844',
    'code': 'IS 3844:1989',
    'fullName': 'Code of Practice for Installation and Maintenance of Internal Hydrant and Hose Reel Systems',
    'authority': 'Bureau of Indian Standards',
    'applicableFrom': '1989-01-01',
    'status': 'ACTIVE',
    'type': 'STANDARD',
  },
  {
    'id': 'IS_1944',
    'code': 'IS 1944',
    'fullName': 'Code of Practice for Lighting of Buildings — Emergency Lighting',
    'authority': 'Bureau of Indian Standards',
    'applicableFrom': '1970-01-01',
    'status': 'ACTIVE',
    'type': 'STANDARD',
  },
  {
    'id': 'OISD_116',
    'code': 'OISD-116',
    'fullName': 'Fire Protection Facilities for Petroleum Refineries and Oil/Gas Processing Plants',
    'authority': 'Oil Industry Safety Directorate (OISD), Ministry of Petroleum',
    'applicableFrom': '1993-01-01',
    'status': 'ACTIVE',
    'type': 'SECTOR_SPECIFIC',
  },
  {
    'id': 'PESO_RULES',
    'code': 'PESO Rules',
    'fullName': 'Petroleum & Explosives Safety Organisation — Gas Cylinder Rules, SMPV Rules',
    'authority': 'PESO, Ministry of Commerce & Industry',
    'applicableFrom': '2016-01-01',
    'status': 'ACTIVE',
    'type': 'REGULATORY',
  },
  {
    'id': 'NBC_2016_P4_AMD1',
    'code': 'NBC 2016 Part 4 — Amendment 1',
    'fullName': 'National Building Code of India 2016 Part 4 — Amendment 1 (High-Rise Buildings)',
    'authority': 'Bureau of Indian Standards (BIS)',
    'applicableFrom': '2020-06-01',
    'status': 'ACTIVE',
    'type': 'AMENDMENT',
  },
];

// ─── Building Type Mapping ─────────────────────────────────────────────────
const Map<String, Map<String, dynamic>> buildingTypeMapping = {
  'shopping_mall': {
    'label': 'Shopping Mall / Retail Complex',
    'occupancyGroup': 'F',
    'nbcCategory': 'Mercantile',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105', 'IS_3844', 'IS_1944'],
    'mandatorySystems': ['sprinkler', 'hydrant', 'fire_alarm', 'emergency_lighting', 'pa_system', 'fire_pump'],
    'minExits': 4,
    'exitWidthM': 2.0,
    'sprinklerThresholdSqm': 500,
    'highRiseThresholdM': 15.0,
  },
  'hospital': {
    'label': 'Hospital / Healthcare Facility',
    'occupancyGroup': 'B',
    'nbcCategory': 'Institutional',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105', 'IS_3844', 'IS_1944'],
    'mandatorySystems': ['sprinkler', 'hydrant', 'fire_alarm', 'emergency_lighting', 'pa_system', 'fire_pump', 'fire_doors'],
    'minExits': 2,
    'exitWidthM': 1.8,
    'sprinklerThresholdSqm': 300,
    'specialRequirements': ['horizontal_evacuation', 'compartmentation', 'fire_command_centre'],
  },
  'it_campus': {
    'label': 'IT Park / Office Complex',
    'occupancyGroup': 'E',
    'nbcCategory': 'Business',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105', 'IS_3844'],
    'mandatorySystems': ['fire_alarm', 'hydrant', 'emergency_lighting', 'fire_pump'],
    'minExits': 2,
    'exitWidthM': 1.5,
    'sprinklerThresholdSqm': 1000,
  },
  'industrial': {
    'label': 'Industrial / Manufacturing Plant',
    'occupancyGroup': 'G',
    'nbcCategory': 'Industrial',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'OISD_116', 'PESO_RULES', 'IS_3844'],
    'mandatorySystems': ['hydrant', 'foam_system', 'fire_alarm', 'fire_pump', 'emergency_lighting'],
    'minExits': 2,
    'exitWidthM': 2.0,
    'hasHazardous': true,
  },
  'school': {
    'label': 'Educational Building',
    'occupancyGroup': 'B',
    'nbcCategory': 'Institutional',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_1944'],
    'mandatorySystems': ['fire_alarm', 'emergency_lighting', 'fire_extinguishers'],
    'minExits': 2,
    'exitWidthM': 1.5,
    'drillFrequencyMonths': 6,
  },
  'hotel': {
    'label': 'Hotel / Hospitality',
    'occupancyGroup': 'A',
    'nbcCategory': 'Residential (Transient)',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105', 'IS_3844', 'IS_1944'],
    'mandatorySystems': ['sprinkler', 'hydrant', 'fire_alarm', 'emergency_lighting', 'pa_system'],
    'minExits': 2,
    'exitWidthM': 1.5,
    'sprinklerThresholdSqm': 500,
  },
  'data_centre': {
    'label': 'Data Centre / Server Farm',
    'occupancyGroup': 'E',
    'nbcCategory': 'Business / Special',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105'],
    'mandatorySystems': ['gas_suppression', 'vhf_detection', 'fire_alarm', 'emergency_lighting'],
    'minExits': 2,
    'exitWidthM': 1.2,
    'specialRequirements': ['clean_agent_suppression', 'epo_system', 'smoke_detection_array'],
  },
  'airport': {
    'label': 'Airport Terminal',
    'occupancyGroup': 'D',
    'nbcCategory': 'Assembly',
    'applicableStandards': ['NBC_2016_P4', 'IS_2189', 'IS_15105', 'IS_3844', 'IS_1944'],
    'mandatorySystems': ['sprinkler', 'hydrant', 'foam_system', 'fire_alarm', 'pa_system', 'fire_pump'],
    'minExits': 6,
    'exitWidthM': 3.0,
    'specialRequirements': ['dgca_approval', 'arff_coordination'],
  },
};

// ─── Checklist Templates ──────────────────────────────────────────────────
const List<Map<String, dynamic>> checklistTemplates = [
  {
    'templateId': 'TPL_MALL_STD',
    'buildingType': 'shopping_mall',
    'version': '3.1',
    'effectiveDate': '2026-01-01',
    'sections': [
      {
        'id': 'S01',
        'title': 'Fire Exits & Evacuation Routes',
        'regulation': 'NBC 2016 Cl. 4.9',
        'weight': 20,
        'passMark': 80,
        'requirements': [
          {'id': 'S01R01', 'text': 'All fire exits clearly marked with illuminated exit signs', 'severity': 'CRITICAL', 'standard': 'NBC 2016 Cl. 4.9.1'},
          {'id': 'S01R02', 'text': 'Exit routes free from obstruction and combustible materials', 'severity': 'CRITICAL', 'standard': 'NBC 2016 Cl. 4.9.2'},
          {'id': 'S01R03', 'text': 'Fire exit doors open in direction of escape (min 2.0m width)', 'severity': 'MAJOR', 'standard': 'NBC 2016 Cl. 4.9.4'},
          {'id': 'S01R04', 'text': 'Staircase doors self-closing and fire rated (min 2hr)', 'severity': 'MAJOR', 'standard': 'NBC 2016 Cl. 4.7.3'},
          {'id': 'S01R05', 'text': 'Emergency lighting functional in all exit routes (min 90 min)', 'severity': 'MAJOR', 'standard': 'IS 1944'},
          {'id': 'S01R06', 'text': 'Assembly points identified and accessible (min 30m from building)', 'severity': 'MINOR', 'standard': 'NBC 2016 Cl. 4.9.8'},
        ],
      },
      {
        'id': 'S02',
        'title': 'Fire Detection & Alarm System',
        'regulation': 'IS 2189:2008',
        'weight': 20,
        'passMark': 80,
        'requirements': [
          {'id': 'S02R01', 'text': 'Fire alarm panel operational and showing normal status', 'severity': 'CRITICAL', 'standard': 'IS 2189 Cl. 7.1'},
          {'id': 'S02R02', 'text': 'All smoke detectors functional — monthly test log maintained', 'severity': 'MAJOR', 'standard': 'IS 2189 Cl. 8.2'},
          {'id': 'S02R03', 'text': 'Manual call points accessible and unobstructed (max 30m travel)', 'severity': 'MAJOR', 'standard': 'IS 2189 Cl. 9.1'},
          {'id': 'S02R04', 'text': 'Sounders/bells audible throughout entire building', 'severity': 'MAJOR', 'standard': 'IS 2189 Cl. 10.1'},
          {'id': 'S02R05', 'text': 'System has 24hr battery backup', 'severity': 'CRITICAL', 'standard': 'IS 2189 Cl. 7.4'},
        ],
      },
      {
        'id': 'S03',
        'title': 'Fire Suppression Systems',
        'regulation': 'IS 15105 / IS 3844',
        'weight': 20,
        'passMark': 75,
        'requirements': [
          {'id': 'S03R01', 'text': 'Sprinkler heads unobstructed and at correct spacing', 'severity': 'CRITICAL', 'standard': 'IS 15105 Cl. 6.2'},
          {'id': 'S03R02', 'text': 'Hydrant outlets accessible and hose reels in working condition', 'severity': 'MAJOR', 'standard': 'IS 3844 Cl. 5'},
          {'id': 'S03R03', 'text': 'Fire pump (electric + diesel backup) operational', 'severity': 'CRITICAL', 'standard': 'NBC 2016 Cl. 4.15.6'},
          {'id': 'S03R04', 'text': 'Water tank levels adequate (dedicated fire reserve)', 'severity': 'MAJOR', 'standard': 'NBC 2016 Cl. 4.15.4'},
        ],
      },
      {
        'id': 'S04',
        'title': 'Fire Extinguishers',
        'regulation': 'IS 2190:2010',
        'weight': 15,
        'passMark': 85,
        'requirements': [
          {'id': 'S04R01', 'text': 'Extinguishers placed at designated locations (max 15m travel for Class A)', 'severity': 'MAJOR', 'standard': 'IS 2190 Cl. 5.1'},
          {'id': 'S04R02', 'text': 'All extinguishers within annual service date', 'severity': 'CRITICAL', 'standard': 'IS 2190 Cl. 6.2'},
          {'id': 'S04R03', 'text': 'Correct type of extinguisher for hazard class', 'severity': 'MAJOR', 'standard': 'IS 2190 Cl. 4.1'},
          {'id': 'S04R04', 'text': 'Mounted at correct height — handle at 1.0–1.5m', 'severity': 'MINOR', 'standard': 'IS 2190 Cl. 5.3'},
        ],
      },
      {
        'id': 'S05',
        'title': 'Compliance & Documentation',
        'regulation': 'NBC 2016 / State Rules',
        'weight': 25,
        'passMark': 90,
        'requirements': [
          {'id': 'S05R01', 'text': 'Valid Fire NOC displayed and not expired', 'severity': 'CRITICAL', 'standard': 'State Fire Rules'},
          {'id': 'S05R02', 'text': 'AMC certificates valid for all fire systems', 'severity': 'MAJOR', 'standard': 'NBC 2016 Cl. 5.1'},
          {'id': 'S05R03', 'text': 'Evacuation drill conducted in last 6 months — records available', 'severity': 'MAJOR', 'standard': 'NBC 2016 Cl. 4.13'},
          {'id': 'S05R04', 'text': 'Fire Safety Officer appointed and registered', 'severity': 'MAJOR', 'standard': 'State Fire Act'},
          {'id': 'S05R05', 'text': 'Approved fire plan and floor-wise evacuation plans displayed', 'severity': 'MINOR', 'standard': 'NBC 2016 Cl. 4.14'},
        ],
      },
    ],
  },
];

// ─── Recommendation Master ─────────────────────────────────────────────────
const List<Map<String, dynamic>> recommendationMaster = [
  {
    'id': 'REC_001',
    'triggerCondition': 'exit_blocked',
    'priority': 'CRITICAL',
    'title': 'Immediately clear blocked fire exit',
    'description': 'Blocked fire exits are a life-safety violation under NBC 2016 Cl. 4.9.2. Remove all obstructions immediately.',
    'standard': 'NBC 2016 Cl. 4.9.2',
    'estimatedCost': '₹0 (Housekeeping)',
    'timelinedays': 1,
    'authority': 'Fire Authority / Building Management',
  },
  {
    'id': 'REC_002',
    'triggerCondition': 'extinguisher_overdue',
    'priority': 'CRITICAL',
    'title': 'Service all overdue fire extinguishers',
    'description': 'Annual refilling and servicing is mandatory under IS 2190. Engage a BIS-licensed fire service contractor.',
    'standard': 'IS 2190 Cl. 6.2',
    'estimatedCost': '₹350–₹800 per unit',
    'timelinedays': 7,
    'authority': 'BIS-Licensed Fire Contractor',
  },
  {
    'id': 'REC_003',
    'triggerCondition': 'mcp_obstructed',
    'priority': 'MAJOR',
    'title': 'Ensure all MCPs are accessible',
    'description': 'Manual Call Points must have clear 1m access radius. No object within reach distance.',
    'standard': 'IS 2189 Cl. 9.1',
    'estimatedCost': '₹0–₹5,000 (Relocation if needed)',
    'timelinedays': 3,
    'authority': 'Fire Safety Officer',
  },
  {
    'id': 'REC_004',
    'triggerCondition': 'noc_expired',
    'priority': 'CRITICAL',
    'title': 'File NOC renewal application immediately',
    'description': 'Operating without a valid Fire NOC is a statutory violation. File renewal application with KSFES/MBFS/respective fire authority.',
    'standard': 'State Fire Services Act',
    'estimatedCost': 'Government fee: ₹5,000–₹50,000',
    'timelinedays': 14,
    'authority': 'State Fire Department',
  },
  {
    'id': 'REC_005',
    'triggerCondition': 'sprinkler_blocked',
    'priority': 'CRITICAL',
    'title': 'Remove all sprinkler head obstructions',
    'description': 'Clearance of 450mm below sprinkler head required per IS 15105. Renovation debris and stored items must be removed.',
    'standard': 'IS 15105 Cl. 6.2',
    'estimatedCost': '₹0 (Housekeeping)',
    'timelinedays': 1,
    'authority': 'Building Management / HSE Team',
  },
  {
    'id': 'REC_006',
    'triggerCondition': 'emergency_lighting_fail',
    'priority': 'MAJOR',
    'title': 'Replace/repair failed emergency lighting units',
    'description': 'Minimum 90-minute battery backup required on all exit routes. Defective units must be replaced immediately.',
    'standard': 'IS 1944 / NBC 2016',
    'estimatedCost': '₹2,000–₹8,000 per unit',
    'timelinedays': 7,
    'authority': 'Electrical Contractor / AMC Team',
  },
  {
    'id': 'REC_007',
    'triggerCondition': 'fire_door_defective',
    'priority': 'MAJOR',
    'title': 'Repair/replace defective fire door self-closer',
    'description': 'Self-closing fire doors are mandatory on staircase enclosures. Defective closers must be repaired by certified vendor.',
    'standard': 'NBC 2016 Cl. 4.7.3',
    'estimatedCost': '₹3,000–₹15,000 per door',
    'timelinedays': 14,
    'authority': 'Fire Door Certified Vendor',
  },
  {
    'id': 'REC_008',
    'triggerCondition': 'amc_expired',
    'priority': 'MAJOR',
    'title': 'Renew expired AMC for fire systems',
    'description': 'Annual Maintenance Contracts ensure fire systems remain operational and legally compliant. Renew with OEM or authorized vendor.',
    'standard': 'NBC 2016 Cl. 5.1',
    'estimatedCost': 'As per AMC terms',
    'timelinedays': 30,
    'authority': 'OEM / Authorized Service Provider',
  },
];

// ─── Regulation Engine ─────────────────────────────────────────────────────
class RegulationEngine {
  /// Get all regulations applicable to a building type
  static List<Map<String, dynamic>> getApplicableRegulations(String buildingType) {
    final mapping = buildingTypeMapping[buildingType];
    if (mapping == null) return regulationMaster;
    final ids = List<String>.from(mapping['applicableStandards'] as List);
    return regulationMaster.where((r) => ids.contains(r['id'])).toList();
  }

  /// Get checklist template for a building type
  static Map<String, dynamic>? getChecklistTemplate(String buildingType) {
    try {
      return checklistTemplates.firstWhere((t) => t['buildingType'] == buildingType);
    } catch (_) {
      return checklistTemplates.first; // fallback to mall template
    }
  }

  /// Get recommendations for a set of triggered conditions
  static List<Map<String, dynamic>> getRecommendations(List<String> conditions) {
    return recommendationMaster.where((r) => conditions.contains(r['triggerCondition'])).toList();
  }

  /// Get building type config
  static Map<String, dynamic>? getBuildingConfig(String buildingType) => buildingTypeMapping[buildingType];

  /// Get all building types (for dropdown)
  static List<Map<String, String>> getAllBuildingTypes() => buildingTypeMapping.entries
      .map((e) => {'key': e.key, 'label': e.value['label'] as String})
      .toList();

  /// Score a completed checklist section
  static double scoreSection(List<String> responses) {
    if (responses.isEmpty) return 0;
    final yes = responses.where((r) => r == 'YES').length;
    final answered = responses.where((r) => r != '').length;
    if (answered == 0) return 0;
    return (yes / answered) * 100;
  }

  /// Lookup a regulation by ID
  static Map<String, dynamic>? getRegulationById(String id) {
    try {
      return regulationMaster.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
