import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/video_thumbnail_service.dart';
import '../utils/media_type.dart';
import 'emotion_bubble.dart';

/// 日記画面の一覧に出す、タップで詳細画面を開くための読み取り専用プレビューカード。
class DiaryEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const DiaryEntryCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeLabel = DateFormat.Hm(locale).format(entry.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (entry.emotion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: EmotionPill(
                      tag: entry.emotion!,
                      label: entry.emotion!.labelFor(AppLocalizations.of(context)!),
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
            for (final note in entry.notes.where(
              (n) => n.category == kNoteCategoryFeeling,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((note.title ?? '').isNotEmpty)
                      Text(
                        note.title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            if (entry.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildMediaPreview(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ThemeData theme) {
    const maxShown = 4;
    final shown = entry.imagePaths.take(maxShown).toList();
    final remaining = entry.imagePaths.length - shown.length;
    const thumbSize = 68.0;

    return SizedBox(
      height: thumbSize,
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _MediaPreviewTile(
              path: shown[i],
              size: thumbSize,
              overlayLabel: (i == shown.length - 1 && remaining > 0)
                  ? '+$remaining'
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

/// 一覧カードの添付サムネイル1枚分。動画は実際のフレーム画像を生成して表示する
/// （編集/閲覧画面の[MediaGallery]と同じ[VideoThumbnailService]を使う）。
class _MediaPreviewTile extends StatefulWidget {
  final String path;
  final double size;
  final String? overlayLabel;

  const _MediaPreviewTile({
    required this.path,
    required this.size,
    this.overlayLabel,
  });

  @override
  State<_MediaPreviewTile> createState() => _MediaPreviewTileState();
}

class _MediaPreviewTileState extends State<_MediaPreviewTile> {
  final _thumbnailService = VideoThumbnailService();
  String? _videoThumbnailPath;

  @override
  void initState() {
    super.initState();
    if (isVideoPath(widget.path)) {
      _thumbnailService.getOrCreateThumbnail(widget.path).then((thumbPath) {
        if (mounted) setState(() => _videoThumbnailPath = thumbPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = isVideoPath(widget.path);
    final videoThumb = _videoThumbnailPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              videoThumb != null
                  ? Image.file(File(videoThumb), fit: BoxFit.cover)
                  : const ColoredBox(color: Colors.black87)
            else
              Image.file(File(widget.path), fit: BoxFit.cover),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            if (widget.overlayLabel != null)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                child: Text(
                  widget.overlayLabel!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
