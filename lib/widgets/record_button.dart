import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

enum RecordButtonState { idle, recording, processing }

class RecordButton extends StatelessWidget {
  final RecordButtonState state;
  final VoidCallback onTap;

  const RecordButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRecording = state == RecordButtonState.recording;
    final isProcessing = state == RecordButtonState.processing;
    final color = isRecording
        ? colorScheme.error
        : context.watch<SettingsStore>().accentColor;
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;
    final deepColor = Color.lerp(color, Colors.black, 0.12)!;

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: SizedBox(
        width: 216,
        height: 216,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外側の柔らかいオーラ。
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 216,
              height: 216,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // 本体: つや感のあるグラデーション球。
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 176,
              height: 176,
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
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
