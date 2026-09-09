import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/throwback_item.dart';
import '../screens/throwback_story_screen.dart';
import 'diary_screen_background.dart';

/// 日記タブ上部に置く、Instagram Storiesのような円形の「思い出」入り口。
/// [items]が空（対象の過去日にまだ日記が無い）なら何も表示しない。
class ThrowbackStoryButton extends StatelessWidget {
  final List<ThrowbackItem> items;

  const ThrowbackStoryButton({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => ThrowbackStoryScreen(items: items),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFEDA75),
                    Color(0xFFE1306C),
                    Color(0xFF962FBF),
                    Color(0xFF4F5BD5),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                ),
                child: ClipOval(child: _ThrowbackThumbnail(item: items.first)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.throwbackRowLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThrowbackThumbnail extends StatelessWidget {
  final ThrowbackItem item;

  const _ThrowbackThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final feelingNotes = item.entry.notes
        .where((n) => n.category == kNoteCategoryFeeling)
        .toList();
    final backgroundId = feelingNotes.isNotEmpty
        ? feelingNotes.first.backgroundId
        : null;
    return DiaryScreenBackground(backgroundId: backgroundId);
  }
}
