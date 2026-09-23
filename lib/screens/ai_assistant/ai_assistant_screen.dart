import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _State();
}

class _State extends State<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<MockChatMessage> _messages = List.from(mockAiConversation);
  bool _thinking = false;

  final _suggestions = [
    'NBC 2016 exit requirements for hospitals',
    'Sprinkler design for shopping malls',
    'Fire NOC renewal process',
    'Extinguisher service schedule IS 2190',
    'Generate CAPA for blocked fire exit',
  ];

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(MockChatMessage(id: DateTime.now().toString(), text: text, sender: 'You', isUser: true));
      _thinking = true;
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(MockChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        text: _generateResponse(text),
        sender: 'AI Assistant',
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  String _generateResponse(String q) {
    final ql = q.toLowerCase();

    // Facility types
    if (ql.contains('hospital') || ql.contains('nabh') || ql.contains('healthcare'))
      return "**Hospitals & Healthcare Facilities** — NBC 2016 Part 4 + NABH Fire Safety:\n\n**Minimum Requirements:**\n• Minimum 2 fire exits per floor, clearly marked with illuminated signs\n• Fire compartmentation every 2,000 sqm (2-hour fire-rated walls)\n• Automatic sprinkler system throughout (IS 15105)\n• 2-hour fire rating for structural elements and staircase doors\n• Pressurised staircases for buildings above 15m height\n• Fire alarm zoning: each ward = separate addressable zone\n• Emergency generator: power transfer within 10 seconds\n• Horizontal evacuation plan for ICU/ICU patients\n\n**NABH Specific:**\n• Monthly fire drills — all shifts, all staff\n• All staff trained in RACE (Rescue, Alarm, Contain, Evacuate) and PASS protocol\n• Patient evacuation chart displayed on each floor at nurse station\n• Signed fire warden register maintained quarterly\n\nShall I generate a hospital audit checklist?";

    if (ql.contains('mall') || ql.contains('shopping') || ql.contains('retail') || ql.contains('mercantile'))
      return "**Shopping Malls & Retail (Group F — Mercantile)** — NBC 2016 Part 4:\n\n**Exit Requirements:**\n• Minimum exits: 1 per 250 persons above 500 occupancy\n• No point on any floor more than 30m from an exit\n• Minimum exit width: 2.0m for occupancy above 1,000\n• Exits must be remote — min separation = floor diagonal × 0.33\n\n**High-Rise Malls (above 15m):**\n• Smoke-proof enclosure staircase mandatory\n• Pressurised staircases per NBC 2016 Cl. 4.8.3\n• Fire lifts mandatory above 24m (1 per 1,000 sqm)\n• Refuge areas on every 3rd floor\n\n**Fire Fighting:**\n• Automatic sprinkler throughout retail floors (IS 15105)\n• Hydrant system: 1 per 500 sqm, max travel 30m (IS 3844)\n• Smoke management system for atriums\n• 24x7 trained fire watch team mandatory\n\nWould you like exit width calculations for your floor plan?";

    if (ql.contains('school') || ql.contains('college') || ql.contains('education') || ql.contains('university'))
      return "**Schools & Educational Institutions** — NBC 2016 Part 4, Group E:\n\n**Key Requirements:**\n• All classrooms: self-closing doors, max occupancy 40 per room\n• Corridors: minimum 1.5m clear width, no storage\n• Assembly hall: sprinkler mandatory above 300 persons\n• Minimum 2 staircases for buildings above 3 floors\n• Fire alarm: manual call points at each staircase landing\n• Smoke detectors: labs, libraries, server rooms (IS 2189)\n\n**Drills & Training:**\n• Evacuation drill: minimum 2 per academic year\n• Drill records maintained and signed by principal\n• Fire safety awareness: taught in curriculum (Std 5 onwards)\n• All teachers: first-aid and fire extinguisher training\n\n**NOC Renewal:**\n• Annual NOC renewal mandatory for schools above 15m height\n• NOC application: 90 days before expiry\n• Structural fire safety certificate required with renewal";

    if (ql.contains('warehouse') || ql.contains('storage') || ql.contains('godown'))
      return "**Warehouses & Storage Facilities** — NBC 2016 + OISD + PESO:\n\n**Classification by Hazard:**\n• Class 1 (Paper, Wood): ABC extinguisher 1 per 150 sqm\n• Class 2 (Rubber, Plastic): CO2 + ABC, sprinkler mandatory\n• Class 3 (Flammable Liquids): AFFF foam, PESO license required\n• High-Rack Storage (above 8m): Early Suppression Fast Response (ESFR) sprinklers\n\n**Layout Requirements:**\n• Fire breaks every 500 sqm (3m wide access aisles)\n• Minimum 0.5m clearance from ceiling to top of stored goods\n• Electrical panels: 1m exclusion zone, CO2 extinguisher nearby\n• Sprinkler design: verify K-factor for storage height\n\n**PESO Requirements (Hazardous Goods):**\n• Explosive / flammable liquids: PESO license mandatory\n• Earthing and bonding for metal containers\n• No smoking / no open flame zones with signage";

    if (ql.contains('hotel') || ql.contains('hospitality') || ql.contains('resort') || ql.contains('guesthouse'))
      return "**Hotels & Hospitality** — NBC 2016 Part 4, Group B:\n\n**Key Standards:**\n• Sprinkler system: all sleeping rooms + corridors (IS 15105)\n• Fire alarm: addressable, zoned per floor (IS 2189)\n• Guest rooms: self-closing fire-rated doors (45-min minimum)\n• Smoke detectors: 1 per room + 1 per 30 sqm corridor\n• Emergency lighting: all corridors and staircases (IS 1944)\n• Signage: room door numbers visible at low level (for smoke visibility)\n\n**Staff Training:**\n• All staff: quarterly fire safety training\n• Night duty staff: trained for evacuation procedures\n• Guest evacuation chart: displayed inside every room door\n\n**High-Rise Hotels (above 15m):**\n• Refuge floor every 15m vertical height\n• Voice evacuation system (not bell only)\n• Fire command centre on ground floor\n• Sky lobby pressurisation above 45m";

    if (ql.contains('factory') || ql.contains('manufacturing') || ql.contains('industrial') || ql.contains('plant'))
      return "**Factories & Manufacturing** — NBC 2016 + OISD + Factories Act 1948:\n\n**Factories Act Requirements:**\n• Section 38: Fire escape, means of exit — 2 exits per floor\n• Fire drills: minimum 2 per year, register maintained\n• First-aider: 1 per 150 workers per shift\n\n**NBC 2016 Part 4 — Group H (Industrial):**\n• Sprinkler: mandatory for areas above 500 sqm (IS 15105)\n• Hydrant: every 45m (IS 3844), with booster pump\n• Foam: for flammable liquid process areas\n• Fire separation: process buildings minimum 9m apart\n\n**OISD for Petroleum/Chemical:**\n• OISD-116: Accident analysis and fire prevention\n• OISD-117: Firefighting equipment\n• OISD-118: Layouts for petroleum installations\n• Fixed foam/deluge system for tank farms";

    if (ql.contains('airport') || ql.contains('terminal') || ql.contains('dgca') || ql.contains('bcas'))
      return "**Airports & Aviation Terminals** — DGCA + BCAS + NBC 2016:\n\n**DGCA Fire Safety:**\n• CAR Section 9 Series D Part I: Aerodrome fire standards\n• Aircraft Rescue & Firefighting (ARFF): category based on longest aircraft\n• Category 6 and above: 3-minute response to mid-point of runway\n• ARFF vehicles: foam tender, dry powder tender, rapid intervention vehicle\n\n**Terminal Building (NBC 2016 Group D/F):**\n• Sprinkler: all concourse, retail, baggage areas\n• Smoke management: atrium and large volume spaces\n• Exits: 1 per 250 persons, no point more than 45m from exit\n• Emergency voice evacuation system (not bell)\n• Blast-resistant glazing for security-sensitive areas\n\n**BCAS Requirements:**\n• Fire safety plan approved by BCAS and airport authority\n• Monthly joint drill with airline operators\n• Airport Operators Committee (AOC) fire safety review quarterly";

    // Equipment / systems
    if (ql.contains('extinguisher') || ql.contains('abc') || ql.contains('co2') || ql.contains('dry powder'))
      return "**Fire Extinguishers** — IS 2190:2010:\n\n**Placement by Hazard Class:**\n• Class A (wood, paper): 1 per 150 sqm, max travel 23m\n• Class B (flammable liquids): 1 per 75 sqm, max travel 9m\n• Class C (electrical): CO2 — no powder near sensitive equipment\n• Class D (metals): Dry sand or special agent only\n• Cooking oil (Class F): Wet Chemical (IS 15683)\n\n**Mounting Height:** Handle at 1.0m–1.5m from floor\n\n**Inspection Schedule:**\n• Monthly: visual check — pressure gauge green, seal intact, tag current\n• Annual: full service + refill by certified agency\n• Every 3 years: hydraulic pressure test\n• Every 5 years: complete overhaul\n\n**Type by Use:**\n• Combustibles (A): ABC Dry Powder or Water-based\n• Electrical (C): CO2 — never use water or powder\n• Oils/Liquids (B): AFFF Foam or CO2\n• Kitchens (F): Wet Chemical only";

    if (ql.contains('hydrant') || ql.contains('hose reel') || ql.contains('wet riser'))
      return "**Hydrant & Hose Reel System** — IS 3844, IS 884:\n\n**Internal Hydrant System (IS 3844):**\n• Single-headed hydrant: 1 per 500 sqm floor area\n• Maximum travel distance: 30m from any point to nearest hydrant\n• Landing valve: 65mm dia at each floor staircase\n• Minimum flow: 900 lpm at terminal hydrant\n• Pressure at top floor: minimum 3.5 kg/cm²\n\n**Hose Reel System (IS 884):**\n• 25mm dia, 36m length — covers 450 sqm per reel\n• Pressure: minimum 2.5 kg/cm² at nozzle tip\n• Quarterly operational test mandatory\n\n**Wet Riser (High-Rise NBC 2016):**\n• Mandatory for buildings above 15m\n• 100mm dia rising main with landing valves\n• Fire pump: primary (electric) + standby (diesel)\n• Terrace tank: 25,000 litres minimum for single building\n• Annual hydraulic flow test — documented and signed";

    if (ql.contains('sprinkler') || ql.contains('suppression') || ql.contains('deluge'))
      return "**Sprinkler & Suppression Systems** — IS 15105, NFPA 13:\n\n**Sprinkler Design Basis:**\n• Light Hazard (office, hotel): 1 head per 12 sqm, 0.07 lpm/sqm\n• Ordinary Hazard Group 1 (school, hospital): 1 per 9 sqm, 0.10 lpm/sqm\n• Ordinary Hazard Group 2 (mall, factory): 1 per 9 sqm, 0.12 lpm/sqm\n• High Hazard (warehouse, paint shop): 0.30–0.50 lpm/sqm\n\n**Head Clearance Rules:**\n• Minimum 450mm clearance below sprinkler head to storage\n• No obstruction within 900mm radius of sprinkler head\n• Concealed heads: only listed concealed type\n\n**Special Systems:**\n• Deluge: transformer rooms, aircraft hangars — all heads open simultaneously\n• Pre-action: server rooms, freezers — prevents accidental discharge\n• Foam-water: fuel storage, aircraft maintenance\n\n**Testing:**\n• Monthly: main drain test + flow switch alarm test\n• Annual: full flow test from inspector's test valve";

    if (ql.contains('detector') || ql.contains('smoke') || ql.contains('heat detector') || ql.contains('flame detector'))
      return "**Fire Detection Systems** — IS 2189:2008:\n\n**Coverage per Detector Type:**\n• Smoke Detector (point type): 1 per 60 sqm (flat ceiling up to 6m)\n• Heat Detector (fixed temp): 1 per 30 sqm\n• Heat Detector (rate of rise): 1 per 40 sqm\n• Beam Detector (linear): covers up to 100m corridor length\n• Flame Detector: process plants, aircraft hangars\n\n**Placement Rules (IS 2189 Cl. 8):**\n• Max wall distance: 7.5m (smoke), 5.3m (heat)\n• Ceiling clearance: min 25mm, max 600mm from ceiling\n• Not within 500mm of air supply diffuser\n• Staircase: 1 detector per floor at head of stairs\n• Within 1.5m of kitchen / cooking area: heat detector only (not smoke)\n\n**Testing Frequency:**\n• Monthly: functional test of each zone (rotational testing)\n• Annual: full system test by competent person\n• Every 5 years: complete panel inspection and battery replacement";

    if (ql.contains('fire alarm') || ql.contains('panel') || ql.contains('mcp') || ql.contains('call point'))
      return "**Fire Alarm Systems** — IS 2189:2008:\n\n**System Types:**\n• Conventional: zones identified, not individual devices — suitable up to 3 floors\n• Addressable: each device has unique ID — required for buildings above 3 floors\n• Analogue Addressable: monitors detector health, early warning — high-rise and hospitals\n\n**Manual Call Points (MCP):**\n• Maximum travel distance: 30m to nearest MCP\n• Height: 1.2m–1.4m from finished floor level\n• Color: red, minimum 85mm face dimension\n• Protection: clear acrylic cover in industrial areas\n\n**Control Panel:**\n• Battery backup: minimum 24 hours standby + 30 min alarm\n• Panel location: permanently manned position or fire command centre\n• Zone isolation: individual zones must be isolatable without silencing system\n\n**Sounder Requirements:**\n• Minimum 65 dB at all occupied areas (75 dB in noisy environments)\n• Voice evacuation: mandatory for buildings above 15m\n• Disabled toilet: visual fire alert strobe mandatory";

    // Compliance / regulatory
    if (ql.contains('exit') || ql.contains('egress') || ql.contains('evacuation') || ql.contains('escape'))
      return "**Fire Exits & Means of Egress** — NBC 2016 Part 4, Cl. 4.9:\n\n**Number of Exits (by Occupancy Load):**\n• Up to 50 persons: 1 exit (minimum)\n• 51–500 persons: 2 exits\n• 501–1,000 persons: 3 exits\n• Above 1,000: 1 additional exit per additional 250 persons\n\n**Exit Width Calculation:**\n• Minimum: 1.0m (1-door), 1.5m (corridors), 2.0m (occupancy above 1,000)\n• Calculated: occupancy load × 6.1mm per person (NBC 2016 Cl. 4.9.3)\n• Staircases: 1.5m minimum clear width (high-rise: 2.0m)\n\n**Key Clauses:**\n• Cl. 4.9.1: Exits must be remote from each other (diagonal × 0.33 rule)\n• Cl. 4.9.2: Exit corridors — no combustibles, minimum 1.5m clear width\n• Cl. 4.9.4: Doors open in direction of escape\n• Cl. 4.9.8: Assembly points minimum 30m from building, clearly signed\n\n**Emergency Lighting (IS 1944):**\n• Minimum 90-minute backup duration\n• 1 lux minimum along escape route at floor level\n• Monthly functional test; annual 90-minute duration test";

    if (ql.contains('occupancy') || ql.contains('load') || ql.contains('capacity') || ql.contains('persons'))
      return "**Occupancy Load Calculation** — NBC 2016 Part 4, Table 1:\n\n**Floor Area per Person by Use:**\n• Assembly (cinema, auditorium): **0.65 sqm/person**\n• Classroom: **1.85 sqm/person**\n• Office (business): **9.3 sqm/person**\n• Shopping / retail sales area: **2.8 sqm/person**\n• Restaurant / dining: **1.4 sqm/person**\n• Industrial (manufacturing): **9.3 sqm/person**\n• Storage: **46.5 sqm/person**\n• Hospital (patient areas): **22.3 sqm/person**\n• Hotel sleeping rooms: **18.6 sqm/person**\n\n**Formula:**\n> Occupancy Load = Floor Area (sqm) ÷ Area per Person\n\n**Example:** Shopping mall, 10,000 sqm retail area\n> 10,000 ÷ 2.8 = **3,572 persons**\n> Minimum exits required: 3 + 1 = **4 exits**\n\n**Note:** Use the higher occupancy from actual count vs. calculated — whichever is greater governs the exit requirement.";

    if (ql.contains('noc') || ql.contains('no objection') || ql.contains('fire certificate'))
      return "**Fire NOC (No Objection Certificate)** — State Fire Services Acts:\n\n**Who Needs a Fire NOC:**\n• All buildings above 15m height\n• Educational institutions above 500 sqm (any height)\n• Hospitals, nursing homes (any height)\n• Hotels above 15 rooms or above 15m\n• Cinema halls, auditoriums, places of assembly\n• Factories with hazardous processes\n• Shopping malls and multiplexes\n\n**Documents Required (typical):**\n• Approved building plan (structural and fire services layout)\n• NBC 2016 compliance certificate from architect\n• Fire system completion certificate from installer\n• Third-party inspection report (Grade A consultant)\n• NOC renewal application (30/1 form — varies by state)\n\n**Renewal:**\n• Annual renewal — most states\n• Application: 90 days before expiry date\n• Penalty for expired NOC: closure notice, FIR under IPC 304A\n\n**FireShield AI tracks NOC expiry — set reminders 90 days in advance.**";

    if (ql.contains('nbc') || ql.contains('national building') || ql.contains('part 4'))
      return "**NBC 2016 — National Building Code, Part 4 (Fire & Life Safety):**\n\n**Scope:** Applies to all buildings constructed after 2016. States have adopted with local amendments.\n\n**Key Sections:**\n• **Cl. 4.1–4.3:** Classification of buildings by occupancy group (A–J)\n• **Cl. 4.7:** Construction requirements — fire ratings for walls, floors, columns\n• **Cl. 4.8:** Staircases, fire lifts, pressurisation\n• **Cl. 4.9:** Means of egress — exits, corridors, assembly points\n• **Cl. 4.10:** Sprinkler and water supply systems\n• **Cl. 4.11:** Fire detection and alarm systems\n• **Cl. 4.12:** Portable firefighting equipment\n• **Cl. 4.13:** Emergency lighting and signage\n• **Cl. 4.14:** Fire and smoke control\n\n**Occupancy Groups:**\n• A: Residential | B: Educational | C: Institutional | D: Assembly\n• E: Business | F: Mercantile | G: Industrial | H: Storage | J: Hazardous\n\n**Related Indian Standards:** IS 2189, IS 2190, IS 3844, IS 15105, IS 1944, IS 16069";

    if (ql.contains('capa') || ql.contains('corrective') || ql.contains('action plan') || ql.contains('finding'))
      return "**CAPA — Corrective & Preventive Action Guide:**\n\n**For a blocked fire exit (Critical finding):**\n1. **Immediate (0–24 hours):** Remove all obstructions. Photograph before and after. Mark the area with floor tape.\n2. **Short-term (1–7 days):** Install 'No Storage' signage. Assign responsible person for daily inspection.\n3. **Preventive:** Include exit corridor in weekly housekeeping checklist. Raise CA in FireShield AI for tracking.\n\n**For expired extinguishers (Critical):**\n1. **Immediate:** Tag out-of-service extinguishers. Replace with temporary units from stores.\n2. **Short-term (3 days):** Issue AMC work order to certified agency for refill/hydro-test.\n3. **Preventive:** Set 90-day advance reminder in equipment tracker.\n\n**CAPA Documentation Format:**\n• Finding reference (audit ID + item number)\n• Root cause (why did this happen?)\n• Corrective action (what was done?)\n• Preventive action (how to stop recurrence?)\n• Responsible person + due date + closure evidence\n\nShall I generate a CAPA template for a specific finding?";

    // Fallback — broad but useful
    return "**Fire Safety Compliance Reference:**\n\nBased on applicable Indian standards for your query:\n\n**Key Standards Coverage:**\n• NBC 2016 Part 4 — Fire & Life Safety (all building types)\n• IS 2189:2008 — Fire Detection & Alarm Systems\n• IS 2190:2010 — Selection, Installation & Maintenance of Extinguishers\n• IS 3844 — Code of Practice for Installation of Internal Fire Hydrants\n• IS 15105 — Automatic Sprinkler Systems (aligned with NFPA 13)\n• IS 1944 — Emergency Lighting\n• OISD-116/117/118 — Petroleum & Petrochemical facilities\n• PESO Act — Explosive & Flammable substances licensing\n• NABH — Hospital Fire Safety Standards\n\n**Common Audit Focus Areas:**\n• Fire exits — width, distance, obstructions, door hardware\n• Detection & alarm — coverage, zoning, test records\n• Suppression — sprinkler, hydrant, portable extinguishers\n• Emergency lighting — coverage, backup duration, testing\n• Documentation — NOC validity, drill records, AMC certificates\n\nTry a specific query such as a facility type (hospital, mall, school) or equipment type (sprinkler, hydrant, extinguisher) for detailed clause references.";
  }

  void _nextRelease(BuildContext ctx) => ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(content: Text('This feature is available in the next release.'), duration: Duration(seconds: 2)),
  );

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fire Safety Assistant', style: AppTextStyles.h5),
          Text('Compliance Reference — NBC / BIS / OISD / PESO', style: AppTextStyles.caption),
        ]),
      ]),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.of(context).pop()),
      actions: [
        IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () => _nextRelease(context)),
        IconButton(icon: const Icon(Icons.add_comment_rounded), onPressed: () => setState(() { _messages.clear(); _messages.add(const MockChatMessage(id: 'init', text: "Hello! I'm your Fire Safety AI Assistant. How can I help you today?", sender: 'AI Assistant', isUser: false)); })),
      ],
    ),
    body: Column(
      children: [
        // Capability banner
        Container(
          color: AppColors.infoLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.info),
            const SizedBox(width: 6),
            Expanded(child: Text('Trained on NBC 2016 · IS Standards · OISD · PESO · NABH · DGCA', style: AppTextStyles.caption.copyWith(color: AppColors.info))),
          ]),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (_, i) {
              if (_thinking && i == _messages.length) return const _ThinkingBubble();
              return _MessageBubble(message: _messages[i]);
            },
          ),
        ),
        // Suggestions
        if (_messages.length <= 3)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => _send(s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                  child: Text(s, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500), maxLines: 1),
                ),
              )).toList(),
            ),
          ),
        // Input
        _InputBar(controller: _ctrl, onSend: _send, thinking: _thinking),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final MockChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(4), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
          child: Text(message.text, style: AppTextStyles.bodySmall.copyWith(color: Colors.white, height: 1.5)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
            child: Row(children: [
              Container(width: 24, height: 24, decoration: const BoxDecoration(gradient: AppColors.blueGradient, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, size: 14, color: Colors.white)),
              const SizedBox(width: 6),
              const Text('AI Assistant', style: AppTextStyles.caption),
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)), border: Border.all(color: AppColors.borderLight), boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)]),
            child: _RichText(text: message.text),
          ),
          Row(children: [
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.copy_rounded, size: 14), color: AppColors.textHint, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Available in next release.'), duration: Duration(seconds: 2))), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.thumb_up_outlined, size: 14), color: AppColors.textHint, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback noted — available in next release.'), duration: Duration(seconds: 2))), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.thumb_down_outlined, size: 14), color: AppColors.textHint, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback noted — available in next release.'), duration: Duration(seconds: 2))), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ],
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  final String text;
  const _RichText({required this.text});

  @override
  Widget build(BuildContext context) {
    // Simple bold parsing for ** **
    final spans = <TextSpan>[];
    final parts = text.split('\n');
    for (final part in parts) {
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(TextSpan(text: '${part.substring(2, part.length - 2)}\n', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)));
      } else {
        spans.add(TextSpan(text: '$part\n', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.6)));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();
  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderLight)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.info),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(children: [1, 2, 3].map((i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7, height: 7,
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: _ctrl.value > (i - 1) / 3 ? 1.0 : 0.3), shape: BoxShape.circle),
          )).toList()),
        ),
        const SizedBox(width: 8),
        const Text('Analysing regulations...', style: AppTextStyles.caption),
      ]),
    ),
  );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool thinking;
  const _InputBar({required this.controller, required this.onSend, required this.thinking});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.borderLight))),
    padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewInsets.bottom),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.mic_rounded, color: AppColors.textSecondary), onPressed: thinking ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice input available in next release.'), duration: Duration(seconds: 2)))),
      Expanded(
        child: TextField(
          controller: controller,
          onSubmitted: thinking ? null : onSend,
          maxLines: null,
          style: AppTextStyles.bodySmall,
          decoration: const InputDecoration(hintText: 'Ask about NBC 2016, BIS standards, OISD...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: AppColors.primary))),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        decoration: BoxDecoration(gradient: thinking ? const LinearGradient(colors: [AppColors.textHint, AppColors.textHint]) : AppColors.primaryGradient, shape: BoxShape.circle),
        child: IconButton(
          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          onPressed: thinking ? null : () => onSend(controller.text),
        ),
      ),
    ]),
  );
}
