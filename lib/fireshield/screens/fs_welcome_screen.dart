import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/fs_tokens.dart';

/// Port of pwa_app/src/screens/WelcomeScreen.jsx — the page at
/// https://pwaapp-ochre.vercel.app/welcome
class FsWelcomeScreen extends StatefulWidget {
  const FsWelcomeScreen({super.key});

  @override
  State<FsWelcomeScreen> createState() => _FsWelcomeScreenState();
}

class _FsWelcomeScreenState extends State<FsWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping;

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

  static const _features = [
    ('🏛️', 'NBC 2026', 'Part 4 Compliant'),
    ('📊', 'Digital Audits', 'Floor-wise & Room-wise'),
    ('📄', 'NOC Ready', 'Regulatory Compliant'),
  ];

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: FsColors.darkGradient),
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildHero(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildCard(),
                        ),
                        const Spacer(),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: FsColors.heroYellow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'EY',
                style: TextStyle(
                  color: FsColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Assurance · Tax · Strategy · Transactions',
                style: FsText.small.copyWith(
                  color: FsColors.gray400,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _buildHero() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(
                    3,
                    (i) => AnimatedBuilder(
                      animation: _ping,
                      builder: (_, __) {
                        final t = (_ping.value + i / 3) % 1.0;
                        return Opacity(
                          opacity: (1 - t) * 0.9,
                          child: Container(
                            width: 80 + (t * 60),
                            height: 80 + (t * 60),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FsColors.primary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: FsColors.flameGradient,
                      borderRadius: BorderRadius.circular(FsRadius.xl3),
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
                color: FsColors.heroYellow.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 280,
              child: Text(
                'Next-Generation Fire Audit Readiness Platform',
                textAlign: TextAlign.center,
                style: FsText.xs.copyWith(
                  color: FsColors.gray400,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: _standards
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(FsRadius.full),
                        border: Border.all(
                          color:
                              FsColors.gray700.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        s,
                        style: FsText.micro.copyWith(
                          color: FsColors.gray400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

  Widget _buildCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(FsRadius.xl3),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            Text(
              'A next-generation fire audit readiness and compliance platform '
              'designed to help organisations digitally assess fire safety '
              'preparedness, identify compliance gaps, streamline audit '
              'activities and improve overall fire readiness.',
              style: FsText.xs
                  .copyWith(color: FsColors.gray400, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'The platform follows applicable fire safety codes, standards '
              'and regulatory requirements and is designed to support '
              'evidence-based inspections and digital compliance management.',
              style: FsText.xs
                  .copyWith(color: FsColors.gray400, height: 1.6),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _featureTile(_features[i])),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _featureTile((String, String, String) f) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(f.$1, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              f.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              f.$3,
              textAlign: TextAlign.center,
              style: FsText.micro
                  .copyWith(color: FsColors.gray400, fontSize: 8),
            ),
          ],
        ),
      );

  Widget _buildActions() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FsColors.heroYellow,
                  foregroundColor: FsColors.ink,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FsRadius.xl2),
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
                onPressed: () => context.go('/tour'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FsRadius.xl2),
                  ),
                ),
                child: const Text(
                  'Take a Tour',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Powered by EY · Compliant with NBC 2026 · BIS · OISD · PESO',
              textAlign: TextAlign.center,
              style: FsText.micro.copyWith(color: FsColors.gray600),
            ),
          ],
        ),
      );
}
