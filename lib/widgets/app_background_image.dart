import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_store.dart';

/// 各画面の全面背景。既定はダークモード設定に連動した単色（黒/白）だが、
/// Pro限定機能として設定画面から自分の画像を背景に設定できる
/// （[SettingsStore.customBackgroundPath]）。カード・テキストの可読性を保つため、
/// 画像の上には常にscaffoldBackgroundColorの薄い暗幕を重ねる。
class AppBackgroundImage extends StatelessWidget {
  const AppBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final customPath = context.watch<SettingsStore>().customBackgroundPath;

    if (customPath == null) {
      return ColoredBox(color: scaffoldColor);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(customPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              ColoredBox(color: scaffoldColor),
        ),
        Container(color: scaffoldColor.withValues(alpha: 0.4)),
      ],
    );
  }
}
