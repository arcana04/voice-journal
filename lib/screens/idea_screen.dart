import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/idea_entry_card.dart';
import '../widgets/scrim_text.dart';
import 'idea_edit_screen.dart';

class IdeaScreen extends StatefulWidget {
  const IdeaScreen({super.key});

  @override
  State<IdeaScreen> createState() => _IdeaScreenState();
}

class _IdeaScreenState extends State<IdeaScreen> {
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

                final ideaEntries =
                    <MapEntry<JournalEntry, List<NoteItem>>>[];
                for (final entry in store.entries) {
                  final ideas = entry.notes
                      .where((n) => n.category == kNoteCategoryIdea)
                      .toList();
                  if (ideas.isNotEmpty) {
                    ideaEntries.add(MapEntry(entry, ideas));
                  }
                }

                if (ideaEntries.isEmpty) {
                  return Center(
                    child: ScrimText(
                      child: Text(
                        AppLocalizations.of(context)!.ideasEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: store.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                    itemCount: ideaEntries.length,
                    itemBuilder: (context, index) {
                      final entry = ideaEntries[index].key;
                      final ideas = ideaEntries[index].value;
                      return IdeaEntryCard(
                        entry: entry,
                        ideas: ideas,
                        onEdit: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                IdeaEditScreen(entryId: entry.id!),
                          ),
                        ),
                        onDelete: () =>
                            store.deleteNotesFromEntry(entry, ideas),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
