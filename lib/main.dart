import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ReminderService.instance.initialize();
  // RevenueCat側のユーザーIDをFirebase AuthのUIDに揃えるため、起動時にサインインを
  // 済ませておく（各画面での遅延サインインは従来どおりBackendService側でも行われる）。
  final uid = await AuthService().ensureSignedIn();
  runApp(VoiceJournalApp(uid: uid));
}
