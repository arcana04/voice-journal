import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/journal_store.dart';
import '../widgets/entry_card.dart';
import '../widgets/heatmap_calendar.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
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
      appBar: AppBar(title: const Text('タイムライン')),
      body: Consumer<JournalStore>(
        builder: (context, store, _) {
          if (store.loading && store.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.entries.isEmpty) {
            return Center(
              child: Text(
                'まだ記録がありません\n録音してみましょう',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: store.load,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: store.entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: HeatmapCalendar(dateCounts: store.dateCounts),
                  );
                }
                final entry = store.entries[index - 1];
                return EntryCard(
                  entry: entry,
                  onToggleTask: (task) => store.toggleTask(entry, task),
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
