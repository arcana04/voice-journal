import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../l10n/l10n_utils.dart';
import '../models/custom_word.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../models/knowledge_base_source.dart';
import '../models/media_usage.dart';
import '../models/notion_page.dart';
import '../models/review_category.dart';
import '../models/summary_level.dart';
import '../models/usage_status.dart';
import '../models/weekly_report.dart';
import 'auth_service.dart';

class BackendServiceException implements Exception {
  final String message;
  final String? code;

  /// HttpsErrorの第3引数(details)由来の追加情報。今のところ`reason`フィールド
  /// (例: "monthly_minutes")で、同じcode="resource-exhausted"の中で
  /// 「日次回数の上限」と「月間録音時間の上限」を区別するために使う。
  final Map<String, dynamic>? details;
  BackendServiceException(this.message, {this.code, this.details});

  bool get isMonthlyMinutesExceeded => details?['reason'] == 'monthly_minutes';

  @override
  String toString() => message;
}

/// FirebaseFunctionsException.detailsはdynamic（プラットフォームによって
/// `Map<Object?, Object?>`で返ることがある）なので、安全に`Map<String, dynamic>?`へ
/// 変換する。
Map<String, dynamic>? _detailsAsMap(dynamic details) {
  if (details is Map) {
    return details.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

class BackendService {
  final AuthService _auth = AuthService();

  /// 「今日」「今日の曜日」の判定をサーバー（Cloud Functions、UTC固定）ではなく
  /// 端末の実際のタイムゾーンで行わせるために送る。取得に失敗しても致命的では
  /// ない（サーバー側で日本時間へフォールバックする）ためベストエフォート
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。
  Future<String?> _deviceTimeZone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return null;
    }
  }

  Future<JournalEntry> processVoiceMemo(
    File audioFile, {
    List<CustomWord> customWords = const [],
    SummaryLevel summaryLevel = SummaryLevel.preserve,
    Set<ReviewCategory> allowedCategories = const {...ReviewCategory.values},
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    final bytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(bytes);
    final timeZone = await _deviceTimeZone();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('processVoiceMemo');
      final result = await callable.call<Map<String, dynamic>>({
        'audioBase64': audioBase64,
        'mimeType': 'audio/m4a',
        'customWords': customWords.map((w) => w.toJson()).toList(),
        'summaryLevel': summaryLevel.wireValue,
        'locale': locale,
        'allowedCategories': allowedCategories.map((c) => c.wireValue).toList(),
        'timeZone': timeZone,
      });
      return _entryFromResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
        details: _detailsAsMap(e.details),
      );
    }
  }

  Future<JournalEntry> processTextMemo(
    String text, {
    SummaryLevel summaryLevel = SummaryLevel.preserve,
    Set<ReviewCategory> allowedCategories = const {...ReviewCategory.values},
    required String locale,
  }) async {
    await _auth.ensureSignedIn();
    final timeZone = await _deviceTimeZone();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('processTextMemo');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
        'summaryLevel': summaryLevel.wireValue,
        'locale': locale,
        'allowedCategories': allowedCategories.map((c) => c.wireValue).toList(),
        'timeZone': timeZone,
      });
      return _entryFromResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }

  JournalEntry _entryFromResponse(Map<String, dynamic> data) {
    final tasks = (data['tasks'] as List? ?? [])
        .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((t) => t.title.isNotEmpty)
        .toList();
    final notes = (data['notes'] as List? ?? [])
        .map((e) => NoteItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((n) => n.content.isNotEmpty)
        .toList();

    final comfortMessage = (data['comfort_message'] as String?)?.trim();

    return JournalEntry(
      createdAt: DateTime.now(),
      summary: (data['summary'] as String? ?? '').trim(),
      tasks: tasks,
      notes: notes,
      comfortMessage:
          (comfortMessage == null || comfortMessage.isEmpty) ? null : comfortMessage,
      emotion: EmotionTag.fromId(data['emotion'] as String?),
    );
  }

  Future<KnowledgeBaseAnswer> askKnowledgeBase(
    String question, {
    required String context,
    required String locale,
    List<Map<String, String>> history = const [],
  }) async {
    await _auth.ensureSignedIn();
    final timeZone = await _deviceTimeZone();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('askKnowledgeBase');
      final result = await callable.call<Map<String, dynamic>>({
        'question': question,
        'context': context,
        'locale': locale,
        'history': history,
        'timeZone': timeZone,
      });
      final answer = (result.data['answer'] as String? ?? '').trim();
      final sourcesJson = result.data['sources'] as List<dynamic>? ?? const [];
      final sources = sourcesJson
          .map((s) => KnowledgeBaseSource.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      return KnowledgeBaseAnswer(answer: answer, sources: sources);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().genericProcessingError);
    }
  }

  /// 相談機能を音声で質問するための文字起こし。processVoiceMemoと違い
  /// 仕分け構造化はせず、日次クォータ・月間録音時間も消費しない。
  Future<String> transcribeQuestion(File audioFile, {required String locale}) async {
    await _auth.ensureSignedIn();

    final bytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(bytes);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('transcribeQuestion');
      final result = await callable.call<Map<String, dynamic>>({
        'audioBase64': audioBase64,
        'mimeType': 'audio/m4a',
        'locale': locale,
      });
      return (result.data['text'] as String? ?? '').trim();
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }

  Future<WeeklyReportInsights> generateWeeklyReport({
    required String context,
    required Map<String, int> emotionBreakdown,
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('generateWeeklyReport');
      final result = await callable.call<Map<String, dynamic>>({
        'context': context,
        'emotionBreakdown': emotionBreakdown,
        'locale': locale,
      });
      return WeeklyReportInsights.fromJson(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().genericProcessingError);
    }
  }

  Future<UsageStatus> fetchUsageStatus() async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('getUsageStatus');
      final result = await callable.call<Map<String, dynamic>>();
      final data = result.data;
      return UsageStatus(
        used: (data['used'] as num?)?.toInt() ?? 0,
        limit: (data['limit'] as num?)?.toInt() ?? 0,
        monthlyUsedSeconds: (data['monthlyUsedSeconds'] as num?)?.toInt(),
        monthlyLimitSeconds: (data['monthlyLimitSeconds'] as num?)?.toInt(),
        bonusSecondsBalance: (data['bonusSecondsBalance'] as num?)?.toInt(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().usageFetchError);
    }
  }

  Future<MediaUsage> fetchMediaUsage() async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('getMediaUsage');
      final result = await callable.call<Map<String, dynamic>>();
      final data = result.data;
      return MediaUsage(
        usedBytes: (data['used'] as num?)?.toInt() ?? 0,
        capBytes: (data['cap'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().usageFetchError);
    }
  }

  /// Notion連携: 渡されたIntegrationトークンに共有済みのページ一覧を返す
  /// (データベース作成先を選ばせるための一覧取得のみ。まだ何も保存しない)。
  Future<List<NotionPage>> notionListPages(String token, {required String locale}) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('notionListPages');
      final result = await callable.call<Map<String, dynamic>>({
        'token': token,
        'locale': locale,
      });
      final pagesJson = result.data['pages'] as List<dynamic>? ?? const [];
      return pagesJson
          .map((p) => NotionPage.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }

  /// Notion連携: 選ばれた親ページ配下に固定スキーマのデータベースを作成し、
  /// トークンとあわせてサーバー側に保存する。
  Future<void> notionSetupDatabase(
    String token,
    String pageId, {
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('notionSetupDatabase');
      await callable.call<Map<String, dynamic>>({
        'token': token,
        'pageId': pageId,
        'locale': locale,
      });
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }

  /// Notion連携の解除(Notion側のデータベース自体は残す)。
  Future<void> notionDisconnect({required String locale}) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('notionDisconnect');
      await callable.call<Map<String, dynamic>>({'locale': locale});
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }

  /// Notion連携: タスク/日記/アイデア1件を接続済みのデータベースへ1ページとして送信する。
  /// 成功したら作成されたNotionページのURLを返す。
  Future<String> notionSendItem({
    required String title,
    required String content,
    required String category,
    required DateTime date,
    DateTime? dueDate,
    bool? done,
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('notionSendItem');
      final payload = <String, dynamic>{
        'title': title,
        'content': content,
        'category': category,
        'dateIso': date.toIso8601String(),
        'locale': locale,
      };
      if (dueDate != null) payload['dueDateIso'] = dueDate.toIso8601String();
      if (done != null) payload['done'] = done;
      final result = await callable.call<Map<String, dynamic>>(payload);
      return result.data['pageUrl'] as String? ?? '';
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
      );
    }
  }
}
