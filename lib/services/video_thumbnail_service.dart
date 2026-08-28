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
}
