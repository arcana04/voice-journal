import 'package:flutter/material.dart';

import '../models/review_category.dart';

/// ボトムナビゲーションバーの日記/アイデア/タスクアイコンの画面上の位置を、
/// 離れたウィジェット（レビュー画面の保存演出など）から参照できるように
/// 保持するレジストリ。[FloatingNavBar]（[RootScreen]経由）が各アイコンに
/// このキーを割り当て、参照側は[rectFor]で現在の画面上の矩形を取得する。
class NavIconAnchors {
  NavIconAnchors._();
  static final NavIconAnchors instance = NavIconAnchors._();

  final Map<ReviewCategory, GlobalKey> _keys = {
    ReviewCategory.diary: GlobalKey(),
    ReviewCategory.idea: GlobalKey(),
    ReviewCategory.task: GlobalKey(),
  };

  GlobalKey keyFor(ReviewCategory category) => _keys[category]!;

  /// 現在レイアウト済みなら、そのアイコンの画面上の矩形を返す。未レイアウト
  /// (画面遷移直後など)ならnull——呼び出し側はその場合そのカテゴリへの
  /// 演出をスキップする。
  Rect? rectFor(ReviewCategory category) {
    final box = _keys[category]!.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
