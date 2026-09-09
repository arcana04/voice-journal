import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/throwback_item.dart';
import '../state/text_style_store.dart';
import '../utils/note_text_style.dart';
import '../widgets/diary_screen_background.dart';
import '../widgets/emotion_bubble.dart';
import '../widgets/scrim_text.dart';
import 'diary_view_screen.dart';

String throwbackLabelFor(AppLocalizations l10n, int monthsAgo) {
  switch (monthsAgo) {
    case 1:
      return l10n.throwbackOneMonthAgo;
    case 3:
      return l10n.throwbackThreeMonthsAgo;
    case 6:
      return l10n.throwbackSixMonthsAgo;
    case 12:
      return l10n.throwbackOneYearAgo;
    default:
      return l10n.throwbackTwoYearsAgo;
  }
}

/// 日記タブの「思い出」ボタンから開く、Instagram Storiesのようなふり返り
/// ビューア。[ThrowbackItem]を1件ずつフルスクリーンで見せ、一定時間で自動的に
/// 次へ進む。画面の左右タップで手動送り、閉じるボタンで即終了できる。
class ThrowbackStoryScreen extends StatefulWidget {
  final List<ThrowbackItem> items;

  const ThrowbackStoryScreen({super.key, required this.items});

  @override
  State<ThrowbackStoryScreen> createState() => _ThrowbackStoryScreenState();
}

class _ThrowbackStoryScreenState extends State<ThrowbackStoryScreen>
    with SingleTickerProviderStateMixin {
  static const _pageDuration = Duration(seconds: 6);

  late final PageController _controller = PageController();
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _pageDuration,
  )..addStatusListener(_onProgressStatus);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goTo(_index + 1);
  }

  void _goTo(int index) {
    if (index < 0) return;
    if (index >= widget.items.length) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _progress
      ..reset()
      ..forward();
  }

  /// 「全文を見る」タップ時、裏で自動送りが進み続けないよう一旦止め、
  /// 画面から戻ってきたら再開する。
  Future<void> _openFullEntry(int entryId) async {
    _progress.stop();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DiaryViewScreen(entryId: entryId)),
    );
    if (mounted) _progress.forward();
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: (context, index) =>
                  _ThrowbackPage(item: widget.items[index]),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _progress.stop();
                        _goTo(_index - 1);
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _progress.stop();
                        _goTo(_index + 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 52,
              top: 8,
              child: Row(
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (context, _) {
                            final value = i < _index
                                ? 1.0
                                : (i == _index ? _progress.value : 0.0);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 3,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                color: Colors.white,
                              ),
                            );
                          },
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
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _ThrowbackFooter(
                item: widget.items[_index],
                onOpenFull: _openFullEntry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThrowbackPage extends StatelessWidget {
  final ThrowbackItem item;

  const _ThrowbackPage({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textStyleDefaults = context.watch<TextStyleStore>();
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final entry = item.entry;
    final feelingNotes = entry.notes
        .where((n) => n.category == kNoteCategoryFeeling)
        .toList();
    final note = feelingNotes.isNotEmpty ? feelingNotes.first : null;
    final backgroundId = note?.backgroundId ?? textStyleDefaults.backgroundId;
    final dateLabel = DateFormat.yMMMd(locale).format(entry.createdAt);

    return Stack(
      fit: StackFit.expand,
      children: [
        DiaryScreenBackground(backgroundId: backgroundId),
        Container(color: Colors.black.withValues(alpha: 0.15)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 120),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScrimText(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        throwbackLabelFor(l10n, item.monthsAgo),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dateLabel, style: theme.textTheme.labelMedium),
                          if (entry.emotion != null) ...[
                            const SizedBox(width: 8),
                            EmotionPill(
                              tag: entry.emotion!,
                              label: entry.emotion!.labelFor(l10n),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 16),
                  ScrimText(
                    child: Text(
                      note.content,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: applyNoteStyle(
                        theme.textTheme.bodyLarge,
                        note: note,
                        defaults: textStyleDefaults,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThrowbackFooter extends StatelessWidget {
  final ThrowbackItem item;
  final Future<void> Function(int entryId) onOpenFull;

  const _ThrowbackFooter({required this.item, required this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entryId = item.entry.id;
    if (entryId == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          backgroundColor: Colors.black.withValues(alpha: 0.25),
        ),
        onPressed: () => onOpenFull(entryId),
        icon: const Icon(Icons.open_in_full, size: 16),
        label: Text(l10n.throwbackOpenFull),
      ),
    );
  }
}
