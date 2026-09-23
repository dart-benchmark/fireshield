class MockUser {
  final String name, role, email, facility, employeeId, photoInitials, department;
  const MockUser({required this.name, required this.role, required this.email, required this.facility, required this.employeeId, required this.photoInitials, required this.department});
}

const demoUsers = [
  MockUser(name: 'Rajesh Kumar',    role: 'Safety Manager',    email: 'rajesh.kumar@refineryco.in',   facility: 'Jamnagar Refinery Complex',   employeeId: 'EMP-001', photoInitials: 'RK', department: 'HSE'),
  MockUser(name: 'Dr. Meena Patel', role: 'Safety Manager',    email: 'meena.patel@cityhospital.in',  facility: 'City Hospital Ahmedabad',      employeeId: 'EMP-002', photoInitials: 'MP', department: 'Administration'),
  MockUser(name: 'Arjun Singh',     role: 'Government Officer',email: 'arjun.singh@mfd.gov.in',       facility: 'Maharashtra Fire Department',  employeeId: 'GOV-001', photoInitials: 'AS', department: 'Fire Safety'),
  MockUser(name: 'Priya Nair',      role: 'Auditor',           email: 'priya.nair@auditcorp.in',      facility: 'Phoenix Mall Bengaluru',       employeeId: 'AUD-001', photoInitials: 'PN', department: 'Audit'),
  MockUser(name: 'Admin User',      role: 'Platform Admin',    email: 'admin@fireaudit.gov.in',       facility: 'All Facilities',               employeeId: 'ADM-001', photoInitials: 'AU', department: 'Administration'),
  MockUser(name: 'Vikram Mehta',    role: 'Organisation Admin', email: 'vikram.mehta@phoenixmalls.com', facility: 'All Phoenix Facilities',      employeeId: 'ORG-001', photoInitials: 'VM', department: 'Safety & Compliance'),
];

class MockFacility {
  final String id, name, type, location, state, nocStatus, riskLevel;
  final int compliance, totalFloors, occupancy;
  final double fri;
  final String lastAudit, nocExpiry;
  const MockFacility({required this.id, required this.name, required this.type, required this.location, required this.state, required this.nocStatus, required this.riskLevel, required this.compliance, required this.totalFloors, required this.occupancy, required this.fri, required this.lastAudit, required this.nocExpiry});
}

const mockFacilities = [
  MockFacility(id: 'F001', name: 'Jamnagar Refinery Complex', type: 'Refinery', location: 'Jamnagar, Gujarat', state: 'Gujarat', nocStatus: 'Valid', riskLevel: 'HIGH', compliance: 78, totalFloors: 4, occupancy: 2400, fri: 72.4, lastAudit: '12 May 2026', nocExpiry: '31 Mar 2027'),
  MockFacility(id: 'F002', name: 'City Hospital Ahmedabad', type: 'Hospital', location: 'Ahmedabad, Gujarat', state: 'Gujarat', nocStatus: 'Expiring Soon', riskLevel: 'MEDIUM', compliance: 85, totalFloors: 8, occupancy: 650, fri: 82.1, lastAudit: '08 Jun 2026', nocExpiry: '15 Jul 2026'),
  MockFacility(id: 'F003', name: 'Phoenix Mall Bengaluru', type: 'Shopping Mall', location: 'Bengaluru, Karnataka', state: 'Karnataka', nocStatus: 'Valid', riskLevel: 'MEDIUM', compliance: 91, totalFloors: 5, occupancy: 8000, fri: 89.3, lastAudit: '01 Jun 2026', nocExpiry: '28 Feb 2027'),
  MockFacility(id: 'F004', name: 'Delhi Public School Sector 19', type: 'School', location: 'Dwarka, Delhi', state: 'Delhi', nocStatus: 'Expired', riskLevel: 'CRITICAL', compliance: 52, totalFloors: 4, occupancy: 2200, fri: 48.6, lastAudit: '20 Mar 2026', nocExpiry: '31 May 2026'),
  MockFacility(id: 'F005', name: 'NPC Data Centre Noida', type: 'Data Centre', location: 'Noida, Uttar Pradesh', state: 'Uttar Pradesh', nocStatus: 'Valid', riskLevel: 'HIGH', compliance: 88, totalFloors: 6, occupancy: 320, fri: 87.2, lastAudit: '05 Jun 2026', nocExpiry: '30 Nov 2026'),
  MockFacility(id: 'F006', name: 'GVK Airport Terminal 2', type: 'Airport', location: 'Mumbai, Maharashtra', state: 'Maharashtra', nocStatus: 'Valid', riskLevel: 'HIGH', compliance: 94, totalFloors: 3, occupancy: 15000, fri: 93.1, lastAudit: '10 Jun 2026', nocExpiry: '30 Sep 2026'),
];

class MockAudit {
  final String id, auditNo, facilityName, facilityType, auditor, status, scheduledDate, type;
  final int totalItems, completed, compliant, nonCompliant, critical, major;
  final double score;
  const MockAudit({required this.id, required this.auditNo, required this.facilityName, required this.facilityType, required this.auditor, required this.status, required this.scheduledDate, required this.type, required this.totalItems, required this.completed, required this.compliant, required this.nonCompliant, required this.critical, required this.major, required this.score});
}

const mockAudits = [
  MockAudit(id: 'A001', auditNo: 'AUD-202606-001089', facilityName: 'Phoenix Mall Bengaluru', facilityType: 'Shopping Mall', auditor: 'Priya Nair', status: 'IN_PROGRESS', scheduledDate: '13 Jun 2026', type: 'Self Audit', totalItems: 148, completed: 64, compliant: 58, nonCompliant: 6, critical: 1, major: 3, score: 78.4),
  MockAudit(id: 'A002', auditNo: 'AUD-202606-001090', facilityName: 'City Hospital Ahmedabad', facilityType: 'Hospital', auditor: 'Priya Nair', status: 'SCHEDULED', scheduledDate: '15 Jun 2026', type: 'Pre-Inspection', totalItems: 186, completed: 0, compliant: 0, nonCompliant: 0, critical: 0, major: 0, score: 0),
  MockAudit(id: 'A003', auditNo: 'AUD-202605-001045', facilityName: 'Delhi Public School Sector 19', facilityType: 'School', auditor: 'Amit Sharma', status: 'SUBMITTED', scheduledDate: '20 May 2026', type: 'Self Audit', totalItems: 92, completed: 92, compliant: 48, nonCompliant: 44, critical: 8, major: 18, score: 52.2),
  MockAudit(id: 'A004', auditNo: 'AUD-202606-001088', facilityName: 'Jamnagar Refinery Complex', facilityType: 'Refinery', auditor: 'Vikram Rathore', status: 'APPROVED', scheduledDate: '10 Jun 2026', type: 'OISD Audit', totalItems: 224, completed: 224, compliant: 175, nonCompliant: 49, critical: 4, major: 15, score: 78.1),
];

class MockChecklistSection {
  final String id, title, standard;
  final int total, completed, nonCompliant;
  final List<MockChecklistItem> items;
  const MockChecklistSection({required this.id, required this.title, required this.standard, required this.total, required this.completed, required this.nonCompliant, required this.items});
}

class MockChecklistItem {
  final String id, question, standard, guidance, severity, response;
  final bool evidenceRequired, hasEvidence, isFlagged;
  const MockChecklistItem({required this.id, required this.question, required this.standard, required this.guidance, required this.severity, required this.response, this.evidenceRequired = false, this.hasEvidence = false, this.isFlagged = false});
}

const mockSections = [
  MockChecklistSection(
    id: 'S1', title: 'Fire Exits & Evacuation Routes', standard: 'NBC 2016 Cl. 4.9', total: 12, completed: 8, nonCompliant: 2,
    items: [
      MockChecklistItem(id: 'S1Q1', question: 'Are all fire exits clearly marked with illuminated exit signs?', standard: 'NBC 2016 Cl. 4.9.1', guidance: 'Exit signs shall be illuminated at all times. Check each floor.', severity: 'CRITICAL', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S1Q2', question: 'Are all exit routes free from obstruction and combustible materials?', standard: 'NBC 2016 Cl. 4.9.2', guidance: 'Minimum clear width of 1.5m required in all corridors.', severity: 'CRITICAL', response: 'NO', evidenceRequired: true, hasEvidence: true, isFlagged: true),
      MockChecklistItem(id: 'S1Q3', question: 'Do all fire exit doors open in the direction of escape?', standard: 'NBC 2016 Cl. 4.9.4', guidance: 'Outward opening required for assembly areas > 50 persons.', severity: 'MAJOR', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S1Q4', question: 'Are staircase doors self-closing and fire rated?', standard: 'NBC 2016 Cl. 4.7.3', guidance: 'Minimum 2-hour fire rating required for exit staircase doors.', severity: 'MAJOR', response: 'PARTIAL', evidenceRequired: true, hasEvidence: false, isFlagged: true),
      MockChecklistItem(id: 'S1Q5', question: 'Is emergency lighting functional in all exit routes?', standard: 'IS 1944 / NBC 2016', guidance: 'Minimum 90-min backup. Test monthly.', severity: 'MAJOR', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S1Q6', question: 'Are assembly points clearly identified and accessible?', standard: 'NBC 2016 Cl. 4.9.8', guidance: 'Assembly point signage at minimum 30m from building.', severity: 'MINOR', response: '', evidenceRequired: false, hasEvidence: false),
    ],
  ),
  MockChecklistSection(
    id: 'S2', title: 'Fire Extinguishers', standard: 'IS 2190 / NBC 2016', total: 18, completed: 18, nonCompliant: 1,
    items: [
      MockChecklistItem(id: 'S2Q1', question: 'Are fire extinguishers placed at designated locations as per layout?', standard: 'IS 2190 Cl. 5.1', guidance: 'Max travel distance of 15m for Class A and 9m for Class B hazards.', severity: 'MAJOR', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S2Q2', question: 'Are all extinguishers within service date? (Annual refilling/service)', standard: 'IS 2190 Cl. 6.2', guidance: 'Annual service mandatory. Check inspection tag on each unit.', severity: 'CRITICAL', response: 'NO', evidenceRequired: true, hasEvidence: true, isFlagged: true),
      MockChecklistItem(id: 'S2Q3', question: 'Are extinguishers mounted at correct height (handle at 1.0-1.5m)?', standard: 'IS 2190 Cl. 5.3', guidance: 'Height measured to handle. Not stored on floor.', severity: 'MINOR', response: 'YES', evidenceRequired: false, hasEvidence: false),
    ],
  ),
  MockChecklistSection(
    id: 'S3', title: 'Fire Detection & Alarm System', standard: 'IS 2189', total: 22, completed: 16, nonCompliant: 3,
    items: [
      MockChecklistItem(id: 'S3Q1', question: 'Is the fire alarm panel operational and showing normal status?', standard: 'IS 2189 Cl. 7.1', guidance: 'Check panel display, power supply, and battery backup.', severity: 'CRITICAL', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S3Q2', question: 'Are all smoke detectors functional? (Monthly test log maintained)', standard: 'IS 2189 Cl. 8.2', guidance: 'Visual inspection + functional test. Check test records.', severity: 'MAJOR', response: 'YES', evidenceRequired: true, hasEvidence: true),
      MockChecklistItem(id: 'S3Q3', question: 'Are manual call points accessible and unobstructed?', standard: 'IS 2189 Cl. 9.1', guidance: 'Max 30m travel to nearest MCP. Must be accessible.', severity: 'MAJOR', response: 'NO', evidenceRequired: true, hasEvidence: false, isFlagged: true),
    ],
  ),
];

class MockEquipment {
  final String id, type, location, make, serial, status, lastService, nextService, condition;
  final int floor;
  const MockEquipment({required this.id, required this.type, required this.location, required this.make, required this.serial, required this.status, required this.lastService, required this.nextService, required this.condition, required this.floor});
}

const mockEquipment = [
  MockEquipment(id: 'EQ001', type: 'Fire Extinguisher (ABC)', location: 'Lobby — Main Entrance', make: 'Safex', serial: 'SFX-2024-00412', status: 'OPERATIONAL', lastService: '15 Jan 2026', nextService: '15 Jan 2027', condition: 'Good', floor: 1),
  MockEquipment(id: 'EQ002', type: 'Fire Extinguisher (CO₂)', location: 'Server Room B-101', make: 'Minimax', serial: 'MMX-2023-00891', status: 'MAINTENANCE_DUE', lastService: '10 Dec 2024', nextService: '10 Dec 2025', condition: 'Overdue', floor: 1),
  MockEquipment(id: 'EQ003', type: 'Smoke Detector', location: 'Floor 2 — Corridor A', make: 'Hochiki', serial: 'HCK-SD-4421', status: 'OPERATIONAL', lastService: '01 Apr 2026', nextService: '01 Apr 2027', condition: 'Good', floor: 2),
  MockEquipment(id: 'EQ004', type: 'Hose Reel', location: 'Floor 3 — Staircase 2', make: 'Viking', serial: 'VKG-HR-0023', status: 'OPERATIONAL', lastService: '20 Feb 2026', nextService: '20 Feb 2027', condition: 'Good', floor: 3),
  MockEquipment(id: 'EQ005', type: 'Fire Alarm Panel', location: 'Security Room — Ground Floor', make: 'Notifier', serial: 'NTF-AFP-900', status: 'OPERATIONAL', lastService: '05 Mar 2026', nextService: '05 Mar 2027', condition: 'Good', floor: 0),
  MockEquipment(id: 'EQ006', type: 'Sprinkler Head', location: 'Basement Parking', make: 'Tyco', serial: 'TYC-SPK-7721', status: 'OPERATIONAL', lastService: '12 Apr 2026', nextService: '12 Apr 2027', condition: 'Good', floor: -1),
  MockEquipment(id: 'EQ007', type: 'Emergency Exit Light', location: 'Floor 1 — Corridor B', make: 'Philips', serial: 'PHL-EL-3301', status: 'DEFECTIVE', lastService: '01 Jan 2026', nextService: 'Immediate', condition: 'Defective', floor: 1),
  MockEquipment(id: 'EQ008', type: 'Fire Pump (Electric)', location: 'Pump Room — Basement', make: 'Grundfos', serial: 'GRF-FP-150HP', status: 'OPERATIONAL', lastService: '10 May 2026', nextService: '10 May 2027', condition: 'Good', floor: -1),
];

class MockCA {
  final String id, caNo, title, facility, severity, status, assignedTo, dueDate, standard, raisedDate;
  const MockCA({required this.id, required this.caNo, required this.title, required this.facility, required this.severity, required this.status, required this.assignedTo, required this.dueDate, required this.standard, required this.raisedDate});
}

const mockCAs = [
  MockCA(id: 'CA001', caNo: 'CA-202606-001034', title: 'Fire exit corridor blocked with stored boxes on Floor 2', facility: 'Phoenix Mall Bengaluru', severity: 'CRITICAL', status: 'OVERDUE', assignedTo: 'Suresh Babu', dueDate: '10 Jun 2026', standard: 'NBC 2016 Cl.4.9.2', raisedDate: '01 Jun 2026'),
  MockCA(id: 'CA002', caNo: 'CA-202606-001035', title: '6 fire extinguishers overdue for annual service on Floor 3', facility: 'Phoenix Mall Bengaluru', severity: 'CRITICAL', status: 'IN_PROGRESS', assignedTo: 'AMC Team — Safex', dueDate: '15 Jun 2026', standard: 'IS 2190 Cl.6.2', raisedDate: '01 Jun 2026'),
  MockCA(id: 'CA003', caNo: 'CA-202606-001036', title: 'Manual call point obstructed near food court entry', facility: 'Phoenix Mall Bengaluru', severity: 'MAJOR', status: 'OPEN', assignedTo: 'Priya Nair', dueDate: '20 Jun 2026', standard: 'IS 2189 Cl.9.1', raisedDate: '13 Jun 2026'),
  MockCA(id: 'CA004', caNo: 'CA-202605-000891', title: 'Fire NOC expired — renewal application not submitted', facility: 'Delhi Public School Sector 19', severity: 'CRITICAL', status: 'ESCALATED', assignedTo: 'Principal Office', dueDate: '31 May 2026', standard: 'Delhi Fire Service Act', raisedDate: '15 May 2026'),
  MockCA(id: 'CA005', caNo: 'CA-202606-001020', title: 'Staircase fire door self-closer mechanism defective — Floor 4', facility: 'City Hospital Ahmedabad', severity: 'MAJOR', status: 'PENDING_REVIEW', assignedTo: 'Maintenance Dept', dueDate: '18 Jun 2026', standard: 'NBC 2016 Cl.4.7.3', raisedDate: '08 Jun 2026'),
  MockCA(id: 'CA006', caNo: 'CA-202606-000998', title: 'Emergency exit sign not illuminated — B Wing 3rd Floor', facility: 'City Hospital Ahmedabad', severity: 'MAJOR', status: 'CLOSED', assignedTo: 'Electrical Dept', dueDate: '14 Jun 2026', standard: 'IS 1944', raisedDate: '05 Jun 2026'),
];

class MockNotification {
  final String id, title, body, time, type;
  final bool isRead;
  const MockNotification({required this.id, required this.title, required this.body, required this.time, required this.type, this.isRead = false});
}

const mockNotifications = [
  MockNotification(id: 'N1', title: '🔴 CRITICAL: CA Overdue — Phoenix Mall', body: 'CA-202606-001034: Fire exit corridor blocked. Overdue by 3 days. Immediate action required.', time: '2 hours ago', type: 'CA_OVERDUE', isRead: false),
  MockNotification(id: 'N2', title: '⚠️ Audit Assigned — City Hospital', body: 'You have been assigned a Pre-Inspection Audit at City Hospital Ahmedabad. Scheduled: 15 Jun 2026.', time: '5 hours ago', type: 'AUDIT_ASSIGNED', isRead: false),
  MockNotification(id: 'N3', title: '📋 Audit Submitted for Review', body: 'AUD-202606-001088 for Jamnagar Refinery has been submitted. Compliance Score: 78.1%', time: 'Yesterday', type: 'AUDIT_SUBMITTED', isRead: true),
  MockNotification(id: 'N4', title: '📅 Fire NOC Expiring — City Hospital', body: 'Fire NOC expires on 15 Jul 2026 (32 days remaining). Initiate renewal process.', time: 'Yesterday', type: 'NOC_EXPIRY', isRead: true),
  MockNotification(id: 'N5', title: '✅ CA Closed — City Hospital B Wing', body: 'CA-202606-000998: Emergency exit sign replaced and verified. Closed by Electrical Dept.', time: '2 days ago', type: 'CA_CLOSED', isRead: true),
];

class MockChatMessage {
  final String id, text, sender;
  final bool isUser;
  const MockChatMessage({required this.id, required this.text, required this.sender, required this.isUser});
}

final mockAiConversation = [
  const MockChatMessage(id: 'M1', text: "Hello! I'm the FireShield AI Compliance Reference Assistant. I can help you with NBC 2016 clauses, BIS standards, OISD requirements, Fire NOC queries, equipment compliance, and audit guidance. How can I assist you today?", sender: 'AI Assistant', isUser: false),
  const MockChatMessage(id: 'M2', text: "What is the minimum number of fire exits required for a shopping mall with occupancy of 8,000 persons as per NBC 2016?", sender: 'You', isUser: true),
  const MockChatMessage(id: 'M3', text: "As per **NBC 2016, Part 4, Clause 4.9.1** and **Table 10**, for an Assembly/Mercantile occupancy (Group D/F) with occupancy load of 8,000 persons:\n\n**Minimum Exits Required: 6**\n\n📌 Key Requirements:\n• Number of exits based on occupancy load (1 exit per 250 persons above 500)\n• No point on any floor should be more than **30m** from an exit\n• Each exit must have a minimum clear width of **2.0m** for occupancies > 1000\n• Exits must be remote from each other — min distance = diagonal × 0.33\n\n**Additional Requirements for High-Rise Malls (>15m):**\n• At least one smoke-proof enclosure staircase\n• Pressurised staircases as per Cl. 4.8.3\n• Fire lifts mandatory above 24m\n\nWould you like me to calculate the specific exit width requirements for your floor layout?", sender: 'AI Assistant', isUser: false),
];

// ─── Governance / Platform Admin Stats ───────────────────────────────────────
class GovernanceStats {
  static const totalOrgs         = 48;
  static const totalFacilities   = 312;
  static const totalBuildings    = 1084;
  static const totalUsers        = 924;
  static const totalOrgAdmins    = 48;
  static const totalManagers     = 214;
  static const totalAuditors     = 386;
  static const totalAudits       = 6843;

  static const stateWise = [
    {'state': 'Maharashtra',   'facilities': 68, 'orgs': 12},
    {'state': 'Karnataka',     'facilities': 54, 'orgs': 9},
    {'state': 'Tamil Nadu',    'facilities': 41, 'orgs': 7},
    {'state': 'Gujarat',       'facilities': 38, 'orgs': 6},
    {'state': 'Delhi',         'facilities': 34, 'orgs': 5},
    {'state': 'Telangana',     'facilities': 28, 'orgs': 4},
    {'state': 'Uttar Pradesh', 'facilities': 22, 'orgs': 3},
    {'state': 'Others',        'facilities': 27, 'orgs': 2},
  ];

  static const industryWise = [
    {'industry': 'Real Estate & Commercial', 'orgs': 14, 'facilities': 98},
    {'industry': 'Healthcare & Hospitals',   'orgs': 9,  'facilities': 72},
    {'industry': 'Information Technology',   'orgs': 8,  'facilities': 56},
    {'industry': 'Manufacturing & EPC',      'orgs': 7,  'facilities': 44},
    {'industry': 'Education',                'orgs': 5,  'facilities': 24},
    {'industry': 'Ports & Logistics',        'orgs': 3,  'facilities': 10},
    {'industry': 'Defence & Government',     'orgs': 2,  'facilities': 8},
  ];

  static const recentRegistrations = [
    {'name': 'Godrej Properties Ltd.',    'type': 'Real Estate',  'date': '18 Jun 2026', 'facilities': 3},
    {'name': 'Manipal Hospitals Group',   'type': 'Healthcare',   'date': '15 Jun 2026', 'facilities': 5},
    {'name': 'Wipro Technologies',        'type': 'IT',           'date': '12 Jun 2026', 'facilities': 4},
    {'name': 'L&T Defence Ltd.',          'type': 'Defence',      'date': '10 Jun 2026', 'facilities': 2},
    {'name': 'Oberoi Hotels & Resorts',   'type': 'Hospitality',  'date': '08 Jun 2026', 'facilities': 6},
  ];

  static const recentActivities = [
    {'action': 'Organisation Registered',   'entity': 'Godrej Properties Ltd.',      'time': '2h ago',    'icon': 'domain'},
    {'action': 'Audit Submitted',           'entity': 'AUD-202606-001088 · Jamnagar','time': '4h ago',    'icon': 'assignment'},
    {'action': 'NOC Application Filed',     'entity': 'Phoenix Mall Bengaluru',       'time': '6h ago',    'icon': 'article'},
    {'action': 'Critical CA Escalated',     'entity': 'Delhi Public School Sector 19','time': '8h ago',    'icon': 'warning'},
    {'action': 'New Auditor Created',       'entity': 'Amit Sharma · Reliance Ind.', 'time': '1d ago',    'icon': 'person_add'},
    {'action': 'Facility Registered',       'entity': 'Wipro SEZ Pune',              'time': '1d ago',    'icon': 'location_city'},
  ];
}

// Summary stats for dashboards
class DashboardStats {
  // All values aligned with GovernanceStats — single source of truth
  static const adminStats = {
    'totalOrgs': GovernanceStats.totalOrgs,
    'totalFacilities': GovernanceStats.totalFacilities,
    'totalAudits': GovernanceStats.totalAudits,
    'activeUsers': GovernanceStats.totalUsers,
    'avgFRI': 74.2,
    'criticalFacilities': 23,
    'pendingNOC': 18,
    'openCAs': 456,
  };

  static const smStats = {
    'compliance': 78,
    'openCAs': 14,
    'criticalCAs': 3,
    'pendingAudits': 2,
    'equipmentDue': 6,
    'nocDaysLeft': 32,
    'lastDrillDays': 45,
    'trainingGap': 8,
  };

  static const auditorStats = {
    'assignedAudits': 4,
    'pendingAudits': 2,
    'completedThisMonth': 6,
    'totalFindings': 38,
    'criticalFindings': 5,
    'avgScore': 76.4,
  };

  static const govtStats = {
    'totalFacilities': 1284,
    'compliant': 892,
    'nonCompliant': 247,
    'critical': 145,
    'nocPending': 68,
    'nocExpired': 34,
    'scheduledInspections': 28,
  };
}
