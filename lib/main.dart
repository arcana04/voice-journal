import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  // 日記アプリとして縦持ち専用の設計になっており、横向きレイアウトは未対応
  // なので、端末の自動回転に関わらず縦向きに固定する。
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ReminderService.instance.initialize();
  // RevenueCat側のユーザーIDをFirebase AuthのUIDに揃えるため、起動時にサインインを
  // 済ませておく（各画面での遅延サインインは従来どおりBackendService側でも行われる）。
  final uid = await AuthService().ensureSignedIn();
  runApp(VoiceJournalApp(uid: uid));
}
