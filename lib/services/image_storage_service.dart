import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 日記に添付する画像を、端末の永続領域（アプリのドキュメントディレクトリ）に
/// コピーして保存する。image_pickerが返す一時ファイルはOSに消される可能性が
/// あるため、選択直後にコピーして参照パスをDBに保存する。
class ImageStorageService {
  Future<String> saveImage(File source) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'diary_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir.path, fileName);
    await source.copy(destPath);
    return destPath;
  }

  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
