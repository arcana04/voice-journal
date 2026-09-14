import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

enum WaveformMode { idle, recording, processing }

/// 録音中だけ、テーマのアクセントカラー設定に関わらずこの赤で固定する
/// （ユーザー指示）。アイドル時・処理中はテーマのアクセントカラーのまま。
const _kRecordingColor = Color(0xFFE53935);

/// 録音画面の飾りとなる波のリボン。録音していない間も常にゆったり漂い、
/// 録音中はマイクの入力音量（[micLevel]、0〜1に正規化済み）に応じて振幅と
/// 波の密度がリアルタイムに揺らめき、AI処理中は「考えている」ように
/// 呼吸するような明滅で脈打つ。
class Waveform extends StatefulWidget {
  final WaveformMode mode;
  final double micLevel;
  const Waveform({super.key, required this.mode, this.micLevel = 0.0});

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // widget.micLevelは300msごとの離散サンプルなので、そのまま使うと値が
  // 飛んでカクついて見える。毎フレーム(_controllerのtickごと)少しずつ
  // 追従させることで、サンプリング間隔に関係なく滑らかな動きにする。
  double _smoothedLevel = 0.0;

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
    final color = widget.mode == WaveformMode.recording
        ? _kRecordingColor
        : accent;
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          _smoothedLevel += (widget.micLevel - _smoothedLevel) * 0.08;
          return CustomPaint(
            painter: _WavePainter(
              phase: _controller.value * 2 * pi,
              mode: widget.mode,
              color: color,
              micLevel: _smoothedLevel,
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
  final WaveformMode mode;
  final Color color;
  final double micLevel;

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

  _WavePainter({
    required this.phase,
    required this.mode,
    required this.color,
    required this.micLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final midY = size.height / 2;
    // アイドル時も飾りのリボンとして見せつつ、録音中は振幅を大きくして反応、
    // 処理中はゆっくり呼吸するように振幅そのものを上下させて「考えている」感を出す。
    final isProcessing = mode == WaveformMode.processing;
    final isRecording = mode == WaveformMode.recording;
    final breathe = isProcessing ? 0.5 + 0.5 * sin(phase * 0.6) : 0.0;
    // 録音中はマイクの実音量([micLevel]、無音=0〜大声=1)に応じて振幅そのものを
    // 揺らめかせる。無音時でも完全に平らにならないよう最低限のベース振幅は残す。
    final baseAmplitude = switch (mode) {
      WaveformMode.recording => size.height * (0.10 + 0.34 * micLevel),
      WaveformMode.processing => size.height * (0.20 + 0.10 * breathe),
      WaveformMode.idle => size.height * 0.17,
    };
    // 真の周波数解析(FFT)は行わないため、音量が大きいほど波が細かく詰まって
    // 見えるように各レイヤーの周波数を上げることで「揺らめき」の代用にする。
    final frequencyBoost = isRecording ? 1.0 + micLevel * 1.2 : 1.0;

    for (final layer in _layers) {
      final path = Path();
      for (double x = 0; x <= size.width; x += 4) {
        final t = x / size.width;
        final y = midY +
            layer.verticalOffset +
            sin(t * 2 * pi * layer.frequency * frequencyBoost + phase * layer.speed) *
                baseAmplitude *
                layer.amplitudeScale;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      // 処理中は各レイヤーの明滅タイミングをずらし、光がリボンの上を
      // 流れていくようなシマー(shimmer)効果を作る。
      final opacity = isProcessing
          ? layer.opacity *
                (0.5 + 0.5 * sin(phase * 1.4 + layer.frequency * 3))
          : layer.opacity;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
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
        oldDelegate.mode != mode ||
        oldDelegate.color != color ||
        oldDelegate.micLevel != micLevel;
  }
}
