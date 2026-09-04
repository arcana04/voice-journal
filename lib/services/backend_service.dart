import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../l10n/l10n_utils.dart';
import '../models/custom_word.dart';
import '../models/emotion_tag.dart';
import '../models/idea_brainstorm.dart';
import '../models/journal_entry.dart';
import '../models/media_usage.dart';
import '../models/review_category.dart';
import '../models/summary_level.dart';
import '../models/usage_status.dart';
import '../models/weekly_report.dart';
import 'auth_service.dart';

class BackendServiceException implements Exception {
  final String message;
  final String? code;
  BackendServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class BackendService {
  final AuthService _auth = AuthService();

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
      });
      return _entryFromResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(
        e.message ?? currentLocalizations().genericProcessingError,
        code: e.code,
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

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('processTextMemo');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
        'summaryLevel': summaryLevel.wireValue,
        'locale': locale,
        'allowedCategories': allowedCategories.map((c) => c.wireValue).toList(),
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

  Future<String> askKnowledgeBase(
    String question, {
    required String context,
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('askKnowledgeBase');
      final result = await callable.call<Map<String, dynamic>>({
        'question': question,
        'context': context,
        'locale': locale,
      });
      return (result.data['answer'] as String? ?? '').trim();
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().genericProcessingError);
    }
  }

  Future<List<IdeaAngle>> brainstormIdea({
    required String title,
    required String content,
    required String locale,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('brainstormIdea');
      final result = await callable.call<Map<String, dynamic>>({
        'title': title,
        'content': content,
        'locale': locale,
      });
      final angles = (result.data['angles'] as List? ?? [])
          .map((e) => IdeaAngle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return angles;
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? currentLocalizations().genericProcessingError);
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
}
