import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 録音前の「どの分野について話すか」の絞り込みと、レビュー画面の3カテゴリの
/// どちらにも使う共通の分類。Cloud Functions側（allowedCategories）とは
/// [wireValue]でやり取りする。
enum ReviewCategory { diary, idea, task }

extension ReviewCategoryX on ReviewCategory {
  String get wireValue => switch (this) {
    ReviewCategory.diary => 'diary',
    ReviewCategory.idea => 'idea',
    ReviewCategory.task => 'task',
  };

  IconData get icon => switch (this) {
    ReviewCategory.diary => Icons.menu_book_outlined,
    ReviewCategory.idea => Icons.lightbulb_outline,
    ReviewCategory.task => Icons.checklist_outlined,
  };

  String labelFor(AppLocalizations l10n) => switch (this) {
    ReviewCategory.diary => l10n.sectionDiary,
    ReviewCategory.idea => l10n.sectionIdea,
    ReviewCategory.task => l10n.sectionTask,
  };
}
