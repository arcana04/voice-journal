import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// アクションボタン/ロック画面ウィジェットから開かれる `voicejournal://record` を
/// 検知して、アプリ起動と同時に録音を自動開始できるようにする。
class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  bool _isRecordLink(Uri uri) {
    return uri.scheme == 'voicejournal' && uri.host == 'record';
  }

  Future<void> init({required VoidCallback onRecordRequested}) async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null && _isRecordLink(initial)) {
        onRecordRequested();
      }
    } catch (_) {
      // 初回リンクの取得に失敗しても、通常起動として続行する。
    }

    _subscription = _appLinks.uriLinkStream.listen((uri) {
      if (_isRecordLink(uri)) {
        onRecordRequested();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
