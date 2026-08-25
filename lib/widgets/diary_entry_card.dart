import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

/// 日記画面用のカード。ある録音から生まれた「アイデア」「感情ログ」だけを表示する。
class DiaryEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDelete;
  final Future<void> Function(List<File> files) onAddPhotos;
  final void Function(NoteItem note, String? title, String content) onUpdateNote;

  const DiaryEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onAddPhotos,
    required this.onUpdateNote,
  });

  Future<void> _pickPhotos(BuildContext context) async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(imageQuality: 85);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('写真の選択に失敗しました: $e')));
      return;
    }
    if (picked.isEmpty) return;
    await onAddPhotos(picked.map((x) => File(x.path)).toList());
  }

  void _openPhotoViewer(BuildContext context, String path, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(paths: entry.imagePaths, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = DateFormat('d').format(entry.createdAt);
    final monthLabel = DateFormat('M月').format(entry.createdAt);
    final timeLabel = DateFormat('HH:mm').format(entry.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
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
                          monthLabel,
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
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  timeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                onPressed: () => _pickPhotos(context),
                visualDensity: VisualDensity.compact,
                tooltip: '写真を追加',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          for (final note in entry.notes)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _EditableNote(
                key: ValueKey(note.id),
                note: note,
                categoryLabel: note.category,
                onCommit: (title, content) => onUpdateNote(note, title, content),
              ),
            ),
          if (entry.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPhotoRow(context, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoRow(BuildContext context, ThemeData theme) {
    const maxShown = 3;
    final shown = entry.imagePaths.take(maxShown).toList();
    final remaining = entry.imagePaths.length - shown.length;

    return SizedBox(
      height: 72,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildThumbnail(
              context,
              theme,
              shown[i],
              i,
              overlayText: (i == shown.length - 1 && remaining > 0) ? '+$remaining' : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    ThemeData theme,
    String path,
    int index, {
    String? overlayText,
  }) {
    return GestureDetector(
      onTap: () => _openPhotoViewer(context, path, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(path), fit: BoxFit.cover),
              if (overlayText != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Text(
                    overlayText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

/// ノート1件分の「カテゴリ見出し・タイトル・本文」を、フォーカスが外れた
/// タイミングでコミットする編集可能ブロック。
class _EditableNote extends StatefulWidget {
  final NoteItem note;
  final String categoryLabel;
  final void Function(String? title, String content) onCommit;

  const _EditableNote({
    super.key,
    required this.note,
    required this.categoryLabel,
    required this.onCommit,
  });

  @override
  State<_EditableNote> createState() => _EditableNoteState();
}

class _EditableNoteState extends State<_EditableNote> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.note.title ?? '');
  late final TextEditingController _contentController =
      TextEditingController(text: widget.note.content);
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(_handleFocusChange);
    _contentFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_titleFocus.hasFocus && !_contentFocus.hasFocus) {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (content.isEmpty) {
        // 本文を空にはできないので元に戻す。
        _contentController.text = widget.note.content;
        return;
      }
      widget.onCommit(title.isEmpty ? null : title, content);
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _contentFocus.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoryLabel,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
        ),
        TextField(
          controller: _titleController,
          focusNode: _titleFocus,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: 'タイトル',
            hintStyle: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        TextField(
          controller: _contentController,
          focusNode: _contentFocus,
          minLines: 1,
          maxLines: 8,
          style: theme.textTheme.bodyMedium,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
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
