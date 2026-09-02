/// 写真・動画クラウド同期の利用容量（Firebase Storage合計バイト数、サブスク
/// プラン限定）。[getMediaUsage] Cloud Functionから取得する。
class MediaUsage {
  final int usedBytes;
  final int capBytes;

  const MediaUsage({required this.usedBytes, required this.capBytes});

  double get ratio => capBytes <= 0 ? 0 : usedBytes / capBytes;

  /// この比率を超えたら「そろそろ上限です」の警告バナーを出す。
  static const double warnRatio = 0.7;

  bool get isWarning => ratio >= warnRatio;
  bool get isOverCap => usedBytes >= capBytes;
}
