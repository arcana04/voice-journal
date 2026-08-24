import 'dart:math';

import 'package:flutter/material.dart';

class Waveform extends StatefulWidget {
  final bool active;
  const Waveform({super.key, required this.active});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavePainter(
              phase: _controller.value * 2 * pi,
              active: widget.active,
              color: Theme.of(context).colorScheme.primary,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveLayer {
  final double frequency;
  final double amplitudeScale;
  final double speed;
  final double opacity;
  final double strokeWidth;

  const _WaveLayer({
    required this.frequency,
    required this.amplitudeScale,
    required this.speed,
    required this.opacity,
    required this.strokeWidth,
  });
}

class _WavePainter extends CustomPainter {
  final double phase;
  final bool active;
  final Color color;

  static const _layers = [
    _WaveLayer(frequency: 1.1, amplitudeScale: 1.0, speed: 1.0, opacity: 0.9, strokeWidth: 3.5),
    _WaveLayer(frequency: 1.7, amplitudeScale: 0.55, speed: -1.5, opacity: 0.5, strokeWidth: 2.5),
    _WaveLayer(frequency: 0.7, amplitudeScale: 0.4, speed: 0.6, opacity: 0.3, strokeWidth: 2),
  ];

  _WavePainter({required this.phase, required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final amplitude = active ? size.height * 0.34 : size.height * 0.05;

    for (final layer in _layers) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 3) {
        final t = x / size.width;
        final y = midY +
            sin(t * 2 * pi * layer.frequency + phase * layer.speed) *
                amplitude *
                layer.amplitudeScale;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = color.withValues(alpha: layer.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer.strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.active != active ||
        oldDelegate.color != color;
  }
}
