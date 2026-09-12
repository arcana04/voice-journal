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

  /// TaskItem.toMap()が返す日時フィールドは、created_atと同じくローカル時刻の
  /// タイムゾーン印なし文字列（TaskItem.dueDate等はAIのJSON応答/ローカル
  /// SQLiteとの往復用にローカル時刻のまま扱う設計のため）。ローカル
  /// SQLiteとの往復では問題ないが、Firestoreに書くとサーバー側の
  /// due_dateベースの締切フィルタ（今週やらなきゃいけないタスク、等）が
  /// created_atと同じ理由で誤解釈する
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  static const _taskDateTimeFields = [
    'due_date',
    'reminder_at',
    'reminder_end_at',
    'notify_at',
  ];

  Map<String, dynamic> _taskToFirestoreMap(Map<String, dynamic> map) {
    for (final field in _taskDateTimeFields) {
      final value = map[field] as String?;
      final parsed = value != null ? DateTime.tryParse(value) : null;
      if (parsed != null) map[field] = parsed.toUtc().toIso8601String();
    }
    return map;
  }

  Map<String, Object?> _taskFromFirestoreMap(Map<String, Object?> map) {
    for (final field in _taskDateTimeFields) {
      final value = map[field] as String?;
      final parsed = value != null ? DateTime.tryParse(value) : null;
      if (parsed != null) map[field] = parsed.toLocal().toIso8601String();
    }
    return map;
  }

  Map<String, dynamic> _entryToFirestoreMap(JournalEntry entry) {
    return {
      'summary': entry.summary,
      // entry.createdAtは端末のローカル時刻（DateTime.now()）で、
      // toIso8601String()はローカル時刻に対してはタイムゾーン情報（Z等）を
      // 一切付けない。UTCで動くCloud Functions側がnew Date(...)でこの文字列を
      // 読むと、ローカルの壁時計の数字をそのままUTCとして誤解釈し、実際の
      // 時刻と最大十数時間ズレる（相談機能の期間判定・時刻表示の土台が歪む
      // 原因になっていた、[[project_voicejournal_knowledge_base_chat]]参照）。
      // Firestoreに書く瞬間だけ明示的にUTCへ変換し、Z付きの曖昧さの無い
      // 文字列にする。
      'created_at': entry.createdAt.toUtc().toIso8601String(),
      'comfort_message': entry.comfortMessage,
      'emotion': entry.emotion?.id,
      'tasks': entry.tasks
          .map(
            (t) => _taskToFirestoreMap(
              _stripLocalKeys(t.toMap())
                ..remove('calendar_event_id')
                ..remove('apple_reminder_id'),
            ),
          )
          .toList(),
      'notes': entry.notes.map((n) => _stripLocalKeys(n.toMap())).toList(),
    };
  }

  JournalEntry _entryFromFirestore(String remoteId, Map<String, dynamic> data) {
    final tasks = (data['tasks'] as List? ?? [])
        .map(
          (m) => TaskItem.fromMap(
            _taskFromFirestoreMap(Map<String, Object?>.from(m as Map)),
          ),
        )
        .toList();
    final notes = (data['notes'] as List? ?? [])
        .map((m) => NoteItem.fromMap(Map<String, Object?>.from(m as Map)))
        .toList();
    return JournalEntry(
      remoteId: remoteId,
      // Firestoreの文字列はUTC（Z付き）で保存されている（_entryToFirestoreMap
      // 参照）。toLocal()でこの端末のローカル時刻に戻し、アプリの他の部分
      // （日記のカレンダー表示・並び替え等）が期待する「ローカル時刻の
      // DateTime」という形を崩さないようにする。
      createdAt:
          DateTime.tryParse(data['created_at'] as String? ?? '')?.toLocal() ??
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
