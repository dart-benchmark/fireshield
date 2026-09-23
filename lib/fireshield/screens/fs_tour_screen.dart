import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/fs_tokens.dart';

/// Port of pwa_app/src/screens/TourScreen.jsx
///
/// Role picker, then a three-slide carousel per role. Slides render one of
/// three visual types: dotted list, plain list, or a stats grid.
class FsTourScreen extends StatefulWidget {
  const FsTourScreen({super.key});

  @override
  State<FsTourScreen> createState() => _FsTourScreenState();
}

enum TourVisual { dotted, list, stats }

class TourSlide {
  final String icon;
  final String title;
  final String body;
  final TourVisual type;

  /// (label, sub-or-value, accent) — accent is a dot colour for [dotted]
  /// and a value colour for [stats].
  final List<(String, String, Color?)> visual;

  const TourSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.type,
    required this.visual,
  });
}

class RoleTour {
  final String key;
  final String role;
  final Color color;
  final String icon;
  final List<TourSlide> slides;

  const RoleTour({
    required this.key,
    required this.role,
    required this.color,
    required this.icon,
    required this.slides,
  });
}

const _green = Color(0xFF10B981);
const _blue = Color(0xFF3B82F6);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _grey = Color(0xFF6B7280);

const List<RoleTour> tours = [
  RoleTour(
    key: 'admin',
    role: 'Platform Admin',
    color: Color(0xFF7C3AED),
    icon: '🛡️',
    slides: [
      TourSlide(
        icon: '🏛️',
        title: 'Manage Organisations',
        body: 'Register and manage organisations, facilities, buildings and users. Maintain a complete hierarchy from enterprise group level down to individual building floors.',
        type: TourVisual.dotted,
        visual: [
          ('Phoenix Group', '6 Facilities · Karnataka', _green),
          ('Apollo Hospitals Group', '14 Facilities · Pan India', _blue),
          ('Larsen & Toubro', '22 Facilities · Pan India', _amber),
        ],
      ),
      TourSlide(
        icon: '📊',
        title: 'Monitor Compliance',
        body: 'Track compliance status, open findings and audit readiness across all organisations and facilities on a single enterprise dashboard.',
        type: TourVisual.stats,
        visual: [
          ('Overall Compliance', '84%', _green),
          ('Open Findings', '40', _amber),
          ('Critical CAPAs', '5', _red),
          ('Pending Audits', '15', _blue),
        ],
      ),
      TourSlide(
        icon: '📑',
        title: 'Reports & Analytics',
        body: 'Generate compliance reports, NOC readiness certificates and organisation-wide analytics dashboards for executive and regulatory stakeholders.',
        type: TourVisual.list,
        visual: [
          ('Audit Summary Report', 'PDF · 12–18 pages', null),
          ('NOC Readiness Certificate', 'PDF · Official Format', null),
          ('Risk Register', 'NBC 2026 Gap Mapping', null),
          ('Govt Submission Package', 'Regulatory Format', null),
        ],
      ),
    ],
  ),
  RoleTour(
    key: 'manager',
    role: 'Safety Manager',
    color: Color(0xFF1D4ED8),
    icon: '📊',
    slides: [
      TourSlide(
        icon: '🏢',
        title: 'Manage Facilities',
        body: 'Maintain facility profiles, documentation, fire NOC status, asset inventory and emergency response plans for all facilities under your organisation.',
        type: TourVisual.list,
        visual: [
          ('Facility Profile', 'Address · Floors · Area · Coordinates', null),
          ('Document Vault', 'Fire NOC · Drawings · ERP · Certs', null),
          ('Asset Inventory', 'Extinguishers · Detectors · Hydrants', null),
        ],
      ),
      TourSlide(
        icon: '👷',
        title: 'Assign Auditors',
        body: 'Assign single or multiple auditors to buildings, floors or rooms. Set priorities, due dates and track audit progress in real time.',
        type: TourVisual.dotted,
        visual: [
          ('Priya Nair', 'Lead Auditor · Ground Floor', _green),
          ('Amit Sharma', 'Auditor · Basement B1 & B2', _blue),
          ('Ravi Kumar', 'Auditor · Floors 1–3', _amber),
        ],
      ),
      TourSlide(
        icon: '⚠️',
        title: 'Corrective Actions',
        body: 'Track findings raised during audits, assign corrective actions to responsible teams, monitor closure progress and verify remediation evidence.',
        type: TourVisual.stats,
        visual: [
          ('Open Findings', '40', _red),
          ('In Progress', '12', _amber),
          ('Closed', '120', _green),
        ],
      ),
    ],
  ),
  RoleTour(
    key: 'auditor',
    role: 'Field Auditor',
    color: Color(0xFFDC2626),
    icon: '🔍',
    slides: [
      TourSlide(
        icon: '📋',
        title: 'Conduct Audits',
        body: 'Perform detailed floor-wise and room-wise fire safety audits using dynamic checklists generated from NBC 2026, IS standards and facility-specific requirements.',
        type: TourVisual.dotted,
        visual: [
          ('Basement 2', 'Car Park · Pump Room · Substation', _grey),
          ('Ground Floor', 'Atrium · Retail · Fire Control Room', Color(0xFFDC2626)),
          ('First Floor', 'Food Court · Retail · Electrical', _amber),
        ],
      ),
      TourSlide(
        icon: '📷',
        title: 'Collect Evidence',
        body: 'Capture geo-tagged photographs and observations for each finding. Attach supporting documents and link evidence directly to NBC 2026 clauses.',
        type: TourVisual.list,
        visual: [
          ('Photo Evidence', 'Geo-tagged · Timestamped', null),
          ('NBC Clause Link', 'NBC 2026 · IS 2189 · IS 2190', null),
          ('Severity Classification', 'Critical · High · Medium · Low', null),
        ],
      ),
      TourSlide(
        icon: '📤',
        title: 'Generate Reports',
        body: 'Submit audit findings digitally with automated report generation. Findings are auto-classified by severity with recommendations and target timelines.',
        type: TourVisual.stats,
        visual: [
          ('Critical Findings', '3', _red),
          ('High Findings', '8', _amber),
          ('Medium Findings', '14', _blue),
          ('Low Findings', '22', _grey),
        ],
      ),
    ],
  ),
];

class _FsTourScreenState extends State<FsTourScreen> {
  RoleTour? _selected;
  int _slide = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: FsColors.darkGradient),
          child: SafeArea(
            child: _selected == null ? _buildPicker() : _buildSlides(),
          ),
        ),
      );

  // ─── Role picker ────────────────────────────────────────────────────────

  Widget _buildPicker() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/welcome'),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Take a Tour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a role to see what the platform does for them.',
              style: FsText.small.copyWith(color: FsColors.gray400),
            ),
            const SizedBox(height: 24),
            ...tours.map(_buildRoleCard),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Skip tour →',
                  style: FsText.small.copyWith(
                    color: FsColors.heroYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRoleCard(RoleTour t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => setState(() {
            _selected = t;
            _slide = 0;
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(FsRadius.xl2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child:
                          Text(t.icon, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.role,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.slides.map((s) => s.title).join(' · '),
                            style:
                                FsText.tiny.copyWith(color: FsColors.gray500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: FsColors.gray600, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  // ─── Slides ─────────────────────────────────────────────────────────────

  Widget _buildSlides() {
    final tour = _selected!;
    final slide = tour.slides[_slide];
    final isLast = _slide == tour.slides.length - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (_slide > 0) {
                    _slide--;
                  } else {
                    _selected = null;
                  }
                }),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tour.role,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Skip',
                  style: FsText.small.copyWith(color: FsColors.gray400),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tour.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FsRadius.xl2),
                  ),
                  child: Text(slide.icon,
                      style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 20),
                Text(
                  slide.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.body,
                  style: FsText.small.copyWith(
                    color: FsColors.gray400,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                _buildVisual(slide, tour.color),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tour.slides.length,
                  (i) => Container(
                    width: i == _slide ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _slide
                          ? FsColors.heroYellow
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(FsRadius.full),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      context.go('/login');
                    } else {
                      setState(() => _slide++);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FsColors.heroYellow,
                    foregroundColor: FsColors.gray900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisual(TourSlide slide, Color accent) => switch (slide.type) {
        TourVisual.stats => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: slide.visual
                .map((v) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            v.$2,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: v.$3 ?? Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.$1,
                            style: FsText.tiny
                                .copyWith(color: FsColors.gray400),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        _ => Column(
            children: slide.visual
                .map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          if (slide.type == TourVisual.dotted) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: v.$3 ?? accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.$1,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  v.$2,
                                  style: FsText.tiny
                                      .copyWith(color: FsColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
      };
}
