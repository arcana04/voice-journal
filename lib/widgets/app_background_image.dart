import 'package:flutter/material.dart';

/// 各画面の全面背景。海外展開を見据え、装飾イラストではなくダークモード設定に
/// 連動した単色（黒/白）にしている。
class AppBackgroundImage extends StatelessWidget {
  const AppBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
  }
}
