import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diary_background.dart';
import '../services/custom_background_service.dart';
import 'app_background_image.dart';

/// 日記の編集・閲覧画面の全面背景。[backgroundId]（ノートに設定された
/// [DiaryBackground]、またはPro限定機能で追加した自分の画像）があればそれを、
/// 無ければ他の画面と同じアプリ全体の背景画像（[AppBackgroundImage]）を表示する。
///
/// 背景素材は画面比率（縦横比およそ0.45〜0.46）に合わせて用意されている前提
/// なので、`BoxFit.cover`でもほぼ切れずに収まる（自分の画像は比率が異なりうる
/// ため多少のクロップが起きるが、これは想定内の挙動）。
class DiaryScreenBackground extends StatelessWidget {
  final String? backgroundId;

  const DiaryScreenBackground({super.key, required this.backgroundId});

  @override
  Widget build(BuildContext context) {
    final id = backgroundId;
    if (CustomBackgroundService.isCustomBackgroundId(id)) {
      return Image.file(
        File(CustomBackgroundService.pathFromId(id!)),
        fit: BoxFit.cover,
      );
    }
    final background = DiaryBackground.fromId(id);
    if (background == null) return const AppBackgroundImage();
    return Image.asset(background.asset, fit: BoxFit.cover);
  }
}
