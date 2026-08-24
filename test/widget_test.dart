import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:voicejournal/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App shows the home screen with a record button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoiceJournalApp());
    await tester.pump();

    expect(find.text('VoiceJournal'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });
}
