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

  const DiaryEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onAddPhotos,
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
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  monthLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
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
          if (entry.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(entry.summary, style: theme.textTheme.titleMedium),
          ],
          ..._buildNoteSection(
            theme,
            title: 'アイデア',
            notes: entry.notes.where((n) => n.category == kNoteCategoryIdea).toList(),
          ),
          ..._buildNoteSection(
            theme,
            title: '感情ログ',
            notes: entry.notes.where((n) => n.category == kNoteCategoryFeeling).toList(),
          ),
          if (entry.comfortMessage != null && entry.comfortMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.comfortMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  List<Widget> _buildNoteSection(
    ThemeData theme, {
    required String title,
    required List<NoteItem> notes,
  }) {
    if (notes.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Text(title, style: theme.textTheme.labelLarge),
      const SizedBox(height: 4),
      ...notes.map(
        (note) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(note.content, style: theme.textTheme.bodyMedium),
        ),
      ),
    ];
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
