import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

enum RecordButtonState { idle, recording, processing }

class RecordButton extends StatefulWidget {
  final RecordButtonState state;
  final VoidCallback onTap;

  const RecordButton({super.key, required this.state, required this.onTap});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 待機/録音中は使わず、処理中の外側オーラの呼吸と中央の思考ドットだけに使う。
    // 常時repeatさせておいても軽量なので、Waveformと同じく都度の開始/停止管理は省く。
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRecording = widget.state == RecordButtonState.recording;
    final isProcessing = widget.state == RecordButtonState.processing;
    final color = isRecording
        ? colorScheme.error
        : context.watch<SettingsStore>().accentColor;
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;
    final deepColor = Color.lerp(color, Colors.black, 0.12)!;

    return GestureDetector(
      onTap: isProcessing ? null : widget.onTap,
      child: SizedBox(
        width: 188,
        height: 188,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外側の柔らかいオーラ。処理中は「考えている」ように呼吸させて明滅する。
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final breathe = isProcessing
                    ? 0.5 + 0.5 * sin(_pulseController.value * 2 * pi)
                    : 0.0;
                final scale = isProcessing ? 1.0 + 0.06 * breathe : 1.0;
                final alpha = isProcessing ? 0.16 + 0.14 * breathe : 0.22;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 188,
                    height: 188,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: alpha),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // 本体: つや感のあるグラデーション球。
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.35),
                  colors: [lightColor, color, deepColor],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: isProcessing
                    ? _ThinkingDots(animation: _pulseController)
                    : Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AIが解析・仕分け中であることを示す、3つの点が波打つように弾む
/// 「思考中」インジケーター。単調なスピナーより、AIが今まさに考えている
/// という臨場感を伝える狙い。
class _ThinkingDots extends StatelessWidget {
  final Animation<double> animation;

  const _ThinkingDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (animation.value - i * 0.18) % 1.0;
            final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -6 * bounce),
                child: Opacity(
                  opacity: 0.5 + 0.5 * bounce,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
