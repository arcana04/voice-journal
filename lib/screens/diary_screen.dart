import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/journal_store.dart';
import '../widgets/diary_entry_card.dart';

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
      appBar: AppBar(title: const Text('日記')),
      body: Consumer<JournalStore>(
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: diaryEntries.length,
              itemBuilder: (context, index) {
                final entry = diaryEntries[index];
                return DiaryEntryCard(
                  entry: entry,
                  onDelete: () => store.deleteEntry(entry),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
