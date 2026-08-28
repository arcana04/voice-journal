import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/diary_background.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../state/text_style_store.dart';
import '../utils/custom_background_picker.dart';
import '../utils/note_text_style.dart';
import '../widgets/app_background_image.dart';
import '../widgets/diary_background_tile.dart';
import '../widgets/diary_entry_card.dart';
import '../widgets/icon_button_style.dart';
import '../widgets/scrim_text.dart';
import 'diary_view_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final Map<int, GlobalKey> _itemKeys = {};

  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _pendingScrollDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
  }

  GlobalKey _keyFor(int entryId) =>
      _itemKeys.putIfAbsent(entryId, () => GlobalKey());

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
                Widget sizeOption(String label, double scale) {
                  final selected = defaults.fontScale == scale;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => defaults.setDefault(
                        fontFamilyIndex: defaults.fontFamilyIndex,
                        textColor: defaults.textColor,
                        fontScale: scale,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.blue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                Widget colorOption(Color? color) {
                  final selected = defaults.textColor == color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => defaults.setDefault(
                        fontFamilyIndex: defaults.fontFamilyIndex,
                        textColor: color,
                        fontScale: defaults.fontScale,
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color ?? Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.4),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: color == null
                            ? Icon(
                                Icons.block,
                                size: 18,
                                color: Colors.grey.withValues(alpha: 0.6),
                              )
                            : null,
                      ),
                    ),
                  );
                }

                Widget fontOption(int index) {
                  final option = noteFontOptions[index];
                  final selected = defaults.fontFamilyIndex == index;
                  final label = option.labelFor(l10n);
                  return GestureDetector(
                    onTap: () => defaults.setDefault(
                      fontFamilyIndex: index,
                      textColor: defaults.textColor,
                      fontScale: defaults.fontScale,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Colors.blue
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: option.apply(const TextStyle(fontSize: 15)),
                      ),
                    ),
                  );
                }

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
                      Row(
                        children: [
                          sizeOption('H1', 1.5),
                          sizeOption('H2', 1.25),
                          sizeOption('H3', 1.0),
                          sizeOption('H4', 0.85),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final color in noteTextColorOptions)
                              colorOption(color),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.6,
                        children: [
                          for (var i = 0; i < noteFontOptions.length; i++)
                            fontOption(i),
                        ],
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
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
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

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visibleMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _visibleMonth = DateTime(picked.year, picked.month);
      _pendingScrollDate = picked;
    });
  }

  void _scheduleScrollIfNeeded(List<JournalEntry> diaryEntries) {
    final target = _pendingScrollDate;
    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      JournalEntry? match;
      for (final e in diaryEntries) {
        if (_isSameDate(e.createdAt, target)) {
          match = e;
          break;
        }
      }
      if (match != null) {
        final ctx = _keyFor(match.id!).currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0,
          );
        }
      }
      if (mounted) setState(() => _pendingScrollDate = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                final diaryEntries = store.entries
                    .where(
                      (e) =>
                          e.notes.any(
                            (n) => n.category == kNoteCategoryFeeling,
                          ) &&
                          e.createdAt.year == _visibleMonth.year &&
                          e.createdAt.month == _visibleMonth.month,
                    )
                    .toList();

                _scheduleScrollIfNeeded(diaryEntries);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: ScrimText(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Text(
                                DateFormat.yMMMM(
                                  Localizations.localeOf(context).toString(),
                                ).format(_visibleMonth),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                      child: diaryEntries.isEmpty
                          ? Center(
                              child: ScrimText(
                                child: Text(
                                  AppLocalizations.of(context)!.diaryMonthEmpty,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: store.load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                                children: [
                                  for (final entry in diaryEntries)
                                    KeyedSubtree(
                                      key: _keyFor(entry.id!),
                                      child: DiaryEntryCard(
                                        entry: entry,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => DiaryViewScreen(
                                              entryId: entry.id!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            bottom: 120,
            child: FloatingActionButton(
              heroTag: 'diary_calendar_fab',
              onPressed: () => _pickDate(context),
              child: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
