import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/video_thumbnail_service.dart';
import '../utils/media_type.dart';

/// 日記に添付された写真・動画のサムネイル一覧。[onRemove]を渡すと各サムネイルに
/// 削除ボタンが付く（編集画面用）。渡さなければ表示のみ（閲覧画面用）。
class MediaGallery extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<int>? onRemove;

  const MediaGallery({super.key, required this.paths, this.onRemove});

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaViewer(paths: paths, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < paths.length; i++)
          _MediaThumbnail(
            path: paths[i],
            onTap: () => _open(context, i),
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
      ],
    );
  }
}

class _MediaThumbnail extends StatefulWidget {
  final String path;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _MediaThumbnail({required this.path, required this.onTap, this.onRemove});

  @override
  State<_MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<_MediaThumbnail> {
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
    final isVideo = isVideoPath(widget.path);
    final videoThumb = _videoThumbnailPath;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 104,
              height: 104,
              child: isVideo
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        videoThumb != null
                            ? Image.file(File(videoThumb), fit: BoxFit.cover)
                            : const ColoredBox(color: Colors.black87),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    )
                  : Image.file(File(widget.path), fit: BoxFit.cover),
            ),
          ),
          if (widget.onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 写真・動画をフルスクリーンでページ送り表示するビューア。
class MediaViewer extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const MediaViewer({super.key, required this.paths, required this.initialIndex});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);

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
          final path = widget.paths[index];
          if (isVideoPath(path)) {
            return _VideoPlayerView(path: path);
          }
          return InteractiveViewer(
            child: Center(child: Image.file(File(path))),
          );
        },
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  final String path;

  const _VideoPlayerView({required this.path});

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: _toggle,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
