import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 日記に添付する画像を、端末の永続領域（アプリのドキュメントディレクトリ）に
/// コピーして保存する。image_pickerが返す一時ファイルはOSに消される可能性が
/// あるため、選択直後にコピーして参照パスをDBに保存する。
class ImageStorageService {
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
  }
}
