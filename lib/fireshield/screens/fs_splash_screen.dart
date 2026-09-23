import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../fs_app_state.dart';
import '../theme/fs_tokens.dart';

/// Port of pwa_app/src/screens/SplashScreen.jsx
///
/// Progress ticks every 120ms by a random 6–24, four phase labels, then
/// routes to the user's dashboard or /welcome.
class FsSplashScreen extends StatefulWidget {
  const FsSplashScreen({super.key});

  @override
  State<FsSplashScreen> createState() => _FsSplashScreenState();
}

class _FsSplashScreenState extends State<FsSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _phases = [
    'Initialising platform...',
    'Loading NBC 2026 standards...',
    'Connecting services...',
    'Ready',
  ];

  late final AnimationController _rings;
  Timer? _timer;
  final _rand = Random();
  double _progress = 0;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted) return;
      setState(() {
        final next = _progress + (_rand.nextDouble() * 18 + 6);
        _progress = next >= 100 ? 100 : min(next, 99);

        if (_progress >= 25) _phase = 1;
        if (_progress >= 60) _phase = 2;
        if (_progress >= 95) _phase = 3;
      });

      if (_progress >= 100) {
        t.cancel();
        Timer(const Duration(milliseconds: 400), _go);
      }
    });
  }

  void _go() {
    if (!mounted) return;
    final state = FsAppState.instance;
    context.go(state.isAuthenticated ? state.homeRoute : '/welcome');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: FsColors.darkGradient),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding ring layers.
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _rings,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        _ring(
                          base: 160.0 + i * 60,
                          t: (_rings.value + i * 0.33) % 1.0,
                        ),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FsColors.heroYellow.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Centre cluster.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _logo(),
                  const SizedBox(height: 32),
                  _brand(),
                  const SizedBox(height: 32),
                  _standards(),
                  const SizedBox(height: 32),
                  _progressBar(),
                ],
              ),

              // Footer.
              Positioned(
                bottom: 40,
                child: Column(
                  children: [
                    Text(
                      'Built by EY Technology Consulting',
                      style: FsText.tiny.copyWith(
                        color: FsColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v2.0.0 · NBC 2026 · BIS · OISD · PESO',
                      style: FsText.micro.copyWith(color: FsColors.gray700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ring({required double base, required double t}) => Opacity(
        opacity: (1 - t) * 0.6,
        child: Container(
          width: base * (0.7 + t * 0.5),
          height: base * (0.7 + t * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
      );

  Widget _logo() => SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: FsColors.flameGradient,
                borderRadius: BorderRadius.circular(FsRadius.xl3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 44)),
            ),
            // EY badge, bottom-right.
            Positioned(
              right: 0,
              bottom: 4,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FsColors.heroYellow,
                  borderRadius: BorderRadius.circular(FsRadius.xl),
                  boxShadow: FsShadows.cardMd,
                ),
                child: const Text(
                  'EY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: FsColors.gray900,
                  ),
                ),
              ),
            ),
            // AI badge, top-right.
            Positioned(
              right: 2,
              top: 4,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: FsColors.roleManager,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _brand() => Column(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: FsText.family,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.0,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'FireShield'),
                TextSpan(
                  text: ' AI™',
                  style: TextStyle(color: FsColors.heroYellow),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FIRE SAFETY OPERATING SYSTEM',
            style: FsText.small.copyWith(
              color: FsColors.gray400,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ],
      );

  Widget _standards() => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: ['NBC 2026', 'IS 2189', 'OISD', 'PESO', 'NABH']
            .map(
              (s) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FsRadius.full),
                  border: Border.all(color: FsColors.gray700),
                ),
                child: Text(
                  s,
                  style: FsText.tiny.copyWith(
                    color: FsColors.gray400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      );

  Widget _progressBar() => SizedBox(
        width: 224,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _phases[_phase],
                  style: FsText.tiny.copyWith(color: FsColors.gray500),
                ),
                Text(
                  '${_progress.round()}%',
                  style: FsText.tiny.copyWith(
                    color: FsColors.heroYellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(FsRadius.full),
              child: LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 2,
                backgroundColor: FsColors.gray800,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(FsColors.heroYellow),
              ),
            ),
          ],
        ),
      );
}
