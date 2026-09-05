/// 本日の無料枠の利用状況（JST基準）。
class UsageStatus {
  final int used;
  final int limit;

  /// Pro/買い切みプラン限定の月間録音時間の状況。無料プランはnull
  /// （月間キャップの対象外のため、サーバーからも返ってこない）。
  final int? monthlyUsedSeconds;
  final int? monthlyLimitSeconds;
  final int? bonusSecondsBalance;

  const UsageStatus({
    required this.used,
    required this.limit,
    this.monthlyUsedSeconds,
    this.monthlyLimitSeconds,
    this.bonusSecondsBalance,
  });

  int get remaining => (limit - used).clamp(0, limit);

  bool get hasMonthlyBudget => monthlyLimitSeconds != null;

  int get monthlyRemainingSeconds {
    final used = monthlyUsedSeconds ?? 0;
    final limit = monthlyLimitSeconds ?? 0;
    final bonus = bonusSecondsBalance ?? 0;
    return ((limit - used) + bonus).clamp(0, 1 << 30);
  }
}
