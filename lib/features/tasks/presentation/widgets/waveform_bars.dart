import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskbite/core/themes/colors.dart';

/// Lightweight animated waveform visualization.
///
/// Samples the live input level on a timer (modest framerate) and repaints only
/// the canvas — no widget tree rebuilds happen per sample, which keeps the
/// recording UI cheap even on low-end devices.
///
/// The bars are driven purely by [levelListenable], which in production is fed
/// from the recorder's real amplitude stream. Silence draws a flat row of
/// minimal bars rather than an animation that runs independently of the
/// microphone.
class WaveformBars extends StatefulWidget {
  const WaveformBars({
    super.key,
    required this.levelListenable,
    this.color = AppColors.primary,
    this.height = 64,
    this.barCount = 24,
    this.sampleInterval = const Duration(milliseconds: 66),
  });

  /// Source of the live 0.0..1.0 input level.
  final ValueListenable<double> levelListenable;
  final Color color;
  final double height;
  final int barCount;
  final Duration sampleInterval;

  @override
  State<WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<WaveformBars> {
  late final List<double> _levels;
  Timer? _timer;
  int _cursor = 0;

  @override
  void initState() {
    super.initState();
    _levels = List<double>.filled(widget.barCount, 0);
    _timer = Timer.periodic(widget.sampleInterval, (_) {
      if (!mounted) return;
      final raw = widget.levelListenable.value.clamp(0.0, 1.0);
      _cursor = (_cursor + 1) % widget.barCount;
      _levels[_cursor] = raw;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          levels: List<double>.unmodifiable(_levels),
          color: widget.color,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final int count = levels.length;
    final double step = size.width / (count * 2 - 1);
    final double barWidth = step * 0.7;
    final Paint paint =
        Paint()
          ..color = color
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final double h = (size.height * levels[i]).clamp(8.0, size.height);
      final double x = step / 2 + i * step * 2;
      final double y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.levels != levels || oldDelegate.color != color;
}
