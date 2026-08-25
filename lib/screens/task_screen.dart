import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/journal_store.dart';
import '../widgets/task_entry_card.dart';
import 'task_edit_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
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
          final taskEntries =
              store.entries.where((e) => e.tasks.isNotEmpty).toList();
          if (taskEntries.isEmpty) {
            return Center(
              child: Text(
                'まだタスクがありません\n「〜する」と話してみましょう',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: store.load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              itemCount: taskEntries.length,
              itemBuilder: (context, index) {
                final entry = taskEntries[index];
                return TaskEntryCard(
                  entry: entry,
                  onToggleTask: (task) => store.toggleTask(entry, task),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskEditScreen(entryId: entry.id!),
                    ),
                  ),
                  onDelete: () => store.deleteEntry(entry),
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
