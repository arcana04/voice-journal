import 'package:flutter/material.dart';

import '../config/theme_colors.dart';

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
    final color = isRecording ? colorScheme.error : kRecordAccentColor;

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 4,
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
    );
  }
}
