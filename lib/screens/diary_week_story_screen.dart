import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/text_style_store.dart';
import '../utils/note_text_style.dart';
import '../widgets/diary_media_canvas.dart';
import '../widgets/diary_screen_background.dart';
import '../widgets/emotion_bubble.dart';
import '../widgets/scrim_text.dart';

/// 日記タブから開く、Instagram Storiesのように横スワイプで週分の日記を
/// 振り返れるフルスクリーンビューア。[ThrowbackStoryScreen]と違い、要約せず
/// 各日記をそのまま（背景・フォント設定込みで）[DiaryViewScreen]相当の見た目で
/// 表示する——自動送りタイマーは付けず、スワイプ操作に委ねる。
class DiaryWeekStoryScreen extends StatefulWidget {
  final List<JournalEntry> entries;

  const DiaryWeekStoryScreen({super.key, required this.entries});

  @override
  State<DiaryWeekStoryScreen> createState() => _DiaryWeekStoryScreenState();
}

class _DiaryWeekStoryScreenState extends State<DiaryWeekStoryScreen> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.entries.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) =>
                  _DiaryStoryPage(entry: widget.entries[index]),
            ),
            Positioned(
              left: 12,
              right: 52,
              top: 8,
              child: Row(
                children: [
                  for (var i = 0; i < widget.entries.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: i <= _index ? 1.0 : 0.0,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryStoryPage extends StatelessWidget {
  final JournalEntry entry;

  const _DiaryStoryPage({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleDefaults = context.watch<TextStyleStore>();
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat('d', locale).format(entry.createdAt);
    final monthYearLabel = DateFormat.yMMMM(locale).format(entry.createdAt);
    final feelingNotes = entry.notes
        .where((n) => n.category == kNoteCategoryFeeling)
        .toList();
    final backgroundId =
        (feelingNotes.isNotEmpty ? feelingNotes.first.backgroundId : null) ??
        textStyleDefaults.backgroundId;

    return Stack(
      fit: StackFit.expand,
      children: [
        DiaryScreenBackground(backgroundId: backgroundId),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScrimText(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            day,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              monthYearLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          if (entry.emotion != null) ...[
                            const SizedBox(width: 12),
                            EmotionPill(
                              tag: entry.emotion!,
                              label: entry.emotion!.labelFor(
                                AppLocalizations.of(context)!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final note in feelingNotes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((note.title ?? '').isNotEmpty)
                          ScrimText(
                            child: Text(
                              note.title!,
                              style: applyNoteStyle(
                                theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                note: note,
                                defaults: textStyleDefaults,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ScrimText(
                          child: Text(
                            note.content,
                            style: applyNoteStyle(
                              theme.textTheme.bodyLarge,
                              note: note,
                              defaults: textStyleDefaults,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DiaryMediaCanvas(entry: entry, editable: false),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
