import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/journal_store.dart';
import '../widgets/diary_entry_card.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<JournalStore>(
          builder: (context, store, _) {
            if (store.loading && store.entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final diaryEntries =
                store.entries.where((e) => e.notes.isNotEmpty).toList();
            if (diaryEntries.isEmpty) {
              return Center(
                child: Text(
                  'まだ日記・感想がありません\n思ったことを話してみましょう',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: store.load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                itemCount: diaryEntries.length,
                itemBuilder: (context, index) {
                  final entry = diaryEntries[index];
                  return DiaryEntryCard(
                    entry: entry,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DiaryDetailScreen(
                          entry: entry,
                          onAddPhotos: (files) => store.addImagesToEntry(entry, files),
                          onUpdateNote: (note, title, content) => store
                              .updateNoteText(entry, note, title: title, content: content),
                          onDelete: () => store.deleteEntry(entry),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
