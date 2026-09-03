import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/entry_image.dart';
import '../models/journal_entry.dart';
import '../services/video_thumbnail_service.dart';
import '../state/journal_store.dart';
import '../utils/media_type.dart';
import 'media_gallery.dart';

const double _kBaseTileSize = 110;
const double _kMinScale = 0.5;
const double _kMaxScale = 2.0;
const double _kDefaultCanvasHeight = 260;

/// 日記に添付された写真・動画を表示するキャンバス。[editable]がtrue
/// (Pro限定)の場合はドラッグでの自由配置とスライダーでの連続リサイズが
/// でき、falseの場合は保存済みの配置をそのまま表示するだけの読み取り専用
/// になる。位置・サイズを一度も調整していない画像は自動で並べる。
/// [onRemove]はPro状態に関わらず常に有効（添付削除は既存の無料機能）。
class DiaryMediaCanvas extends StatefulWidget {
  final JournalEntry entry;
  final bool editable;
  final ValueChanged<String>? onRemove;
  final double height;

  const DiaryMediaCanvas({
    super.key,
    required this.entry,
    required this.editable,
    this.onRemove,
    this.height = _kDefaultCanvasHeight,
  });

  @override
  State<DiaryMediaCanvas> createState() => _DiaryMediaCanvasState();
}

class _DiaryMediaCanvasState extends State<DiaryMediaCanvas> {
  String? _selectedPath;
  final Map<String, Offset> _liveDragCenters = {};
  double? _liveScale;

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaViewer(paths: widget.entry.imagePaths, initialIndex: index),
      ),
    );
  }

  Offset _autoPosition(int unarrangedIndex, double canvasWidth) {
    final tileStep = _kBaseTileSize + 10;
    final cols = math.max(1, (canvasWidth / tileStep).floor());
    final col = unarrangedIndex % cols;
    final row = unarrangedIndex ~/ cols;
    return Offset((col + 0.5) * tileStep, (row + 0.5) * tileStep);
  }

  void _commitPosition(
    EntryImage image,
    Offset centerPx,
    double scale,
    double canvasW,
    double canvasH,
  ) {
    context.read<JournalStore>().updateImagePosition(
      widget.entry,
      image.path,
      x: (centerPx.dx / canvasW).clamp(0.0, 1.0),
      y: (centerPx.dy / canvasH).clamp(0.0, 1.0),
      scale: scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.entry.images;
    if (images.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final canvasH = widget.height;

        EntryImage? selected;
        var unarrangedIndex = 0;
        final tiles = <Widget>[];

        for (var i = 0; i < images.length; i++) {
          final image = images[i];
          final isSelected = widget.editable && _selectedPath == image.path;
          if (isSelected) selected = image;

          final scale = (isSelected && _liveScale != null)
              ? _liveScale!
              : (image.scale ?? 1.0).clamp(_kMinScale, _kMaxScale);
          final size = _kBaseTileSize * scale;

          final Offset centerPx;
          if (_liveDragCenters.containsKey(image.path)) {
            centerPx = _liveDragCenters[image.path]!;
          } else if (image.x != null && image.y != null) {
            centerPx = Offset(image.x! * canvasW, image.y! * canvasH);
          } else {
            centerPx = _autoPosition(unarrangedIndex, canvasW);
            unarrangedIndex++;
          }

          tiles.add(
            Positioned(
              left: (centerPx.dx - size / 2).clamp(0.0, math.max(0.0, canvasW - size)),
              top: (centerPx.dy - size / 2).clamp(0.0, math.max(0.0, canvasH - size)),
              width: size,
              height: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!widget.editable) {
                    _openViewer(i);
                    return;
                  }
                  setState(() {
                    _selectedPath = _selectedPath == image.path ? null : image.path;
                    _liveScale = null;
                  });
                },
                onDoubleTap: () => _openViewer(i),
                onPanStart: !widget.editable
                    ? null
                    : (_) => setState(() {
                        _selectedPath = image.path;
                        _liveScale = null;
                        _liveDragCenters[image.path] = centerPx;
                      }),
                onPanUpdate: !widget.editable
                    ? null
                    : (details) => setState(() {
                        _liveDragCenters[image.path] =
                            (_liveDragCenters[image.path] ?? centerPx) + details.delta;
                      }),
                onPanEnd: !widget.editable
                    ? null
                    : (_) {
                        final finalCenter = _liveDragCenters[image.path];
                        setState(() => _liveDragCenters.remove(image.path));
                        if (finalCenter != null) {
                          _commitPosition(image, finalCenter, scale, canvasW, canvasH);
                        }
                      },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 2.5)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(isSelected ? 2.5 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _MediaTileVisual(path: image.path),
                          ),
                        ),
                      ),
                      if (widget.onRemove != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => widget.onRemove!(image.path),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _selectedPath = null;
                _liveScale = null;
              }),
              child: Container(
                height: canvasH,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(children: tiles),
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: 6),
              _ScaleSlider(
                value: _liveScale ?? (selected.scale ?? 1.0).clamp(_kMinScale, _kMaxScale),
                onChanged: (v) => setState(() => _liveScale = v),
                onChangeEnd: (v) {
                  final image = selected!;
                  final centerPx = image.x != null && image.y != null
                      ? Offset(image.x! * canvasW, image.y! * canvasH)
                      : _autoPosition(unarrangedIndex > 0 ? unarrangedIndex - 1 : 0, canvasW);
                  _commitPosition(image, centerPx, v, canvasW, canvasH);
                  setState(() => _liveScale = null);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _ScaleSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.photo_size_select_small_rounded, size: 18),
        Expanded(
          child: Slider(
            value: value,
            min: _kMinScale,
            max: _kMaxScale,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        const Icon(Icons.photo_size_select_large_rounded, size: 20),
      ],
    );
  }
}

/// 画像はそのまま、動画はサムネイル+再生アイコンを表示するタイルの中身。
class _MediaTileVisual extends StatefulWidget {
  final String path;

  const _MediaTileVisual({required this.path});

  @override
  State<_MediaTileVisual> createState() => _MediaTileVisualState();
}

class _MediaTileVisualState extends State<_MediaTileVisual> {
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
    if (!isVideoPath(widget.path)) {
      return Image.file(File(widget.path), fit: BoxFit.cover);
    }
    final videoThumb = _videoThumbnailPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        videoThumb != null
            ? Image.file(File(videoThumb), fit: BoxFit.cover)
            : const ColoredBox(color: Colors.black87),
        const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
        ),
      ],
    );
  }
}
