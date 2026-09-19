import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/media_type.dart';
import 'video_thumbnail_service.dart';

/// 日記に添付する画像を、端末の永続領域（アプリのドキュメントディレクトリ）に
/// コピーして保存する。image_pickerが返す一時ファイルはOSに消される可能性が
/// あるため、選択直後にコピーして参照パスをDBに保存する。
class ImageStorageService {
  final VideoThumbnailService _thumbnails = VideoThumbnailService();

  Future<Directory> _imagesDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'diary_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<String> saveImage(File source) async {
    final imagesDir = await _imagesDir();
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir.path, fileName);
    await source.copy(destPath);
    return destPath;
  }

  /// クラウドからダウンロードしたバイト列を、[fileName]（Storage側のオブジェクト名
  /// = 元のローカルファイル名）のまま端末に保存する。端末間でファイル名を保つことで
  /// 「すでにローカルにあるか」の判定に使える。
  Future<String> saveBytes(Uint8List bytes, String fileName) async {
    final imagesDir = await _imagesDir();
    final destPath = p.join(imagesDir.path, fileName);
    await File(destPath).writeAsBytes(bytes);
    return destPath;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    // 動画の場合、対応するキャッシュ済みサムネイルも一緒に消す。放置すると
    // Documents/video_thumbnails配下に元動画が無くなった孤児サムネイルが
    // 溜まり続ける（[VideoThumbnailService.deleteThumbnailFor]参照）。
    if (isVideoPath(path)) {
      await _thumbnails.deleteThumbnailFor(path);
    }
  }

  /// アカウント切り替え/削除時、端末ローカルの添付画像を全て消す。
  Future<void> deleteAllImages() async {
    final imagesDir = await _imagesDir();
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
    await _deleteAllThumbnails();
  }

  /// 動画サムネイルのキャッシュディレクトリを丸ごと消す。個々の動画パスを
  /// 辿らずに済むよう、[deleteAllImages]と同じ「全消去」経路でのみ使う。
  Future<void> _deleteAllThumbnails() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final thumbsDir = Directory(p.join(docsDir.path, 'video_thumbnails'));
    if (await thumbsDir.exists()) {
      try {
        await thumbsDir.delete(recursive: true);
      } catch (_) {}
    }
  }
}
