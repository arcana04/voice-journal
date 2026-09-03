/// 日記エントリに添付された1枚の写真・動画。[x]/[y]/[scale]はPro限定の
/// 「自由配置」機能用で、ユーザーがまだ一度も動かしていない画像はnull
/// （キャンバス上で自動的に並べる）のままになる。一度ドラッグ・リサイズ
/// されると具体的な値が入り、以後はその位置・大きさで固定表示される。
class EntryImage {
  final int? id;
  final int entryId;
  final String path;
  final int sortOrder;
  /// キャンバス内での中心位置。左上が(0,0)、右下が(1,1)の正規化座標。
  final double? x;
  final double? y;
  /// 基準サイズに対する拡大率。nullは「まだ調整されていない（既定サイズ）」。
  final double? scale;

  const EntryImage({
    this.id,
    required this.entryId,
    required this.path,
    this.sortOrder = 0,
    this.x,
    this.y,
    this.scale,
  });

  EntryImage copyWith({double? x, double? y, double? scale}) {
    return EntryImage(
      id: id,
      entryId: entryId,
      path: path,
      sortOrder: sortOrder,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
    );
  }
}
