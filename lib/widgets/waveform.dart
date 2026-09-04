import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

/// 録音画面の飾りとなる波のリボン。録音していない間も常にゆったり漂い、
/// 録音中だけ振幅が大きくなって反応する。
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
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsStore>().accentColor;
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavePainter(
              phase: _controller.value * 2 * pi,
              active: widget.active,
              color: accent,
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
  final double verticalOffset;

  const _WaveLayer({
    required this.frequency,
    required this.amplitudeScale,
    required this.speed,
    required this.opacity,
    required this.strokeWidth,
    this.verticalOffset = 0,
  });
}

class _WavePainter extends CustomPainter {
  final double phase;
  final bool active;
  final Color color;

  // speedは必ず整数にする。AnimationControllerのrepeat()はvalue(=phaseの元)を
  // 1.0から0.0へ瞬間的に巻き戻すため、phase*speedが整数周期でなければループの
  // 継ぎ目でsin波の位相がズレて「アニメーションの切り替わり」が見えてしまう。
  static const _layers = [
    _WaveLayer(
      frequency: 0.9,
      amplitudeScale: 1.0,
      speed: 1,
      opacity: 0.85,
      strokeWidth: 18,
    ),
    _WaveLayer(
      frequency: 1.3,
      amplitudeScale: 0.68,
      speed: -2,
      opacity: 0.45,
      strokeWidth: 14,
      verticalOffset: 8,
    ),
    _WaveLayer(
      frequency: 0.6,
      amplitudeScale: 0.5,
      speed: 1,
      opacity: 0.28,
      strokeWidth: 12,
      verticalOffset: -10,
    ),
  ];

  _WavePainter({required this.phase, required this.active, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final midY = size.height / 2;
    // アイドル時も飾りのリボンとして見せつつ、録音中は振幅を大きくして反応させる。
    final amplitude = active ? size.height * 0.34 : size.height * 0.17;

    for (final layer in _layers) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 4) {
        final t = x / size.width;
        final y = midY +
            layer.verticalOffset +
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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
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
