import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pro限定の「自分の画像を背景にする」機能用。選んだ画像をアプリの永続領域に
/// コピーし、[NoteItem.backgroundId]にそのまま保存できる `custom:<絶対パス>`
/// 形式のIDを返す（[DiaryBackground]の列挙値IDとは別の名前空間として共存する）。
class CustomBackgroundService {
  static const _prefix = 'custom:';

  /// これを超えるファイルは背景として保存しない（端末ストレージの無制限な
  /// 肥大化を防ぐための簡易な上限）。
  static const maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  Future<String> saveCustomBackground(File source) async {
    final length = await source.length();
    if (length > maxFileSizeBytes) {
      throw CustomBackgroundTooLargeException(length);
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'diary_custom_backgrounds'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(dir.path, fileName);
    try {
      await source.copy(destPath);
    } catch (e) {
      throw CustomBackgroundSaveFailedException(e);
    }
    return '$_prefix$destPath';
  }

  static bool isCustomBackgroundId(String? id) =>
      id != null && id.startsWith(_prefix);

  static String pathFromId(String id) => id.substring(_prefix.length);
}

/// 選んだ画像が[CustomBackgroundService.maxFileSizeBytes]を超えていた場合に
/// 投げられる例外。呼び出し側でユーザー向けのエラー表示に使う。
class CustomBackgroundTooLargeException implements Exception {
  final int fileSizeBytes;
  const CustomBackgroundTooLargeException(this.fileSizeBytes);

  @override
  String toString() =>
      'CustomBackgroundTooLargeException: $fileSizeBytes bytes exceeds '
      '${CustomBackgroundService.maxFileSizeBytes} byte limit';
}

/// アプリの永続領域への画像コピーに失敗した場合（ディスク容量不足・権限
/// エラーなど）に投げられる例外。呼び出し側でユーザー向けのエラー表示に使う。
class CustomBackgroundSaveFailedException implements Exception {
  final Object cause;
  const CustomBackgroundSaveFailedException(this.cause);

  @override
  String toString() => 'CustomBackgroundSaveFailedException: $cause';
}
