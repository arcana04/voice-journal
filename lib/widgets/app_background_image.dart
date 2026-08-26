import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/background_store.dart';

/// 各画面の全面背景。ユーザーが設定で共通の背景を選んでいればそれを、
/// 選んでいなければ[fallbackAsset]（その画面固有のデフォルト背景）を表示する。
class AppBackgroundImage extends StatelessWidget {
  final String fallbackAsset;

  const AppBackgroundImage({super.key, required this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<BackgroundStore>().selected;
    return Image.asset(selected?.asset ?? fallbackAsset, fit: BoxFit.cover);
  }
}
