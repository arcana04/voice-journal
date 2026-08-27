import 'package:flutter/material.dart';

import '../models/diary_background.dart';
import 'app_background_image.dart';

/// 日記の編集・閲覧画面の全面背景。[backgroundId]（ノートに設定された
/// [DiaryBackground]）があればそれを、無ければ他の画面と同じアプリ全体の
/// 背景画像（[AppBackgroundImage]）を表示する。
///
/// 背景素材は画面比率（縦横比およそ0.45〜0.46）に合わせて用意されている前提
/// なので、`BoxFit.cover`でもほぼ切れずに収まる。
class DiaryScreenBackground extends StatelessWidget {
  final String? backgroundId;

  const DiaryScreenBackground({super.key, required this.backgroundId});

  @override
  Widget build(BuildContext context) {
    final background = DiaryBackground.fromId(backgroundId);
    if (background == null) return const AppBackgroundImage();
    return Image.asset(background.asset, fit: BoxFit.cover);
  }
}
