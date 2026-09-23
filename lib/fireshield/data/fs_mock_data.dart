/// Mock data ported from pwa_app/src/data/mockData.js.
///
/// INTEGRATION NOTE (for backend wiring): every screen reads through
/// [FsRepository], never from these lists directly. Replace the repository's
/// method bodies with HTTP calls and the UI needs no changes.
library;

import 'fs_models.dart';

const List<FsUser> demoUsers = [
  FsUser(
    id: 1,
    name: 'Arjun Mehta',
    role: FsRole.admin,
    email: 'arjun@fireshield.in',
    facility: 'All Facilities',
    initials: 'AM',
    dept: 'Platform Administration',
    org: 'FireShield AI™ · EY',
  ),
  FsUser(
    id: 2,
    name: 'Priya Sharma',
    role: FsRole.manager,
    email: 'priya@phoenix.com',
    facility: 'Phoenix Marketcity Bengaluru',
    initials: 'PS',
    dept: 'HSE Department',
    org: 'Phoenix Group',
  ),
  FsUser(
    id: 3,
    name: 'Ravi Kumar',
    role: FsRole.auditor,
    email: 'ravi@auditcorp.in',
    facility: 'Phoenix Marketcity Bengaluru',
    initials: 'RK',
    dept: 'Audit Division',
    org: 'AuditCorp India',
  ),
  FsUser(
    id: 4,
    name: 'Vikram Mehta',
    role: FsRole.orgadmin,
    email: 'vikram@phoenix.com',
    facility: 'All Phoenix Facilities',
    initials: 'VM',
    dept: 'Safety & Compliance',
    org: 'Phoenix Group',
  ),
];

const List<FsOrganisation> organizations = [
  FsOrganisation(id: 'O01', name: 'Phoenix Group', industry: 'Retail & Commercial', gst: '29AABCP1234Q1ZX', pan: 'AABCP1234Q', email: 'safety@phoenixgroup.com', phone: '+91-80-4567-8900', city: 'Bengaluru', state: 'Karnataka', facilities: 6, compliance: 88, risk: 'MEDIUM'),
  FsOrganisation(id: 'O02', name: 'Apollo Hospitals Group', industry: 'Healthcare', gst: '07AABCA5678R1ZY', pan: 'AABCA5678R', email: 'safety@apollohospitals.com', phone: '+91-11-7654-3210', city: 'New Delhi', state: 'Delhi', facilities: 14, compliance: 91, risk: 'LOW'),
  FsOrganisation(id: 'O03', name: 'Infosys Limited', industry: 'Information Technology', gst: '29AABCI9012S1ZZ', pan: 'AABCI9012S', email: 'safety@infosys.com', phone: '+91-80-2852-0261', city: 'Bengaluru', state: 'Karnataka', facilities: 9, compliance: 86, risk: 'MEDIUM'),
  FsOrganisation(id: 'O04', name: 'Tata Consultancy Services', industry: 'Information Technology', gst: '27AAACT3456T1ZA', pan: 'AAACT3456T', email: 'safety@tcs.com', phone: '+91-22-6778-9999', city: 'Mumbai', state: 'Maharashtra', facilities: 18, compliance: 89, risk: 'LOW'),
  FsOrganisation(id: 'O05', name: 'DLF Limited', industry: 'Real Estate', gst: '06AAACD7890U1ZB', pan: 'AAACD7890U', email: 'safety@dlf.in', phone: '+91-124-4769-000', city: 'Gurugram', state: 'Haryana', facilities: 11, compliance: 82, risk: 'MEDIUM'),
  FsOrganisation(id: 'O06', name: 'Larsen & Toubro', industry: 'Manufacturing & EPC', gst: '27AAACL2345V1ZC', pan: 'AAACL2345V', email: 'safety@lt.com', phone: '+91-22-6776-2000', city: 'Mumbai', state: 'Maharashtra', facilities: 22, compliance: 84, risk: 'MEDIUM'),
  FsOrganisation(id: 'O07', name: 'Adani Group', industry: 'Ports & Logistics', gst: '24AAACA6789W1ZD', pan: 'AAACA6789W', email: 'safety@adani.com', phone: '+91-79-2555-5555', city: 'Ahmedabad', state: 'Gujarat', facilities: 28, compliance: 79, risk: 'HIGH'),
  FsOrganisation(id: 'O08', name: 'Prestige Group', industry: 'Real Estate', gst: '29AAACP0123X1ZE', pan: 'AAACP0123X', email: 'safety@prestigegroup.com', phone: '+91-80-2225-4000', city: 'Bengaluru', state: 'Karnataka', facilities: 7, compliance: 87, risk: 'MEDIUM'),
  FsOrganisation(id: 'O09', name: 'Brigade Group', industry: 'Real Estate', gst: '29AAACB4567Y1ZF', pan: 'AAACB4567Y', email: 'safety@brigadegroup.com', phone: '+91-80-4137-9200', city: 'Bengaluru', state: 'Karnataka', facilities: 5, compliance: 85, risk: 'LOW'),
  FsOrganisation(id: 'O10', name: 'Bharat Electronics Limited', industry: 'Defence & Electronics', gst: '29AAACB8901Z1ZG', pan: 'AAACB8901Z', email: 'safety@bel.com', phone: '+91-80-2296-3142', city: 'Bengaluru', state: 'Karnataka', facilities: 8, compliance: 93, risk: 'LOW'),
];

const List<FsFacility> mockFacilities = [
  FsFacility(id: 'F001', name: 'Phoenix Marketcity Bengaluru', org: 'Phoenix Group', type: 'Shopping Mall', state: 'Karnataka', city: 'Bengaluru', risk: 'MEDIUM', compliance: 88, fri: 86.4, noc: 'Valid', nocExpiry: '28 Feb 2027', floors: 5, basements: 2, area: '1,85,000 sqm', occupancy: 8000, lastAudit: '01 Jun 2026', due: '20 Jun 2026', head: 'Suresh Iyer', coordinator: 'Anita Sharma'),
  FsFacility(id: 'F011', name: 'Phoenix Marketcity Pune', org: 'Phoenix Group', type: 'Shopping Mall', state: 'Maharashtra', city: 'Pune', risk: 'LOW', compliance: 91, fri: 89.3, noc: 'Valid', nocExpiry: '31 Mar 2027', floors: 4, basements: 2, area: '1,65,000 sqm', occupancy: 7000, lastAudit: '10 Jun 2026', due: '28 Jun 2026', head: 'Vikram Patil', coordinator: 'Seema Kulkarni'),
  FsFacility(id: 'F012', name: 'Phoenix Palladium Mumbai', org: 'Phoenix Group', type: 'Shopping Mall', state: 'Maharashtra', city: 'Mumbai', risk: 'MEDIUM', compliance: 86, fri: 84.7, noc: 'Expiring', nocExpiry: '15 Aug 2026', floors: 6, basements: 2, area: '2,10,000 sqm', occupancy: 9500, lastAudit: '05 Jun 2026', due: '20 Jun 2026', head: 'Anand Joshi', coordinator: 'Priti Shah'),
  FsFacility(id: 'F013', name: 'Phoenix Citadel Indore', org: 'Phoenix Group', type: 'Shopping Mall', state: 'Madhya Pradesh', city: 'Indore', risk: 'LOW', compliance: 88, fri: 86.1, noc: 'Valid', nocExpiry: '28 Feb 2027', floors: 4, basements: 1, area: '1,25,000 sqm', occupancy: 6000, lastAudit: '01 Jun 2026', due: '25 Jun 2026', head: 'Rakesh Sharma', coordinator: 'Divya Mehta'),
  FsFacility(id: 'F002', name: 'Apollo Hospital Delhi', org: 'Apollo Hospitals Group', type: 'Hospital', state: 'Delhi', city: 'New Delhi', risk: 'HIGH', compliance: 91, fri: 90.2, noc: 'Valid', nocExpiry: '31 Dec 2026', floors: 8, basements: 2, area: '95,000 sqm', occupancy: 3200, lastAudit: '08 Jun 2026', due: '15 Jul 2026', head: 'Dr. Meera Nair', coordinator: 'Rohit Verma'),
  FsFacility(id: 'F003', name: 'Infosys Campus Mysuru', org: 'Infosys Limited', type: 'IT Campus', state: 'Karnataka', city: 'Mysuru', risk: 'MEDIUM', compliance: 86, fri: 84.3, noc: 'Valid', nocExpiry: '30 Sep 2026', floors: 6, basements: 1, area: '3,40,000 sqm', occupancy: 15000, lastAudit: '18 Jun 2026', due: '30 Jul 2026', head: 'Karthik Iyer', coordinator: 'Lakshmi Rao'),
];

const List<FsAudit> allOrgAudits = [
  FsAudit(id: 'A001', no: 'AUD-202606-1089', facility: 'Phoenix Marketcity Bengaluru', org: 'Phoenix Group', facilityId: 'F001', type: 'Fire Safety Audit', status: 'IN_PROGRESS', date: '13 Jun 2026', total: 148, done: 64, score: 78.4, auditor: 'Priya Nair', priority: 'HIGH'),
  FsAudit(id: 'A002', no: 'AUD-202606-1092', facility: 'Phoenix Marketcity Pune', org: 'Phoenix Group', facilityId: 'F011', type: 'Pre-Inspection Audit', status: 'SCHEDULED', date: '20 Jun 2026', total: 132, done: 0, score: 0, auditor: 'Priya Nair', priority: 'NORMAL'),
  FsAudit(id: 'A003', no: 'AUD-202606-1094', facility: 'Phoenix Palladium Mumbai', org: 'Phoenix Group', facilityId: 'F012', type: 'NOC Renewal Audit', status: 'SCHEDULED', date: '25 Jun 2026', total: 156, done: 0, score: 0, auditor: 'Priya Nair', priority: 'HIGH'),
  FsAudit(id: 'A004', no: 'AUD-202605-1081', facility: 'Phoenix Citadel Indore', org: 'Phoenix Group', facilityId: 'F013', type: 'Self Audit', status: 'APPROVED', date: '01 Jun 2026', total: 118, done: 118, score: 88.1, auditor: 'Priya Nair', priority: 'NORMAL'),
  FsAudit(id: 'A005', no: 'AUD-202606-1096', facility: 'Phoenix Mall of Asia Bengaluru', org: 'Phoenix Group', facilityId: 'F014', type: 'Fire Safety Audit', status: 'SUBMITTED', date: '14 Jun 2026', total: 168, done: 168, score: 81.5, auditor: 'Priya Nair', priority: 'NORMAL'),
  FsAudit(id: 'A006', no: 'AUD-202606-2011', facility: 'Apollo Hospital Delhi', org: 'Apollo Hospitals Group', facilityId: 'F002', type: 'Fire Safety Audit', status: 'APPROVED', date: '08 Jun 2026', total: 180, done: 180, score: 91.2, auditor: 'Ravi Kumar', priority: 'HIGH'),
  FsAudit(id: 'A007', no: 'AUD-202606-2015', facility: 'Apollo Hospital Chennai', org: 'Apollo Hospitals Group', facilityId: 'F015', type: 'NABH Compliance Audit', status: 'SUBMITTED', date: '12 Jun 2026', total: 165, done: 165, score: 88.7, auditor: 'Ravi Kumar', priority: 'HIGH'),
  FsAudit(id: 'A008', no: 'AUD-202606-3022', facility: 'Infosys Campus Mysuru', org: 'Infosys Limited', facilityId: 'F003', type: 'Annual Fire Audit', status: 'IN_PROGRESS', date: '18 Jun 2026', total: 142, done: 90, score: 84.3, auditor: 'Suresh Pillai', priority: 'NORMAL'),
];


const List<FsCorrectiveAction> correctiveActions = [
  FsCorrectiveAction(id: 'CA001', no: 'CA-2026-0234', title: 'Blocked emergency exit — Floor 3 East Wing', severity: 'CRITICAL', status: 'OVERDUE', facility: 'Infosys Campus Mysuru', std: 'NBC 2026 Cl. 4.2.5', assigned: 'Suresh Mehta', raised: '01 Jun 2026', due: '03 Jun 2026', cost: '₹45,000', category: 'Means of Escape'),
  FsCorrectiveAction(id: 'CA002', no: 'CA-2026-0235', title: 'Fire extinguisher expired — Server Room B', severity: 'CRITICAL', status: 'IN_PROGRESS', facility: 'BEL Electronics Complex', std: 'IS 2190:2010', assigned: 'Anita Verma', raised: '05 Jun 2026', due: '12 Jun 2026', cost: '₹12,000', category: 'Fire Extinguishers'),
  FsCorrectiveAction(id: 'CA003', no: 'CA-2026-0236', title: 'Smoke detectors missing — Basement Car Park', severity: 'MAJOR', status: 'OPEN', facility: 'Phoenix Mall Bengaluru', std: 'IS 2189 Cl. 8.3', assigned: 'Ravi Kumar', raised: '08 Jun 2026', due: '22 Jun 2026', cost: '₹80,000', category: 'Fire Detection'),
  FsCorrectiveAction(id: 'CA004', no: 'CA-2026-0237', title: 'Exit signage not illuminated — Ground Floor', severity: 'MAJOR', status: 'CLOSED', facility: 'Apollo Hospital Delhi', std: 'NBC 2026 Cl. 4.13.2', assigned: 'Meena Shah', raised: '02 Jun 2026', due: '09 Jun 2026', cost: '₹18,000', category: 'Exit Signage'),
  FsCorrectiveAction(id: 'CA005', no: 'CA-2026-0238', title: 'Fire drill not conducted in last 6 months', severity: 'MINOR', status: 'OPEN', facility: 'L&T Manufacturing Plant', std: 'NBC 2026 Cl. 4.15', assigned: 'Principal Office', raised: '20 May 2026', due: '20 Jun 2026', cost: '₹5,000', category: 'Training & Drills'),
  FsCorrectiveAction(id: 'CA006', no: 'CA-2026-0239', title: 'Hydrant hose reel missing — Floor 2', severity: 'CRITICAL', status: 'OVERDUE', facility: 'DLF Cyber City Gurugram', std: 'IS 3844', assigned: 'Mohan Verma', raised: '28 May 2026', due: '04 Jun 2026', cost: '₹35,000', category: 'Hydrant System'),
  FsCorrectiveAction(id: 'CA007', no: 'CA-2026-0240', title: 'Fire control room unattended during audit hours', severity: 'MAJOR', status: 'IN_PROGRESS', facility: 'Phoenix Mall Bengaluru', std: 'NBC 2026 Cl. 6.1', assigned: 'Security Head', raised: '10 Jun 2026', due: '17 Jun 2026', cost: '₹0', category: 'Control Room'),
];

/// Single seam between the UI and the data source.
///
/// Every method is async and returns the same shapes a REST API would, so
/// swapping the bodies for `http`/`dio` calls is the whole integration job.
class FsRepository {
  const FsRepository();

  static const FsRepository instance = FsRepository();

  /// Simulates network latency so loading states are exercised in the demo.
  static const _latency = Duration(milliseconds: 350);

  Future<List<FsUser>> fetchDemoUsers() async {
    await Future<void>.delayed(_latency);
    return demoUsers;
  }

  Future<FsUser?> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    for (final u in demoUsers) {
      if (u.email.toLowerCase() == email.trim().toLowerCase()) return u;
    }
    return null;
  }

  Future<List<FsOrganisation>> fetchOrganisations() async {
    await Future<void>.delayed(_latency);
    return organizations;
  }

  Future<List<FsFacility>> fetchFacilities({String? org}) async {
    await Future<void>.delayed(_latency);
    if (org == null) return mockFacilities;
    return mockFacilities.where((f) => f.org == org).toList();
  }

  Future<List<FsAudit>> fetchAudits({String? org, String? auditor}) async {
    await Future<void>.delayed(_latency);
    return allOrgAudits.where((a) {
      if (org != null && a.org != org) return false;
      if (auditor != null && a.auditor != auditor) return false;
      return true;
    }).toList();
  }

  Future<List<FsCorrectiveAction>> fetchCorrectiveActions({String? facility}) async {
    await Future<void>.delayed(_latency);
    if (facility == null) return correctiveActions;
    return correctiveActions.where((c) => c.facility == facility).toList();
  }
}
