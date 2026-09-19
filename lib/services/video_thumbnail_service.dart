import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// 添付動画のサムネイル画像を生成・キャッシュする。
/// video_thumbnailは動画パスのハッシュ値をファイル名にして同じ出力先ディレクトリに
/// 保存するため、同じ動画への2回目以降の呼び出しは自然と同じファイルを指す。
/// さらにアプリ実行中はメモリ上にも結果をキャッシュし、同じセッション内での
/// 再生成（＝毎回の動画デコード）を避ける。
class VideoThumbnailService {
  static final Map<String, String> _memoryCache = {};

  Future<String?> getOrCreateThumbnail(String videoPath) async {
    final cached = _memoryCache[videoPath];
    if (cached != null && await File(cached).exists()) return cached;

    final docsDir = await getApplicationDocumentsDirectory();
    final thumbsDir = Directory(p.join(docsDir.path, 'video_thumbnails'));
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }

    try {
      final generated = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbsDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 240,
        quality: 70,
      );
      if (generated != null) _memoryCache[videoPath] = generated;
      return generated;
    } catch (_) {
      return null;
    }
  }

  /// [videoPath]に対応するキャッシュ済みサムネイルを削除する。添付動画自体が
  /// 削除される際に呼ぶ（[ImageStorageService.deleteImage]参照）。
  /// video_thumbnailパッケージは出力ファイル名を内部で決めるため、このセッション
  /// 中に一度でも[getOrCreateThumbnail]を呼んでいてメモリキャッシュにパスが
  /// 残っている場合のみ削除できる——アプリ再起動後、一度も表示していない
  /// サムネイルは対象外（アカウント切り替え等の全削除は
  /// [ImageStorageService.deleteAllImages]がディレクトリごと消すのでカバーされる）。
  Future<void> deleteThumbnailFor(String videoPath) async {
    final cached = _memoryCache.remove(videoPath);
    if (cached == null) return;
    try {
      final file = File(cached);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
