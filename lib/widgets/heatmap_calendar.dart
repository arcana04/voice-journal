import 'package:flutter/material.dart';

/// 直近の録音履歴を GitHub 風のヒートマップで表示するカレンダー。
/// [dateCounts] は 'yyyy-MM-dd' 形式の日付キーと当日の記録件数のマップ。
class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> dateCounts;
  final int weeks;

  const HeatmapCalendar({
    super.key,
    required this.dateCounts,
    this.weeks = 12,
  });

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    // 直近の日曜日を末尾の週の始まりにする
    final endOfWeek = todayMidnight.add(Duration(days: 6 - todayMidnight.weekday % 7));
    final totalDays = weeks * 7;
    final start = endOfWeek.subtract(Duration(days: totalDays - 1));

    final columns = <List<DateTime?>>[];
    for (var w = 0; w < weeks; w++) {
      final column = <DateTime?>[];
      for (var d = 0; d < 7; d++) {
        final date = start.add(Duration(days: w * 7 + d));
        column.add(date.isAfter(todayMidnight) ? null : date);
      }
      columns.add(column);
    }

    int streak = 0;
    for (var i = 0; ; i++) {
      final date = todayMidnight.subtract(Duration(days: i));
      final count = dateCounts[_dateKey(date)] ?? 0;
      if (count == 0) {
        if (i == 0) continue; // 今日はまだ未記録でも streak を切らない
        break;
      }
      streak++;
    }

    final activeDays = dateCounts.values.where((c) => c > 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('継続記録', style: theme.textTheme.labelLarge),
              Text(
                streak > 0 ? '$streak日連続' : '直近$weeks週間で$activeDays日記録',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      children: [
                        for (final date in column)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: _DayCell(
                              count: date == null ? null : (dateCounts[_dateKey(date)] ?? 0),
                              isToday: date != null && date == todayMidnight,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? count;
  final bool isToday;

  const _DayCell({required this.count, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    Color color;
    if (count == null) {
      color = Colors.transparent;
    } else if (count == 0) {
      color = theme.colorScheme.surfaceContainerHighest;
    } else if (count == 1) {
      color = accent.withValues(alpha: 0.35);
    } else if (count == 2) {
      color = accent.withValues(alpha: 0.65);
    } else {
      color = accent;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: isToday ? Border.all(color: accent, width: 1.5) : null,
      ),
    );
  }
}
