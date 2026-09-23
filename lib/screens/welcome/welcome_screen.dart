import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Welcome screen — Flutter port of the EY FireShield AI PWA welcome page
/// at https://pwaapp-ochre.vercel.app/welcome
///
/// Colours, sizes, radii and spacing are taken from the live page's computed
/// styles rather than eyeballed, so this should sit pixel-close to the React
/// original at a 375pt viewport.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping;

  @override
  void initState() {
    super.initState();
    // Drives the three expanding rings behind the logo (Tailwind animate-ping).
    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: EyWelcome.pageGradient),
        child: SafeArea(
          bottom: false,
          // Fills the viewport on tall screens and scrolls on short ones.
          // IntrinsicHeight gives the Column a bounded height so the Spacer
          // has something to push against inside the scroll view.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const _Header(),
                      _Hero(ping: _ping),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _WelcomeCard(),
                      ),
                      const Spacer(),
                      _Actions(
                        onGetStarted: () => context.go('/login'),
                        onTakeTour: () => _showTour(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTour(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EyWelcome.surface,
      // Scrollable and height-capped so the sheet still works on short
      // screens instead of running past the bottom of the viewport.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'How FireShield works',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ..._tourSteps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: EyWelcome.eyYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_tourSteps.indexOf(s) + 1}',
                            style: const TextStyle(
                              color: EyWelcome.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.$1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.$2,
                                style: const TextStyle(
                                  color: EyWelcome.gray400,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EyWelcome.eyYellow,
                    foregroundColor: EyWelcome.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<(String, String)> _tourSteps = [
    (
      'Classify the building',
      'Pick the occupancy group and subdivision. That decides which NBC and BIS checkpoints apply.'
    ),
    (
      'Run the checklist',
      'Answer each checkpoint yes, no or not applicable, with photo evidence and remarks.'
    ),
    (
      'Read the risk score',
      'Severity-weighted compliance, section breakdown and whether the site clears the NOC bar.'
    ),
    (
      'Close the CAPAs',
      'Every failure raises a corrective and preventive action with an owner and a due date.'
    ),
  ];
}

// ─── Design tokens, lifted from the live page ──────────────────────────────

class EyWelcome {
  const EyWelcome._();

  static const eyYellow = Color(0xFFFACC15);
  static const ink = Color(0xFF111827);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray600 = Color(0xFF4B5563);
  static const surface = Color(0xFF1A1225);
  static const flameFrom = Color(0xFFD32F2F);
  static const flameTo = Color(0xFFB71C1C);

  /// linear-gradient(160deg, #0F0F1A 0%, #1A1225 55%, #0D1117 100%)
  static const pageGradient = LinearGradient(
    begin: Alignment(-0.34, -1),
    end: Alignment(0.34, 1),
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1225), Color(0xFF0D1117)],
    stops: [0.0, 0.55, 1.0],
  );

  static Color get glassFill => Colors.white.withValues(alpha: 0.05);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.08);
  static Color get chipBorder =>
      const Color(0xFF374151).withValues(alpha: 0.6);
}

// ─── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EyWelcome.eyYellow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'EY',
                style: TextStyle(
                  color: EyWelcome.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Assurance · Tax · Strategy · Transactions',
                style: TextStyle(
                  color: EyWelcome.gray400,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ─── Hero ──────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final AnimationController ping;
  const _Hero({required this.ping});

  static const _standards = [
    'NBC 2026',
    'IS 2189',
    'NABH',
    'OISD',
    'PESO',
    'IS 2190',
    'IS 3844',
    'IS 15105',
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (i) => _PingRing(ping: ping, index: i)),
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [EyWelcome.flameFrom, EyWelcome.flameTo],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 36)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FireShield AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.25,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'by EY',
              style: TextStyle(
                color: EyWelcome.eyYellow.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 280,
              child: Text(
                'Next-Generation Fire Audit Readiness Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EyWelcome.gray400,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: _standards.map((s) => _StandardChip(label: s)).toList(),
            ),
          ],
        ),
      );
}

class _PingRing extends StatelessWidget {
  final AnimationController ping;
  final int index;
  const _PingRing({required this.ping, required this.index});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ping,
        builder: (_, __) {
          // Stagger the three rings across the cycle.
          final t = (ping.value + index / 3) % 1.0;
          return Opacity(
            opacity: (1 - t) * 0.9,
            child: Container(
              width: 80 + (t * 60),
              height: 80 + (t * 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EyWelcome.flameFrom.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        },
      );
}

class _StandardChip extends StatelessWidget {
  final String label;
  const _StandardChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EyWelcome.chipBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: EyWelcome.gray400,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─── Welcome card ──────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  static const _features = [
    ('🏛️', 'NBC 2026', 'Part 4 Compliant'),
    ('📊', 'Digital Audits', 'Floor-wise & Room-wise'),
    ('📄', 'NOC Ready', 'Regulatory Compliant'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EyWelcome.glassFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: EyWelcome.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to FireShield AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A next-generation fire audit readiness and compliance platform '
              'designed to help organisations digitally assess fire safety '
              'preparedness, identify compliance gaps, streamline audit '
              'activities and improve overall fire readiness.',
              style: TextStyle(
                color: EyWelcome.gray400,
                fontSize: 11,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The platform follows applicable fire safety codes, standards '
              'and regulatory requirements and is designed to support '
              'evidence-based inspections and digital compliance management.',
              style: TextStyle(
                color: EyWelcome.gray400,
                fontSize: 11,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _FeatureTile(
                      emoji: _features[i].$1,
                      title: _features[i].$2,
                      subtitle: _features[i].$3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}

class _FeatureTile extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EyWelcome.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EyWelcome.gray400,
                fontSize: 8,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

// ─── Actions ───────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onTakeTour;
  const _Actions({required this.onGetStarted, required this.onTakeTour});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EyWelcome.eyYellow,
                  foregroundColor: EyWelcome.ink,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onTakeTour,
                style: OutlinedButton.styleFrom(
                  backgroundColor: EyWelcome.glassFill,
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Take a Tour',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Powered by EY · Compliant with NBC 2026 · BIS · OISD · PESO',
              textAlign: TextAlign.center,
              style: TextStyle(color: EyWelcome.gray600, fontSize: 9),
            ),
          ],
        ),
      );
}
