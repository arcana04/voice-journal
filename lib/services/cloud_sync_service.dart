import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';

/// エントリ（日記・タスク・アイデア）をFirestore `users/{uid}/entries/{remoteId}`
/// へバックアップ/復元する。写真・動画は対象外（テキストデータのみ）。
///
/// メールアカウントを作成していない（匿名認証のままの）ユーザーには一切
/// 通信しない — 課金と同様、未加入者にコストをかけない設計。
/// リアルタイム同期ではなく、呼び出されたタイミングでの単純なpush/pull。
class CloudSyncService {
  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('entries');
  }

  Map<String, dynamic> _stripLocalKeys(Map<String, Object?> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.remove('id');
    copy.remove('entry_id');
    return copy;
  }

  Map<String, dynamic> _entryToFirestoreMap(JournalEntry entry) {
    return {
      'summary': entry.summary,
      'created_at': entry.createdAt.toIso8601String(),
      'comfort_message': entry.comfortMessage,
      'emotion': entry.emotion?.id,
      'tasks': entry.tasks
          .map(
            (t) => _stripLocalKeys(t.toMap())
              ..remove('calendar_event_id')
              ..remove('apple_reminder_id'),
          )
          .toList(),
      'notes': entry.notes.map((n) => _stripLocalKeys(n.toMap())).toList(),
    };
  }

  JournalEntry _entryFromFirestore(String remoteId, Map<String, dynamic> data) {
    final tasks = (data['tasks'] as List? ?? [])
        .map((m) => TaskItem.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();
    final notes = (data['notes'] as List? ?? [])
        .map((m) => NoteItem.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();
    return JournalEntry(
      remoteId: remoteId,
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '') ??
              DateTime.now(),
      summary: data['summary'] as String? ?? '',
      tasks: tasks,
      notes: notes,
      comfortMessage: data['comfort_message'] as String?,
      emotion: EmotionTag.fromId(data['emotion'] as String?),
    );
  }

  /// 戻り値はUIへの同期状態表示（[JournalStore.syncError]）に使う成否フラグ。
  /// 匿名ユーザーなど「そもそも同期対象外」の場合は失敗ではないので`true`を返す。
  Future<bool> pushEntry(JournalEntry entry) async {
    final collection = _collection;
    final remoteId = entry.remoteId;
    if (collection == null || remoteId == null) return true;
    try {
      // merge:true でないと、この端末が知らないフィールド（サーバー側で計算される
      // 相談機能の埋め込みベクトルなど）を毎回の同期で消してしまう。
      await collection
          .doc(remoteId)
          .set(_entryToFirestoreMap(entry), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('cloud sync push failed: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String? remoteId) async {
    final collection = _collection;
    if (collection == null || remoteId == null) return true;
    try {
      await collection.doc(remoteId).delete();
      return true;
    } catch (e) {
      debugPrint('cloud sync delete failed: $e');
      return false;
    }
  }

  /// nullは取得失敗（UIへの同期状態表示に使う）、空リストは「同期対象0件」を表す。
  Future<List<JournalEntry>?> fetchAll() async {
    final collection = _collection;
    if (collection == null) return [];
    try {
      final snapshot = await collection.get();
      return snapshot.docs
          .map((doc) => _entryFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('cloud sync fetch failed: $e');
      return null;
    }
  }
}
