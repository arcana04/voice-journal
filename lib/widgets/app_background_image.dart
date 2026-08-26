import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/background_store.dart';

/// 各画面の全面背景。設定で選んだ背景画像（デフォルトは星空）を表示する。
class AppBackgroundImage extends StatelessWidget {
  const AppBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<BackgroundStore>().selected;
    return Image.asset(selected.asset, fit: BoxFit.cover);
  }
}
