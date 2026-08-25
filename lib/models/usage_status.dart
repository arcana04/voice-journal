/// 本日の無料枠の利用状況（JST基準）。
class UsageStatus {
  final int used;
  final int limit;

  const UsageStatus({required this.used, required this.limit});

  int get remaining => (limit - used).clamp(0, limit);
}
