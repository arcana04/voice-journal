import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../widgets/media_gallery.dart';

class _NoteDraft {
  final NoteItem note;
  final TextEditingController titleController;
  final TextEditingController contentController;

  _NoteDraft(this.note)
      : titleController = TextEditingController(text: note.title ?? ''),
        contentController = TextEditingController(text: note.content);

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}

/// 日記の編集画面。写真・動画の追加はここでのみ行える。
class DiaryEditScreen extends StatefulWidget {
  final int entryId;

  const DiaryEditScreen({super.key, required this.entryId});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  List<_NoteDraft>? _drafts;

  JournalEntry? _findEntry(JournalStore store) {
    for (final e in store.entries) {
      if (e.id == widget.entryId) return e;
    }
    return null;
  }

  List<_NoteDraft> _ensureDrafts(JournalEntry entry) {
    return _drafts ??= entry.notes.map((n) => _NoteDraft(n)).toList();
  }

  @override
  void dispose() {
    for (final d in _drafts ?? const <_NoteDraft>[]) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_NoteDraft>[]) {
      final title = d.titleController.text.trim();
      var content = d.contentController.text.trim();
      if (content.isEmpty) content = d.note.content;
      await store.updateNoteText(
        entry,
        d.note,
        title: title.isEmpty ? null : title,
        content: content,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickMedia(JournalStore store, JournalEntry entry) async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultipleMedia(imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('写真・動画の選択に失敗しました: $e')));
      return;
    }
    if (picked.isEmpty) return;
    await store.addMediaToEntry(entry, picked.map((x) => File(x.path)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = _findEntry(store);
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final theme = Theme.of(context);
        final drafts = _ensureDrafts(entry);
        final day = DateFormat('d').format(entry.createdAt);
        final monthLabel = DateFormat('M月').format(entry.createdAt);
        final yearLabel = DateFormat('yyyy').format(entry.createdAt);

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: '写真・動画を追加',
                onPressed: () => _pickMedia(store, entry),
              ),
              TextButton(
                onPressed: () => _save(store, entry),
                child: const Text('保存'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        day,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$monthLabel $yearLabel',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final d in drafts) _buildNoteBlock(theme, d),
                  if (entry.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MediaGallery(
                      paths: entry.imagePaths,
                      onRemove: (index) =>
                          store.removeMediaFromEntry(entry, entry.imagePaths[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteBlock(ThemeData theme, _NoteDraft d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: d.titleController,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: '題名',
              hintStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: d.contentController,
            minLines: 3,
            maxLines: null,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'ここにもっと書く…',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
