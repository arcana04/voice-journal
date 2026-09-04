import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/diary_background.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../state/text_style_store.dart';
import '../utils/custom_background_picker.dart';
import '../widgets/app_background_image.dart';
import '../widgets/diary_background_tile.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/icon_button_style.dart';
import '../widgets/note_text_style_picker.dart';
import '../widgets/scrim_text.dart';
import 'diary_view_screen.dart';
import 'manual_diary_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  late DateTime _weekStart = _weekStartFor(_selectedDate);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// その日を含む週の月曜日（週の先頭）を返す。
  static DateTime _weekStartFor(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _weekStart = _weekStartFor(_selectedDate);
    });
  }

  void _shiftWeek(int weeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weeks));
      _selectedDate = _weekStart;
    });
  }

  void _shiftDay(int days) => _selectDate(_selectedDate.add(Duration(days: days)));

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _selectDate(picked);
  }

  /// AIが新しい日記を作るたびに毎回同じ文字スタイル・背景を選び直す手間を
  /// なくすため、日記一覧の上から直接デフォルトを設定できるようにする画面。
  /// ここで選んだ内容は[TextStyleStore]に保存され、以後AIが作成する日記や
  /// 未設定の日記に自動で適用される（[DiaryEditScreen]の各シートと同じ仕組み）。
  void _openFavoriteSettingsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Consumer<TextStyleStore>(
              builder: (context, defaults, _) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.favoriteSettingsSheetTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            tooltip: l10n.closeTooltip,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      Text(
                        l10n.favoriteSettingsDescription,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.fontSheetTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoteTextStylePicker(
                        fontFamilyIndex: defaults.fontFamilyIndex,
                        textColor: defaults.textColor,
                        fontScale: defaults.fontScale,
                        onFontScaleChanged: (scale) => defaults.setDefault(
                          fontFamilyIndex: defaults.fontFamilyIndex,
                          textColor: defaults.textColor,
                          fontScale: scale,
                        ),
                        onTextColorChanged: (color) => defaults.setDefault(
                          fontFamilyIndex: defaults.fontFamilyIndex,
                          textColor: color,
                          fontScale: defaults.fontScale,
                        ),
                        onFontFamilyIndexChanged: (index) => defaults.setDefault(
                          fontFamilyIndex: index,
                          textColor: defaults.textColor,
                          fontScale: defaults.fontScale,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        l10n.backgroundSheetTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        // 背景画像の実サイズ（841x1870）に合わせた比率。
                        childAspectRatio: 841 / 1870,
                        children: [
                          DiaryBackgroundTile(
                            label: l10n.backgroundNone,
                            selected: defaults.backgroundId == null,
                            onTap: () => defaults.setDefaultBackground(null),
                            child: const ColoredBox(
                              color: Color(0x11000000),
                              child: Icon(Icons.block, color: Colors.grey),
                            ),
                          ),
                          for (final background in DiaryBackground.values)
                            DiaryBackgroundTile(
                              label: background.labelFor(l10n),
                              selected: defaults.backgroundId == background.id,
                              onTap: () =>
                                  defaults.setDefaultBackground(background.id),
                              child: Image.asset(
                                background.asset,
                                fit: BoxFit.cover,
                              ),
                            ),
                          AddCustomBackgroundTile(
                            isPro: context.read<SubscriptionStore>().isPro,
                            onTap: () => pickCustomBackground(
                              sheetContext,
                              onPicked: defaults.setDefaultBackground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      floatingActionButton: Padding(
        // 外側のRootScreenが持つフローティングナビゲーションバー（透過で背後に
        // body が回り込む extendBody:true）と重ならないよう、その高さ分だけ上げる。
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 76,
        ),
        child: FloatingActionButton(
          heroTag: 'manual_diary_fab',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManualDiaryScreen()),
          ),
          tooltip: AppLocalizations.of(context)!.manualDiaryFabTooltip,
          child: const Icon(Icons.add),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppBackgroundImage(),
          ),
          SafeArea(
            child: Consumer<JournalStore>(
              builder: (context, store, _) {
                if (store.loading && store.entries.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allDiaryEntries = store.entries
                    .where(
                      (e) => e.notes.any(
                        (n) => n.category == kNoteCategoryFeeling,
                      ),
                    )
                    .toList();
                final dayEntries =
                    allDiaryEntries
                        .where((e) => _isSameDate(e.createdAt, _selectedDate))
                        .toList()
                      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                bool hasEntry(DateTime day) =>
                    allDiaryEntries.any((e) => _isSameDate(e.createdAt, day));
                final accent = context.watch<SettingsStore>().accentColor;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent,
                              Color.lerp(accent, Colors.black, 0.25)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          '日記',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    _WeekStrip(
                      weekStart: _weekStart,
                      selectedDate: _selectedDate,
                      locale: locale,
                      hasEntry: hasEntry,
                      onSelectDate: _selectDate,
                      onPreviousWeek: () => _shiftWeek(-1),
                      onNextWeek: () => _shiftWeek(1),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Row(
                        children: [
                          ScrimText(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat.E(locale).format(_selectedDate),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                Text(
                                  DateFormat.MMMd(locale).format(_selectedDate),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.calendar_month_outlined),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.diaryPickDateTooltip,
                            style: pressableIconButtonStyle(context),
                            onPressed: () => _pickDate(context),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.star_border),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.favoriteSettingsTooltip,
                            style: pressableIconButtonStyle(context),
                            onPressed: () =>
                                _openFavoriteSettingsSheet(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -200) {
                            _shiftDay(1);
                          } else if (velocity > 200) {
                            _shiftDay(-1);
                          }
                        },
                        child: dayEntries.isEmpty
                            ? Center(
                                child: ScrimText(
                                  child: Text(
                                    AppLocalizations.of(context)!.diaryDayEmpty,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: store.load,
                                child: ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 8, 0, 96),
                                  children: [
                                    for (final entry in dayEntries)
                                      DiaryEntryCard(
                                        entry: entry,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => DiaryViewScreen(
                                              entryId: entry.id!,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 月曜始まりの週を横一列で表示し、日付をタップして選択できるバー。
/// 日記のある日には下に小さなドットを表示する。
class _WeekStrip extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDate;
  final String locale;
  final bool Function(DateTime day) hasEntry;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const _WeekStrip({
    required this.weekStart,
    required this.selectedDate,
    required this.locale,
    required this.hasEntry,
    required this.onSelectDate,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) {
          onNextWeek();
        } else if (velocity > 200) {
          onPreviousWeek();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.diaryPreviousWeekTooltip,
              onPressed: onPreviousWeek,
            ),
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(
                  builder: (_) {
                    final day = weekStart.add(Duration(days: i));
                    return _DayCell(
                      day: day,
                      locale: locale,
                      selected:
                          day.year == selectedDate.year &&
                          day.month == selectedDate.month &&
                          day.day == selectedDate.day,
                      isToday:
                          day.year == today.year &&
                          day.month == today.month &&
                          day.day == today.day,
                      hasEntry: hasEntry(day),
                      onTap: () => onSelectDate(day),
                    );
                  },
                ),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.diaryNextWeekTooltip,
              onPressed: onNextWeek,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final String locale;
  final bool selected;
  final bool isToday;
  final bool hasEntry;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.locale,
    required this.selected,
    required this.isToday,
    required this.hasEntry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.E(locale).format(day),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              border: !selected && isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 6,
            height: 6,
            child: hasEntry
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
