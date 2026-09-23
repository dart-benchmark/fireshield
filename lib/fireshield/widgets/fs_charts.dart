/// Minimal chart primitives — enough to represent the PWA's Charts.jsx
/// (BarChart, HorizontalBarChart, DonutChart, TrendLine) faithfully in data
/// terms without pulling in a charting package.
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';

/// Vertical bar chart — `BarChart` in Charts.jsx.
class FsBarChart extends StatelessWidget {
  final List<(String, num)> data;
  final Color color;
  final double height;
  const FsBarChart({
    super.key,
    required this.data,
    this.color = FsColors.eyYellow,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = data.map((d) => d.$2).fold<num>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data
            .map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${d.$2}',
                            style: FsText.micro
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Container(
                          height: maxV == 0
                              ? 2
                              : (d.$2 / maxV) * (height - 30),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(d.$1, style: FsText.micro),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Horizontal bar chart — `HorizontalBarChart` in Charts.jsx.
class FsHorizontalBarChart extends StatelessWidget {
  final List<(String, num, Color)> data;
  const FsHorizontalBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxV = data.map((d) => d.$2).fold<num>(0, (a, b) => a > b ? a : b);
    return Column(
      children: data
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(d.$1,
                          style: FsText.tiny, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: FsColors.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: maxV == 0 ? 0 : d.$2 / maxV,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: d.$3,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      child: Text('${d.$2}',
                          style: FsText.micro
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// Donut chart with legend — `DonutChart` in Charts.jsx. Painted as a ring
/// built from stacked arcs.
class FsDonutChart extends StatelessWidget {
  final List<(num, Color)> segments;
  final double size;
  final double thickness;
  const FsDonutChart({
    super.key,
    required this.segments,
    this.size = 100,
    this.thickness = 18,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(segments: segments, thickness: thickness),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  final List<(num, Color)> segments;
  final double thickness;
  _DonutPainter({required this.segments, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<num>(0, (a, b) => a + b.$1);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    var start = -90 * (3.1415926535 / 180);
    for (final s in segments) {
      final sweep = (s.$1 / total) * 2 * 3.1415926535;
      final paint = Paint()
        ..color = s.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(thickness / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

/// Trend line — `TrendLine` in Charts.jsx.
class FsTrendLine extends StatelessWidget {
  final List<num> values;
  final Color color;
  final double height;
  const FsTrendLine({
    super.key,
    required this.values,
    this.color = FsColors.primary,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendPainter(values: values, color: color),
        ),
      );
}

class _TrendPainter extends CustomPainter {
  final List<num> values;
  final Color color;
  _TrendPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values;
}
