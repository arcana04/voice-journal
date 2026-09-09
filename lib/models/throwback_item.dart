import 'journal_entry.dart';

/// 日記タブの「思い出」機能（Instagram Storiesのようなふり返りビューア）で
/// 使う、1件の過去エントリと「何ヶ月前の今日か」のペア。
class ThrowbackItem {
  final JournalEntry entry;
  final int monthsAgo;

  const ThrowbackItem({required this.entry, required this.monthsAgo});
}
