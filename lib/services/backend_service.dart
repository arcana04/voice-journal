import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/custom_word.dart';
import '../models/journal_entry.dart';
import '../models/summary_level.dart';
import '../models/usage_status.dart';
import 'auth_service.dart';

class BackendServiceException implements Exception {
  final String message;
  BackendServiceException(this.message);

  @override
  String toString() => message;
}

class BackendService {
  final AuthService _auth = AuthService();

  Future<JournalEntry> processVoiceMemo(
    File audioFile, {
    List<CustomWord> customWords = const [],
    SummaryLevel summaryLevel = SummaryLevel.preserve,
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
      });
      return _entryFromResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? '処理中にエラーが発生しました');
    }
  }

  Future<JournalEntry> processTextMemo(
    String text, {
    SummaryLevel summaryLevel = SummaryLevel.preserve,
  }) async {
    await _auth.ensureSignedIn();

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('processTextMemo');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
        'summaryLevel': summaryLevel.wireValue,
      });
      return _entryFromResponse(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? '処理中にエラーが発生しました');
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
    );
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
      throw BackendServiceException(e.message ?? '利用状況の取得に失敗しました');
    }
  }
}
