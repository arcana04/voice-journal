import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/diary_entry_card.dart';
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
            child: const AppBackgroundImage(
              fallbackAsset: 'assets/images/diary_background.png',
            ),
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
