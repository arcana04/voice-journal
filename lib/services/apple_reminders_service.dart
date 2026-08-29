import 'dart:io';

import 'package:flutter/services.dart';

/// iPhone標準の「リマインダー」アプリ（EventKitのEKReminder）と連携するための
/// プラットフォームチャンネルのラッパー。[CalendarService]がEKEvent（予定）を
/// 扱うのに対し、こちらはEKReminder（ToDo）を扱う——iOSにしか存在しない別の
/// OS標準アプリのため、iOS専用（Androidでは常に非対応として振る舞う）。
class AppleRemindersService {
  static final AppleRemindersService instance =
      AppleRemindersService._internal();
  AppleRemindersService._internal();

  static const MethodChannel _channel = MethodChannel(
    'voicejournal/apple_reminders',
  );

  bool get isSupported => Platform.isIOS;

  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    final result = await _channel.invokeMethod<bool>('hasPermission');
    return result ?? false;
  }

  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  /// 書き込み可能なリマインダーリストの一覧を返す。
  Future<List<({String id, String title})>> fetchLists() async {
    if (!isSupported) return const [];
    final result = await _channel.invokeMethod<List<Object?>>('fetchLists');
    if (result == null) return const [];
    return result
        .map((e) => Map<String, Object?>.from(e as Map))
        .map((m) => (id: m['id'] as String, title: m['title'] as String))
        .toList();
  }

  /// [listId]にリマインダーを作成・更新する。既存の[reminderId]を渡すとそれを
  /// 更新する。[dueDate]がnullなら期限なしのリマインダーとして登録し、既存の
  /// 期限は消える。[includesTime]がfalseなら日付のみ（終日）の期限にする。
  /// 成功すればリマインダーIDを返す。
  Future<String?> upsertReminder({
    required String listId,
    String? reminderId,
    required String title,
    DateTime? dueDate,
    bool includesTime = true,
    bool completed = false,
  }) async {
    if (!isSupported) return null;
    final result = await _channel.invokeMethod<String>('upsertReminder', {
      'listId': listId,
      'reminderId': reminderId,
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'includesTime': includesTime,
      'completed': completed,
    });
    return result;
  }

  Future<void> deleteReminder(String reminderId) async {
    if (!isSupported) return;
    await _channel.invokeMethod('deleteReminder', {'reminderId': reminderId});
  }
}
