import 'package:flutter/material.dart';

/// 背景画像の上に文字を直接置くと読みにくくなるため、半透明の背景を敷いて
/// 可読性を確保するための共通ラッパー。
class ScrimText extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ScrimText({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
