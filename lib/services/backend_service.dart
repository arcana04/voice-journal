import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/journal_entry.dart';
import 'auth_service.dart';

class BackendServiceException implements Exception {
  final String message;
  BackendServiceException(this.message);

  @override
  String toString() => message;
}

class BackendService {
  final AuthService _auth = AuthService();

  Future<JournalEntry> processVoiceMemo(File audioFile) async {
    await _auth.ensureSignedIn();

    final bytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(bytes);

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('processVoiceMemo');
      final result = await callable.call<Map<String, dynamic>>({
        'audioBase64': audioBase64,
        'mimeType': 'audio/m4a',
      });

      final data = result.data;
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
        comfortMessage: (comfortMessage == null || comfortMessage.isEmpty)
            ? null
            : comfortMessage,
      );
    } on FirebaseFunctionsException catch (e) {
      throw BackendServiceException(e.message ?? '処理中にエラーが発生しました');
    }
  }
}
