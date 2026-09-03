import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pro限定の「アプリ全体の背景を自分の画像にする」機能用。選んだ画像を
/// アプリの永続領域にコピーする。常に1枚しか使わないので、新しい画像を
/// 保存する際は前のファイルを削除して溜め込まないようにする。
class AppBackgroundStorageService {
  Future<Directory> _dir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'app_background'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> saveBackground(File source) async {
    final dir = await _dir();
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
    final ext = p.extension(source.path);
    final destPath = p.join(dir.path, 'background$ext');
    await source.copy(destPath);
    return destPath;
  }

  Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
