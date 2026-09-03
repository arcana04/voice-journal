import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/media_type.dart';

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
