import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

/// 日記の詳細画面。既定では読み取り専用で表示し、右上の鉛筆アイコンから
/// 編集モードに切り替えて「保存」でコミットする。
class DiaryDetailScreen extends StatefulWidget {
  final JournalEntry entry;
  final Future<void> Function(List<File> files) onAddPhotos;
  final void Function(NoteItem note, String? title, String content) onUpdateNote;
  final VoidCallback onDelete;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
    required this.onAddPhotos,
    required this.onUpdateNote,
    required this.onDelete,
  });

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

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

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  bool _editing = false;
  late final List<_NoteDraft> _drafts =
      widget.entry.notes.map((n) => _NoteDraft(n)).toList();

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _save() {
    for (final d in _drafts) {
      final title = d.titleController.text.trim();
      var content = d.contentController.text.trim();
      if (content.isEmpty) {
        content = d.note.content;
      }
      d.titleController.text = title;
      d.contentController.text = content;
      widget.onUpdateNote(d.note, title.isEmpty ? null : title, content);
    }
    setState(() => _editing = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: const Text('この記録を削除すると元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.onDelete();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('写真の選択に失敗しました: $e')));
      return;
    }
    if (picked.isEmpty) return;
    await widget.onAddPhotos(picked.map((x) => File(x.path)).toList());
  }

  void _openPhotoViewer(String path, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(paths: widget.entry.imagePaths, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final day = DateFormat('d').format(entry.createdAt);
    final monthLabel = DateFormat('M月').format(entry.createdAt);
    final yearLabel = DateFormat('yyyy').format(entry.createdAt);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _pickPhotos,
            tooltip: '写真を追加',
          ),
          if (_editing)
            TextButton(onPressed: _save, child: const Text('保存'))
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
              tooltip: '編集',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
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
              for (final d in _drafts) _buildNoteBlock(theme, d),
              if (entry.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPhotoGrid(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteBlock(ThemeData theme, _NoteDraft d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editing
              ? TextField(
                  controller: d.titleController,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '題名',
                    hintStyle:
                        theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              : (d.titleController.text.isNotEmpty
                  ? Text(
                      d.titleController.text,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    )
                  : const SizedBox.shrink()),
          const SizedBox(height: 8),
          _editing
              ? TextField(
                  controller: d.contentController,
                  minLines: 3,
                  maxLines: null,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'ここにもっと書く…',
                    hintStyle:
                        theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              : Text(d.contentController.text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < widget.entry.imagePaths.length; i++)
          GestureDetector(
            onTap: () => _openPhotoViewer(widget.entry.imagePaths[i], i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(widget.entry.imagePaths[i]),
                width: 104,
                height: 104,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const _PhotoViewer({required this.paths, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(File(widget.paths[index])),
            ),
          );
        },
      ),
    );
  }
}
