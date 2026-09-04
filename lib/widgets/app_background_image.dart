import 'package:flutter/material.dart';

/// 各画面の全面背景。ダークモード設定に連動した単色（黒/白）。
class AppBackgroundImage extends StatelessWidget {
  const AppBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
  }
}
