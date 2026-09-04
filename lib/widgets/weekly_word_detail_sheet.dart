import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import 'emotion_bubble.dart';

enum _MatchCategory { diary, idea, task }

class _WordMatch {
  final DateTime time;
  final _MatchCategory category;
  final String text;
  final EmotionTag? emotion;
  final bool taskDone;

  const _WordMatch({
    required this.time,
    required this.category,
    required this.text,
    this.emotion,
    this.taskDone = false,
  });
}

List<_WordMatch> _findMatches({
  required List<JournalEntry> entries,
  required DateTime weekStart,
  required DateTime weekEnd,
  required String keyword,
}) {
  final matches = <_WordMatch>[];
  for (final entry in entries) {
    if (entry.createdAt.isBefore(weekStart) || entry.createdAt.isAfter(weekEnd)) {
      continue;
    }
    for (final note in entry.notes) {
      final isDiary = note.category == kNoteCategoryFeeling;
      final isIdea = note.category == kNoteCategoryIdea;
      if (!isDiary && !isIdea) continue;
      final haystack = '${note.title ?? ''}\n${note.content}';
      if (!haystack.contains(keyword)) continue;
      matches.add(_WordMatch(
        time: entry.createdAt,
        category: isDiary ? _MatchCategory.diary : _MatchCategory.idea,
        text: (note.title != null && note.title!.trim().isNotEmpty)
            ? note.title!.trim()
            : note.content,
        emotion: isDiary ? entry.emotion : null,
      ));
    }
    for (final task in entry.tasks) {
      if (!task.title.contains(keyword)) continue;
      matches.add(_WordMatch(
        time: entry.createdAt,
        category: _MatchCategory.task,
        text: task.title,
        taskDone: task.done,
      ));
    }
  }
  matches.sort((a, b) => b.time.compareTo(a.time));
  return matches;
}

/// 「今週のよく話した言葉」の1枚をタップした時に、その単語を含む今週の
/// 日記・アイデア・タスクを下から一覧表示する。
void showWeeklyWordDetailSheet(
  BuildContext context, {
  required String keyword,
  required DateTime weekStart,
  required DateTime weekEnd,
}) {
  final entries = context.read<JournalStore>().entries;
  final matches = _findMatches(
    entries: entries,
    weekStart: weekStart,
    weekEnd: weekEnd,
    keyword: keyword,
  );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WordDetailSheet(keyword: keyword, matches: matches),
  );
}

class _WordDetailSheet extends StatelessWidget {
  final String keyword;
  final List<_WordMatch> matches;

  const _WordDetailSheet({required this.keyword, required this.matches});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.32,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        keyword,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          l10n.weeklyReportWordDetailEmpty,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _MatchRow(match: matches[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  final _WordMatch match;

  const _MatchRow({required this.match});

  IconData get _icon => switch (match.category) {
        _MatchCategory.diary => Icons.menu_book_outlined,
        _MatchCategory.idea => Icons.lightbulb_outline,
        _MatchCategory.task => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeLabel =
        '${DateFormat.MMMd(locale).format(match.time)} ${DateFormat.Hm(locale).format(match.time)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                timeLabel,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              if (match.category == _MatchCategory.task && match.taskDone) ...[
                const SizedBox(width: 8),
                Icon(Icons.check, size: 14, color: theme.colorScheme.primary),
              ],
              if (match.emotion != null) ...[
                const Spacer(),
                EmotionPill(tag: match.emotion!, label: match.emotion!.labelFor(l10n)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            match.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: match.category == _MatchCategory.task && match.taskDone
                  ? TextDecoration.lineThrough
                  : null,
              color: match.category == _MatchCategory.task && match.taskDone
                  ? theme.colorScheme.outline
                  : null,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
