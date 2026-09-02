import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/idea_status.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/idea_entry_card.dart';
import '../widgets/scrim_text.dart';
import 'idea_edit_screen.dart';
import 'manual_idea_screen.dart';

enum _IdeaFilter { all, considering, adopted, rejected }

extension on _IdeaFilter {
  String labelFor(AppLocalizations l10n) => switch (this) {
    _IdeaFilter.all => l10n.filterAll,
    _IdeaFilter.considering => l10n.ideaStatusConsidering,
    _IdeaFilter.adopted => l10n.ideaStatusAdopted,
    _IdeaFilter.rejected => l10n.ideaStatusRejected,
  };

  bool matches(NoteItem idea) => switch (this) {
    _IdeaFilter.all => true,
    _IdeaFilter.considering =>
      idea.ideaStatus == IdeaStatus.considering.id,
    _IdeaFilter.adopted => idea.ideaStatus == IdeaStatus.adopted.id,
    _IdeaFilter.rejected => idea.ideaStatus == IdeaStatus.rejected.id,
  };
}

class IdeaScreen extends StatefulWidget {
  const IdeaScreen({super.key});

  @override
  State<IdeaScreen> createState() => _IdeaScreenState();
}

class _IdeaScreenState extends State<IdeaScreen> {
  _IdeaFilter _filter = _IdeaFilter.all;
  bool _newestFirst = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(NoteItem idea) {
    if (_query.isEmpty) return true;
    return (idea.title ?? '').toLowerCase().contains(_query) ||
        idea.content.toLowerCase().contains(_query) ||
        (idea.tag ?? '').toLowerCase().contains(_query);
  }

  Widget _buildSearchField(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.ideaSearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
          filled: true,
          fillColor: theme.colorScheme.surface.withValues(alpha: 0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _IdeaFilter.values) ...[
                    _FilterChip(
                      label: filter.labelFor(l10n),
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _newestFirst
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 20,
            ),
            tooltip: _newestFirst
                ? l10n.ideaSortNewestFirstTooltip
                : l10n.ideaSortOldestFirstTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: Padding(
        // 外側のRootScreenが持つフローティングナビゲーションバー（透過で背後に
        // body が回り込む extendBody:true）と重ならないよう、その高さ分だけ上げる。
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 76,
        ),
        child: FloatingActionButton(
          heroTag: 'manual_idea_fab',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ManualIdeaScreen()),
          ),
          tooltip: AppLocalizations.of(context)!.manualIdeaFabTooltip,
          child: const Icon(Icons.add),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppBackgroundImage(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(theme),
                _buildFilterRow(theme),
                Expanded(
                  child: Consumer<JournalStore>(
                    builder: (context, store, _) {
                      if (store.loading && store.entries.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allIdeaEntries =
                          <MapEntry<JournalEntry, List<NoteItem>>>[];
                      for (final entry in store.entries) {
                        final ideas = entry.notes
                            .where((n) => n.category == kNoteCategoryIdea)
                            .toList();
                        if (ideas.isNotEmpty) {
                          allIdeaEntries.add(MapEntry(entry, ideas));
                        }
                      }

                      if (allIdeaEntries.isEmpty) {
                        return Center(
                          child: ScrimText(
                            child: Text(
                              AppLocalizations.of(context)!.ideasEmpty,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }

                      final ideaEntries =
                          <MapEntry<JournalEntry, List<NoteItem>>>[];
                      for (final e in allIdeaEntries) {
                        final visible = e.value
                            .where((idea) =>
                                _filter.matches(idea) && _matchesQuery(idea))
                            .toList();
                        if (visible.isNotEmpty) {
                          ideaEntries.add(MapEntry(e.key, visible));
                        }
                      }

                      ideaEntries.sort((a, b) {
                        final aPinned = a.value.any((i) => i.pinned);
                        final bPinned = b.value.any((i) => i.pinned);
                        if (aPinned != bPinned) {
                          return aPinned ? -1 : 1;
                        }
                        final cmp = a.key.createdAt.compareTo(b.key.createdAt);
                        return _newestFirst ? -cmp : cmp;
                      });

                      if (ideaEntries.isEmpty) {
                        return Center(
                          child: ScrimText(
                            child: Text(
                              AppLocalizations.of(context)!.ideasFilterEmpty,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
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
                              onTogglePin: (idea, {required pinned}) =>
                                  store.updateIdeaMeta(
                                entry,
                                idea,
                                ideaStatus: idea.ideaStatus,
                                pinned: pinned,
                                tag: idea.tag,
                              ),
                              onChangeStatus: (idea, {required ideaStatus}) =>
                                  store.updateIdeaMeta(
                                entry,
                                idea,
                                ideaStatus: ideaStatus,
                                pinned: idea.pinned,
                                tag: idea.tag,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
