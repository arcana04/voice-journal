import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pro限定の「自分の画像を背景にする」機能用。選んだ画像をアプリの永続領域に
/// コピーし、[NoteItem.backgroundId]にそのまま保存できる `custom:<絶対パス>`
/// 形式のIDを返す（[DiaryBackground]の列挙値IDとは別の名前空間として共存する）。
class CustomBackgroundService {
  static const _prefix = 'custom:';

  Future<String> saveCustomBackground(File source) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'diary_custom_backgrounds'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(dir.path, fileName);
    await source.copy(destPath);
    return '$_prefix$destPath';
  }

  static bool isCustomBackgroundId(String? id) =>
      id != null && id.startsWith(_prefix);

  static String pathFromId(String id) => id.substring(_prefix.length);
}
