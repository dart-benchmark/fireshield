/// NBC 2016 Part 4 occupancy classification.
///
/// Groups A–J per Cl. 3.1. Note there is no Group I — NBC skips it so the
/// letter is not confused with the numeral 1.
///
/// Each concrete building type maps to exactly one subdivision. The
/// subdivision decides which checkpoint categories apply and how heavily the
/// building's risk is weighted.
library;

import 'checkpoint_model.dart';

class OccupancyGroup {
  /// Single letter, A–J.
  final String code;
  final String name;
  final String description;

  const OccupancyGroup({
    required this.code,
    required this.name,
    required this.description,
  });
}

class OccupancySubdivision {
  /// e.g. "C-1".
  final String code;
  final String groupCode;
  final String name;
  final String description;

  /// Multiplier on the building's inherent risk before any audit is run.
  /// Hospitals and hazardous plants start riskier than a small office.
  final double hazardFactor;

  const OccupancySubdivision({
    required this.code,
    required this.groupCode,
    required this.name,
    required this.description,
    required this.hazardFactor,
  });
}

class BuildingType {
  /// Stable key used in storage and dropdowns.
  final String key;
  final String label;

  /// Subdivision code, e.g. "F-2".
  final String subdivision;

  /// Regulators with jurisdiction beyond NBC/BIS for this type.
  final List<String> authorities;

  /// NBC checkpoint categories that apply. Empty means all 13 apply.
  final List<String> extraCategories;

  const BuildingType({
    required this.key,
    required this.label,
    required this.subdivision,
    this.authorities = const [],
    this.extraCategories = const [],
  });
}

// ─── Groups ────────────────────────────────────────────────────────────────

const List<OccupancyGroup> occupancyGroups = [
  OccupancyGroup(
    code: 'A',
    name: 'Residential',
    description: 'Sleeping accommodation — dwellings, hostels, hotels.',
  ),
  OccupancyGroup(
    code: 'B',
    name: 'Educational',
    description: 'Schools, colleges and training institutions.',
  ),
  OccupancyGroup(
    code: 'C',
    name: 'Institutional',
    description:
        'Occupants under medical care or restraint, with limited ability to self-evacuate.',
  ),
  OccupancyGroup(
    code: 'D',
    name: 'Assembly',
    description: 'Places where people gather in numbers for events or worship.',
  ),
  OccupancyGroup(
    code: 'E',
    name: 'Business',
    description: 'Offices, laboratories and data or telecom installations.',
  ),
  OccupancyGroup(
    code: 'F',
    name: 'Mercantile',
    description: 'Shops, stores and shopping centres.',
  ),
  OccupancyGroup(
    code: 'G',
    name: 'Industrial',
    description: 'Manufacturing and processing, graded by hazard level.',
  ),
  OccupancyGroup(
    code: 'H',
    name: 'Storage',
    description: 'Warehouses, cold stores and goods depots.',
  ),
  OccupancyGroup(
    code: 'J',
    name: 'Hazardous',
    description:
        'Storage or handling of materials liable to burn rapidly, explode or emit toxins.',
  ),
];

// ─── Subdivisions ──────────────────────────────────────────────────────────

const List<OccupancySubdivision> occupancySubdivisions = [
  // Group A — Residential
  OccupancySubdivision(code: 'A-1', groupCode: 'A', name: 'Lodging / rooming houses', description: 'Sleeping accommodation for up to 15 persons on transient basis.', hazardFactor: 1.0),
  OccupancySubdivision(code: 'A-2', groupCode: 'A', name: 'One or two family private dwellings', description: 'Independent houses, villas, duplexes.', hazardFactor: 0.8),
  OccupancySubdivision(code: 'A-3', groupCode: 'A', name: 'Dormitories', description: 'Group sleeping accommodation — hostels, barracks.', hazardFactor: 1.2),
  OccupancySubdivision(code: 'A-4', groupCode: 'A', name: 'Apartment houses / flats', description: 'Three or more dwelling units in one building.', hazardFactor: 1.1),
  OccupancySubdivision(code: 'A-5', groupCode: 'A', name: 'Hotels', description: 'Transient accommodation with services.', hazardFactor: 1.3),
  OccupancySubdivision(code: 'A-6', groupCode: 'A', name: 'Starred hotels', description: 'Classified hotels with extended guest facilities.', hazardFactor: 1.4),

  // Group B — Educational
  OccupancySubdivision(code: 'B-1', groupCode: 'B', name: 'Schools up to senior secondary', description: 'Instruction for students below 18, higher evacuation dependency.', hazardFactor: 1.3),
  OccupancySubdivision(code: 'B-2', groupCode: 'B', name: 'All other educational institutions', description: 'Colleges, universities, training and coaching centres.', hazardFactor: 1.1),

  // Group C — Institutional
  OccupancySubdivision(code: 'C-1', groupCode: 'C', name: 'Hospitals and sanatoria', description: 'Occupants under medical care, largely non-ambulatory.', hazardFactor: 1.8),
  OccupancySubdivision(code: 'C-2', groupCode: 'C', name: 'Custodial institutions', description: 'Care of children, elderly or persons with disability.', hazardFactor: 1.6),
  OccupancySubdivision(code: 'C-3', groupCode: 'C', name: 'Penal and mental institutions', description: 'Occupants under restraint, evacuation is controlled.', hazardFactor: 1.7),

  // Group D — Assembly
  OccupancySubdivision(code: 'D-1', groupCode: 'D', name: 'Assembly with stage, over 1000 persons', description: 'Theatres, auditoria and concert halls with permanent stage.', hazardFactor: 1.7),
  OccupancySubdivision(code: 'D-2', groupCode: 'D', name: 'Assembly with stage, under 1000 persons', description: 'Smaller theatres and halls with permanent stage.', hazardFactor: 1.5),
  OccupancySubdivision(code: 'D-3', groupCode: 'D', name: 'Assembly without stage, over 300 persons', description: 'Places of worship, community halls, restaurants.', hazardFactor: 1.4),
  OccupancySubdivision(code: 'D-4', groupCode: 'D', name: 'Assembly without stage, under 300 persons', description: 'Small halls, clubs and meeting rooms.', hazardFactor: 1.2),
  OccupancySubdivision(code: 'D-5', groupCode: 'D', name: 'Open air assembly', description: 'Stadia, grandstands and amusement park structures.', hazardFactor: 1.3),
  OccupancySubdivision(code: 'D-6', groupCode: 'D', name: 'Transport terminals', description: 'Airports, rail and metro stations, bus terminals.', hazardFactor: 1.6),
  OccupancySubdivision(code: 'D-7', groupCode: 'D', name: 'Underground or terrace assembly', description: 'Assembly below grade or on roof, with constrained escape.', hazardFactor: 1.8),

  // Group E — Business
  OccupancySubdivision(code: 'E-1', groupCode: 'E', name: 'Offices, banks, professional establishments', description: 'General commercial office use.', hazardFactor: 1.0),
  OccupancySubdivision(code: 'E-2', groupCode: 'E', name: 'Laboratories and research establishments', description: 'Testing and research, may hold limited hazardous stock.', hazardFactor: 1.4),
  OccupancySubdivision(code: 'E-3', groupCode: 'E', name: 'Computer installations', description: 'Data centres and server farms with high electrical load.', hazardFactor: 1.5),
  OccupancySubdivision(code: 'E-4', groupCode: 'E', name: 'Telephone exchanges', description: 'Switching and telecom equipment rooms.', hazardFactor: 1.3),
  OccupancySubdivision(code: 'E-5', groupCode: 'E', name: 'Broadcasting and TV stations', description: 'Studios with stage sets and heavy cabling.', hazardFactor: 1.4),

  // Group F — Mercantile
  OccupancySubdivision(code: 'F-1', groupCode: 'F', name: 'Shops and stores, small', description: 'Retail below 500 m² floor area.', hazardFactor: 1.1),
  OccupancySubdivision(code: 'F-2', groupCode: 'F', name: 'Departmental stores and shopping malls', description: 'Large retail with high occupant load and combustible stock.', hazardFactor: 1.5),
  OccupancySubdivision(code: 'F-3', groupCode: 'F', name: 'Underground shopping centres', description: 'Retail below grade, escape and smoke venting constrained.', hazardFactor: 1.8),

  // Group G — Industrial
  OccupancySubdivision(code: 'G-1', groupCode: 'G', name: 'Low hazard industrial', description: 'Non-combustible processing — assembly, packaging.', hazardFactor: 1.2),
  OccupancySubdivision(code: 'G-2', groupCode: 'G', name: 'Moderate hazard industrial', description: 'Moderately combustible processing and finished stock.', hazardFactor: 1.6),
  OccupancySubdivision(code: 'G-3', groupCode: 'G', name: 'High hazard industrial', description: 'Highly combustible or flammable processing.', hazardFactor: 2.0),

  // Group H — Storage
  OccupancySubdivision(code: 'H-1', groupCode: 'H', name: 'General storage', description: 'Warehouses and goods depots.', hazardFactor: 1.4),
  OccupancySubdivision(code: 'H-2', groupCode: 'H', name: 'Cold storage and high-rack storage', description: 'Insulated panel construction or high stacking.', hazardFactor: 1.7),

  // Group J — Hazardous
  OccupancySubdivision(code: 'J-1', groupCode: 'J', name: 'Flammable liquid and gas storage', description: 'Petroleum, LPG and solvent handling — PESO licensed.', hazardFactor: 2.5),
  OccupancySubdivision(code: 'J-2', groupCode: 'J', name: 'Explosives and pyrotechnics', description: 'Manufacture or storage of explosive materials.', hazardFactor: 3.0),
  OccupancySubdivision(code: 'J-3', groupCode: 'J', name: 'Radioactive and toxic materials', description: 'Radiological or acutely toxic inventory — AERB regulated.', hazardFactor: 2.8),
];

// ─── Concrete building types ───────────────────────────────────────────────

const List<BuildingType> buildingTypes = [
  // Residential
  BuildingType(key: 'independent_house', label: 'Independent house / villa', subdivision: 'A-2'),
  BuildingType(key: 'apartment_complex', label: 'Apartment complex', subdivision: 'A-4'),
  BuildingType(key: 'gated_township', label: 'Gated residential township', subdivision: 'A-4'),
  BuildingType(key: 'hostel', label: 'Hostel / dormitory', subdivision: 'A-3'),
  BuildingType(key: 'staff_quarters', label: 'Staff quarters', subdivision: 'A-3'),
  BuildingType(key: 'guest_house', label: 'Guest house / lodge', subdivision: 'A-1'),
  BuildingType(key: 'service_apartment', label: 'Service apartment', subdivision: 'A-5'),
  BuildingType(key: 'hotel', label: 'Hotel', subdivision: 'A-5'),
  BuildingType(key: 'starred_hotel', label: 'Starred hotel / resort', subdivision: 'A-6'),

  // Educational
  BuildingType(key: 'primary_school', label: 'Primary school', subdivision: 'B-1'),
  BuildingType(key: 'secondary_school', label: 'Secondary / senior secondary school', subdivision: 'B-1'),
  BuildingType(key: 'residential_school', label: 'Residential school', subdivision: 'B-1'),
  BuildingType(key: 'college', label: 'College', subdivision: 'B-2'),
  BuildingType(key: 'university_campus', label: 'University campus', subdivision: 'B-2'),
  BuildingType(key: 'coaching_centre', label: 'Coaching / training centre', subdivision: 'B-2'),
  BuildingType(key: 'library', label: 'Library', subdivision: 'B-2'),

  // Institutional
  BuildingType(key: 'hospital', label: 'Hospital', subdivision: 'C-1', authorities: ['NABH', 'AERB']),
  BuildingType(key: 'nursing_home', label: 'Nursing home', subdivision: 'C-1', authorities: ['NABH']),
  BuildingType(key: 'clinic', label: 'Clinic / day-care centre', subdivision: 'C-1', authorities: ['NABH']),
  BuildingType(key: 'diagnostic_centre', label: 'Diagnostic imaging centre', subdivision: 'C-1', authorities: ['NABH', 'AERB']),
  BuildingType(key: 'old_age_home', label: 'Old age home', subdivision: 'C-2'),
  BuildingType(key: 'orphanage', label: 'Orphanage / childcare institution', subdivision: 'C-2'),
  BuildingType(key: 'rehab_centre', label: 'Rehabilitation centre', subdivision: 'C-2'),
  BuildingType(key: 'prison', label: 'Prison / correctional facility', subdivision: 'C-3', authorities: ['CISF']),
  BuildingType(key: 'mental_institution', label: 'Mental health institution', subdivision: 'C-3'),

  // Assembly
  BuildingType(key: 'auditorium', label: 'Auditorium / concert hall', subdivision: 'D-1'),
  BuildingType(key: 'multiplex', label: 'Multiplex cinema', subdivision: 'D-1'),
  BuildingType(key: 'theatre', label: 'Theatre', subdivision: 'D-2'),
  BuildingType(key: 'banquet_hall', label: 'Banquet / marriage hall', subdivision: 'D-3'),
  BuildingType(key: 'place_of_worship', label: 'Place of worship', subdivision: 'D-3'),
  BuildingType(key: 'restaurant', label: 'Restaurant / food court', subdivision: 'D-3'),
  BuildingType(key: 'community_hall', label: 'Community hall', subdivision: 'D-4'),
  BuildingType(key: 'club', label: 'Club / recreation centre', subdivision: 'D-4'),
  BuildingType(key: 'stadium', label: 'Stadium / grandstand', subdivision: 'D-5'),
  BuildingType(key: 'amusement_park', label: 'Amusement park structure', subdivision: 'D-5'),
  BuildingType(key: 'airport', label: 'Airport terminal', subdivision: 'D-6', authorities: ['DGCA', 'CISF']),
  BuildingType(key: 'railway_station', label: 'Railway station', subdivision: 'D-6', authorities: ['CISF']),
  BuildingType(key: 'metro_station', label: 'Metro station', subdivision: 'D-7', authorities: ['CISF']),
  BuildingType(key: 'bus_terminal', label: 'Bus terminal', subdivision: 'D-6'),
  BuildingType(key: 'convention_centre', label: 'Convention / exhibition centre', subdivision: 'D-1'),

  // Business
  BuildingType(key: 'office', label: 'Office building', subdivision: 'E-1'),
  BuildingType(key: 'it_campus', label: 'IT / ITES campus', subdivision: 'E-1'),
  BuildingType(key: 'bank', label: 'Bank / financial branch', subdivision: 'E-1'),
  BuildingType(key: 'coworking', label: 'Co-working space', subdivision: 'E-1'),
  BuildingType(key: 'government_office', label: 'Government office', subdivision: 'E-1'),
  BuildingType(key: 'research_lab', label: 'Research laboratory', subdivision: 'E-2', authorities: ['AERB']),
  BuildingType(key: 'testing_lab', label: 'Testing / QC laboratory', subdivision: 'E-2'),
  BuildingType(key: 'data_centre', label: 'Data centre', subdivision: 'E-3'),
  BuildingType(key: 'server_room', label: 'Server / control room', subdivision: 'E-3'),
  BuildingType(key: 'telephone_exchange', label: 'Telephone exchange', subdivision: 'E-4'),
  BuildingType(key: 'broadcast_studio', label: 'Broadcast / TV studio', subdivision: 'E-5'),

  // Mercantile
  BuildingType(key: 'retail_shop', label: 'Retail shop', subdivision: 'F-1'),
  BuildingType(key: 'showroom', label: 'Showroom', subdivision: 'F-1'),
  BuildingType(key: 'supermarket', label: 'Supermarket', subdivision: 'F-2'),
  BuildingType(key: 'shopping_mall', label: 'Shopping mall', subdivision: 'F-2'),
  BuildingType(key: 'departmental_store', label: 'Departmental store', subdivision: 'F-2'),
  BuildingType(key: 'wholesale_market', label: 'Wholesale market', subdivision: 'F-2'),
  BuildingType(key: 'underground_market', label: 'Underground shopping centre', subdivision: 'F-3'),

  // Industrial
  BuildingType(key: 'assembly_unit', label: 'Assembly / packaging unit', subdivision: 'G-1'),
  BuildingType(key: 'garment_factory', label: 'Garment factory', subdivision: 'G-2'),
  BuildingType(key: 'food_processing', label: 'Food processing plant', subdivision: 'G-2'),
  BuildingType(key: 'engineering_workshop', label: 'Engineering workshop', subdivision: 'G-2'),
  BuildingType(key: 'automobile_plant', label: 'Automobile plant', subdivision: 'G-2'),
  BuildingType(key: 'pharma_plant', label: 'Pharmaceutical plant', subdivision: 'G-2'),
  BuildingType(key: 'textile_mill', label: 'Textile mill', subdivision: 'G-3'),
  BuildingType(key: 'chemical_plant', label: 'Chemical plant', subdivision: 'G-3', authorities: ['PESO', 'OISD']),
  BuildingType(key: 'paint_factory', label: 'Paint / solvent factory', subdivision: 'G-3', authorities: ['PESO']),
  BuildingType(key: 'refinery', label: 'Refinery / petrochemical unit', subdivision: 'G-3', authorities: ['OISD', 'PESO', 'CISF']),
  BuildingType(key: 'power_plant', label: 'Power plant', subdivision: 'G-3', authorities: ['CISF']),
  BuildingType(key: 'nuclear_facility', label: 'Nuclear facility', subdivision: 'G-3', authorities: ['AERB', 'CISF']),

  // Storage
  BuildingType(key: 'warehouse', label: 'Warehouse', subdivision: 'H-1'),
  BuildingType(key: 'godown', label: 'Godown / goods depot', subdivision: 'H-1'),
  BuildingType(key: 'container_yard', label: 'Container yard', subdivision: 'H-1'),
  BuildingType(key: 'cold_storage', label: 'Cold storage', subdivision: 'H-2'),
  BuildingType(key: 'high_rack_warehouse', label: 'High-rack automated warehouse', subdivision: 'H-2'),
  BuildingType(key: 'grain_silo', label: 'Grain silo', subdivision: 'H-2'),

  // Hazardous
  BuildingType(key: 'petrol_pump', label: 'Petrol pump / fuel station', subdivision: 'J-1', authorities: ['PESO', 'OISD']),
  BuildingType(key: 'lpg_bottling', label: 'LPG bottling plant', subdivision: 'J-1', authorities: ['PESO', 'OISD']),
  BuildingType(key: 'oil_terminal', label: 'Oil storage terminal', subdivision: 'J-1', authorities: ['OISD', 'PESO', 'CISF']),
  BuildingType(key: 'solvent_store', label: 'Solvent / flammable liquid store', subdivision: 'J-1', authorities: ['PESO']),
  BuildingType(key: 'gas_cylinder_store', label: 'Compressed gas cylinder store', subdivision: 'J-1', authorities: ['PESO']),
  BuildingType(key: 'explosives_magazine', label: 'Explosives magazine', subdivision: 'J-2', authorities: ['PESO', 'CISF']),
  BuildingType(key: 'firework_factory', label: 'Firework factory', subdivision: 'J-2', authorities: ['PESO']),
  BuildingType(key: 'radioactive_store', label: 'Radioactive material store', subdivision: 'J-3', authorities: ['AERB', 'CISF']),
];

// ─── Lookup ────────────────────────────────────────────────────────────────

class OccupancyTaxonomy {
  const OccupancyTaxonomy._();

  static OccupancyGroup? group(String code) {
    for (final g in occupancyGroups) {
      if (g.code == code) return g;
    }
    return null;
  }

  static OccupancySubdivision? subdivision(String code) {
    for (final s in occupancySubdivisions) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Returns null for an unknown key — callers must handle it rather than
  /// falling back to an unrelated building type.
  static BuildingType? byKey(String key) {
    for (final b in buildingTypes) {
      if (b.key == key) return b;
    }
    return null;
  }

  static List<OccupancySubdivision> subdivisionsOf(String groupCode) =>
      occupancySubdivisions.where((s) => s.groupCode == groupCode).toList();

  static List<BuildingType> typesOf(String subdivisionCode) =>
      buildingTypes.where((b) => b.subdivision == subdivisionCode).toList();

  static List<BuildingType> typesOfGroup(String groupCode) {
    final subs = subdivisionsOf(groupCode).map((s) => s.code).toSet();
    return buildingTypes.where((b) => subs.contains(b.subdivision)).toList();
  }

  /// Free-text search across type label, subdivision name and group name.
  static List<BuildingType> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return buildingTypes;
    return buildingTypes.where((b) {
      final sub = subdivision(b.subdivision);
      final grp = sub == null ? null : group(sub.groupCode);
      final hay = [
        b.label,
        b.key,
        b.subdivision,
        sub?.name ?? '',
        grp?.name ?? '',
        b.authorities.join(' '),
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  static double hazardFactor(BuildingType type) =>
      subdivision(type.subdivision)?.hazardFactor ?? 1.0;

  /// Regulators for a building type — always NBC and BIS, plus any sector
  /// authority declared on the type.
  static List<String> authoritiesFor(BuildingType type) =>
      ['BIS', ...type.authorities];

  /// Checkpoints that apply to a building type.
  ///
  /// BIS checkpoints for lifts (IS 14665) are dropped for low-rise
  /// subdivisions that will not have one.
  static List<Checkpoint> checkpointsFor(
    BuildingType type,
    List<Checkpoint> master,
  ) {
    final sub = subdivision(type.subdivision);
    final lowRise = sub != null && sub.code == 'A-2';
    return master.where((c) {
      if (lowRise && c.category.startsWith('IS 14665')) return false;
      if (lowRise && c.category == 'Fire Lifts') return false;
      return true;
    }).toList();
  }
}
