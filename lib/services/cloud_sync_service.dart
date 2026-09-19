import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/sync_failure_reason.dart';
import 'settings_service.dart';

/// エントリ（日記・タスク・アイデア）をFirestore `users/{uid}/entries/{remoteId}`
/// へバックアップ/復元する。写真・動画は対象外（テキストデータのみ）。
///
/// メールアカウントを作成していない（匿名認証のままの）ユーザーには一切
/// 通信しない — 課金と同様、未加入者にコストをかけない設計。
/// リアルタイム同期ではなく、呼び出されたタイミングでの単純なpush/pull。
class CloudSyncService {
  /// 直近の失敗の分類（[JournalStore.syncErrorReason]に使う）。各メソッドは
  /// 呼ばれるたびに自分の結果でこれを上書きするので、staleな値が別の
  /// 失敗に紛れ込むことはない。
  SyncFailureReason? lastFailureReason;

  /// [operation]を実行し、失敗が[SyncFailureReason.network]（一時的な通信の
  /// 途切れ）に分類される場合だけ、短い待機を挟んで1回だけ再試行する。
  /// 権限エラーや未認証はリトライしても直らないため対象外。ユーザーが
  /// 削除操作をしただけで、単発のWi-Fi切れのようなごく一時的な事象で毎回
  /// 「同期に失敗しました」バナーが出てしまうのを減らす狙い。
  Future<bool> _withNetworkRetry(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (e) {
      final reason = SyncFailureReason.classify(e);
      if (reason != SyncFailureReason.network) {
        lastFailureReason = reason;
        return false;
      }
      await Future.delayed(const Duration(seconds: 2));
      try {
        await operation();
        return true;
      } catch (e2) {
        lastFailureReason = SyncFailureReason.classify(e2);
        return false;
      }
    }
  }

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

  /// Firestoreの1ドキュメント上限（1MiB）に対する安全マージン。実際の音声
  /// メモは（15分話しても）この何分の1にも収まらないはずなので、正常な
  /// エントリを削ることはない想定 — 万一異常に長い本文があっても、それ
  /// だけを理由に同期全体が`invalid-argument`/`resource-exhausted`で
  /// 恒久的に失敗し続けるのを防ぐための保険。
  static const _noteContentCharCap = 100000;

  /// 1エントリ内の全note合計に対する安全マージン（文字数）。
  /// [_noteContentCharCap]はnote単体の暴走を止めるが、firestore.rulesは
  /// 1エントリあたり最大200 noteを許可しているため、note単体は上限内でも
  /// 合計では依然としてFirestoreの1ドキュメント1MiB上限を超えて同期が
  /// 恒久的に失敗しうる。マルチバイト文字（日本語等）は1文字あたり最大
  /// 3バイトになり得るため、バイト数ではなく十分保守的な文字数で見積もる。
  static const _totalNoteContentCharCap = 300000;

  Map<String, dynamic> _capNoteForFirestore(Map<String, dynamic> map) {
    final content = map['content'] as String?;
    if (content != null && content.length > _noteContentCharCap) {
      map['content'] = content.substring(0, _noteContentCharCap);
    }
    return map;
  }

  /// 各noteに[_capNoteForFirestore]を適用した後、note合計の文字数が
  /// [_totalNoteContentCharCap]を超えないよう、超過分から後ろのnoteの
  /// contentを先頭側から優先して切り詰める（一部のnoteを丸ごと消すより、
  /// できるだけ多くのnoteの内容を部分的にでも残す方針）。
  List<Map<String, dynamic>> _capNotesTotalForFirestore(
    List<Map<String, dynamic>> notes,
  ) {
    var remainingBudget = _totalNoteContentCharCap;
    for (final note in notes) {
      final content = note['content'] as String?;
      if (content == null) continue;
      if (remainingBudget <= 0) {
        note['content'] = '';
      } else if (content.length > remainingBudget) {
        note['content'] = content.substring(0, remainingBudget);
        remainingBudget = 0;
      } else {
        remainingBudget -= content.length;
      }
    }
    return notes;
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

  // 返り値のトップレベルキーは firestore.rules の
  // `users/{uid}/entries/{entryId}` にある `hasOnly([...])` の許可リストと
  // 一致していなければならない。ここに新しいフィールドを足すときは必ず
  // 両方同時に更新すること — ずれると全ユーザーの書き込みが恒久的に
  // permission-deniedで失敗し、UIは「サインインし直してください」という
  // 見当違いの案内を出してしまう（再サインインでは直らない）。
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
      // fullSyncが同じremoteIdのエントリを端末とリモートの両方で見つけた際に
      // どちらが新しいか判定する基準([JournalStore.fullSync]参照)。UTCへ
      // 変換する理由はcreated_atと同じ(Firestore/他端末との間で曖昧さの無い
      // 文字列にするため)。
      'updated_at': entry.updatedAt.toUtc().toIso8601String(),
      'comfort_message': entry.comfortMessage,
      'emotion': entry.emotion?.id,
      'tasks': entry.tasks
          .map(
            (t) => _taskToFirestoreMap(
              _stripLocalKeys(t.toMap())
                ..remove('calendar_event_id')
                ..remove('apple_reminder_id')
                // 端末のカレンダーID（OS/コンテンツプロバイダのローカルな
                // 整数/文字列ID）。他の端末・他のアカウントでは同じIDが
                // 全く別のカレンダーを指し得るため、同期して良い情報ではない
                // ——含めたまま同期すると、別端末側のjournal_store.dartが
                // このIDを信じて誤った（無関係な）カレンダーに予定を作成・
                // 更新・削除してしまう。
                ..remove('calendar_id')
                // apple_reminder_list_idもcalendar_idと全く同じ理由で除外する
                // 必要がある(端末のEventKitリマインダーリストのローカルID)。
                // これが漏れていたため、別端末で同じエントリを取り込むと、
                // その端末には存在しない/無関係なリストIDを持つタスクが
                // 出来上がり、以後そのタスクを更新・完了するたびに無関係な
                // リマインダーリストを誤って操作してしまっていた
                // (calendar_idについてv25で修正済みの不具合と同型)。
                ..remove('apple_reminder_list_id'),
            ),
          )
          .toList(),
      'notes': _capNotesTotalForFirestore(
        entry.notes
            .map((n) => _capNoteForFirestore(_stripLocalKeys(n.toMap())))
            .toList(),
      ),
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
    final createdAt =
        DateTime.tryParse(data['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now();
    // 'updated_at'は今回のfullSync同期修正で追加したフィールドのため、それ
    // 以前に書き込まれた古いドキュメントには存在しない。無い場合はcreated_at
    // を代わりに使う — fullSyncの新旧比較にとっては「実際の最終編集時刻より
    // 古い可能性がある値」でしかないが、少なくとも「常にローカルが勝つ」
    // 従来の挙動よりは正確な比較ができる。マイグレーション未完了のドキュメント
    // が残っていることを追跡できるよう、ここでログに残しておく。
    final updatedAtRaw = data['updated_at'] as String?;
    if (updatedAtRaw == null) {
      debugPrint(
        'cloud sync: entry $remoteId has no updated_at (pre-migration doc); '
        'falling back to created_at for sync comparison',
      );
    }
    final updatedAt =
        (updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null)
                ?.toLocal() ??
            createdAt;
    return JournalEntry(
      remoteId: remoteId,
      // Firestoreの文字列はUTC（Z付き）で保存されている（_entryToFirestoreMap
      // 参照）。toLocal()でこの端末のローカル時刻に戻し、アプリの他の部分
      // （日記のカレンダー表示・並び替え等）が期待する「ローカル時刻の
      // DateTime」という形を崩さないようにする。
      createdAt: createdAt,
      updatedAt: updatedAt,
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
    // アカウント切り替え中の極短い窓（currentUserは切り替わっているが、
    // ローカルデータの持ち主記録はまだ前のアカウントのまま）に、前アカウントの
    // データが新アカウントのFirestoreへ紛れ込むのを防ぐ最終防衛ライン。
    if (!await SettingsService().currentUserOwnsLocalData()) return true;
    final success = await _withNetworkRetry(
      // merge:true でないと、この端末が知らないフィールド（サーバー側で計算される
      // 相談機能の埋め込みベクトルなど）を毎回の同期で消してしまう。
      () => collection.doc(remoteId).set(_entryToFirestoreMap(entry), SetOptions(merge: true)),
    );
    if (!success) debugPrint('cloud sync push failed: $lastFailureReason');
    return success;
  }

  Future<bool> deleteEntry(String? remoteId) async {
    final collection = _collection;
    if (collection == null || remoteId == null) return true;
    // pushEntryと同じ、アカウント切り替え中の極短い窓に対するガード。この
    // remoteIdは前アカウントのローカルエントリのものなので、削除も新アカウント
    // 側の同名ドキュメントを誤って消してしまわないよう同様にブロックする。
    if (!await SettingsService().currentUserOwnsLocalData()) return true;
    final success = await _withNetworkRetry(() => collection.doc(remoteId).delete());
    if (!success) debugPrint('cloud sync delete failed: $lastFailureReason');
    return success;
  }

  /// nullは取得失敗（UIへの同期状態表示に使う）、空リストは「同期対象0件」を表す。
  Future<List<JournalEntry>?> fetchAll() async {
    final collection = _collection;
    if (collection == null) return [];
    try {
      final snapshot = await collection.get();
      final entries = <JournalEntry>[];
      for (final doc in snapshot.docs) {
        try {
          entries.add(_entryFromFirestore(doc.id, doc.data()));
        } catch (e) {
          // 1件のドキュメントの型不整合（壊れた/古い形式のデータ）で同期
          // 全体を失敗させない。そのドキュメントだけ復元をスキップし、
          // 他の正常なエントリは通常通り取得する。
          debugPrint('cloud sync: skipping malformed entry ${doc.id}: $e');
        }
      }
      return entries;
    } catch (e) {
      lastFailureReason = SyncFailureReason.classify(e);
      debugPrint('cloud sync fetch failed: $e');
      return null;
    }
  }
}
