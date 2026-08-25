const _videoExtensions = ['.mp4', '.mov', '.m4v', '.avi'];

/// パスの拡張子から、写真ではなく動画かどうかを判定する。
bool isVideoPath(String path) {
  final lower = path.toLowerCase();
  return _videoExtensions.any(lower.endsWith);
}
