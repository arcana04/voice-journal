import 'package:flutter/material.dart';

import '../models/emotion_tag.dart';

/// 感情タグを表す単色フラットの正円。ツヤ・グラデーション・虹色の縁取りを
/// 持つ以前の泡PNGとは違い、このアプリのミニマルなUIに合わせて色分けのみ
/// で表現する。以前はカテゴリごとに形(ハート/正円/しずく)も変えていたが、
/// 小さいバッジでは形の違いに気を取られて色の違いが伝わりにくかったため、
/// 形は正円1種類に統一し、[EmotionTag.color]の違いだけで判別させる。
class EmotionBubble extends StatelessWidget {
  final EmotionTag tag;
  final double size;

  const EmotionBubble({super.key, required this.tag, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tag.color),
    );
  }
}

/// 感情タグを、色だけで判別させる[EmotionBubble]ではなくラベル付きの
/// ピル(丸薬形チップ)で示す版。アイデア画面の検討状況チップ(`_StatusChip`)
/// と同じ「薄い色の背景+同色の細い縁取り+同色のテキスト」の見た目に揃えて
/// あり、単色の丸だけをカードの角に浮かせて置くよりもアプリの他の場所と
/// 馴染む。ラベルが別の場所に既に出ている(選択シートの下のテキストなど)
/// 文脈では使わず、単体で感情を示す必要がある場所(日記一覧カードなど)で使う。
class EmotionPill extends StatelessWidget {
  final EmotionTag tag;
  final String label;

  const EmotionPill({super.key, required this.tag, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tag.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
