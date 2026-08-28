import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

import '../utils/media_type.dart';
import 'db_service.dart';
import 'image_storage_service.dart';

/// 日記に添付した写真・動画をFirebase Storageへバックアップ/復元する。
/// テキストデータの同期（[CloudSyncService]）とは独立して動き、Pro限定機能
/// として呼び出し側（JournalStore）でゲートする——ここではメールアカウント
/// を持っているか（匿名ユーザーでないか）だけをチェックする。
///
/// コスト対策として、写真はアップロード前に圧縮し（元のローカルファイルは
/// 無圧縮のまま）、動画は圧縮せず一定サイズを超えるものはアップロードを
/// スキップする（動画の圧縮は未対応、既知の制限）。
class MediaSyncService {
  static const int _maxVideoUploadBytes = 100 * 1024 * 1024; // 100MB
  static const int _imageMaxDimension = 1600;
  static const int _imageQuality = 80;

  final ImageStorageService _images = ImageStorageService();

  Reference? _mediaFolder(String? remoteId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || remoteId == null) return null;
    return FirebaseStorage.instance.ref(
      'users/${user.uid}/entries/$remoteId/media',
    );
  }

  Future<Uint8List?> _prepareBytesForUpload(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    if (isVideoPath(path)) {
      final length = await file.length();
      if (length > _maxVideoUploadBytes) return null;
      return file.readAsBytes();
    }
    final compressed = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: _imageMaxDimension,
      minHeight: _imageMaxDimension,
      quality: _imageQuality,
    );
    return compressed ?? file.readAsBytes();
  }

  /// [entryId]のまだアップロードしていない添付ファイルをStorageへ送る。
  Future<void> uploadPendingMedia({
    required int entryId,
    required String? remoteId,
  }) async {
    final folder = _mediaFolder(remoteId);
    if (folder == null) return;
    final pending = await DbService.instance.getUnuploadedImagePaths(entryId);
    for (final path in pending) {
      try {
        final bytes = await _prepareBytesForUpload(path);
        if (bytes == null) continue;
        await folder.child(p.basename(path)).putData(bytes);
        await DbService.instance.markImageUploaded(path);
      } catch (e) {
        debugPrint('media upload failed: $e');
      }
    }
  }

  Future<void> deleteMedia(String? remoteId, String path) async {
    final folder = _mediaFolder(remoteId);
    if (folder == null) return;
    try {
      await folder.child(p.basename(path)).delete();
    } catch (e) {
      debugPrint('media delete failed: $e');
    }
  }

  Future<void> deleteAllMedia(String? remoteId) async {
    final folder = _mediaFolder(remoteId);
    if (folder == null) return;
    try {
      final list = await folder.listAll();
      for (final item in list.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('media delete-all failed: $e');
    }
  }

  /// クラウド上にあってこの端末にまだ無い添付ファイルをダウンロードし、
  /// entry_imagesへ追加登録する。[fullSync]で新しく取り込んだエントリに使う。
  Future<void> downloadMissingMedia({
    required int entryId,
    required String? remoteId,
    required List<String> localPaths,
  }) async {
    final folder = _mediaFolder(remoteId);
    if (folder == null) return;
    final localFileNames = localPaths.map(p.basename).toSet();
    List<Reference> remoteItems;
    try {
      remoteItems = (await folder.listAll()).items;
    } catch (e) {
      debugPrint('media list failed: $e');
      return;
    }
    final newPaths = <String>[];
    for (final ref in remoteItems) {
      if (localFileNames.contains(ref.name)) continue;
      try {
        final bytes = await ref.getData(20 * 1024 * 1024);
        if (bytes == null) continue;
        final localPath = await _images.saveBytes(bytes, ref.name);
        newPaths.add(localPath);
      } catch (e) {
        debugPrint('media download failed: $e');
      }
    }
    if (newPaths.isEmpty) return;
    await DbService.instance.addImages(entryId, newPaths);
    for (final path in newPaths) {
      await DbService.instance.markImageUploaded(path);
    }
  }
}
