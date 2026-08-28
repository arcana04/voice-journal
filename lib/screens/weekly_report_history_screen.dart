import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/weekly_report.dart';
import '../services/db_service.dart';
import '../state/subscription_store.dart';
import '../widgets/app_background_image.dart';
import '../widgets/pro_feature_gate.dart';
import 'weekly_report_screen.dart';

/// 過去に保存された週刊脳内レポートの一覧。タップすると、その週のスナップ
/// ショットをそのまま表示する（再生成・再集計はしない）。
class WeeklyReportHistoryScreen extends StatefulWidget {
  const WeeklyReportHistoryScreen({super.key});

  @override
  State<WeeklyReportHistoryScreen> createState() => _WeeklyReportHistoryScreenState();
}

class _WeeklyReportHistoryScreenState extends State<WeeklyReportHistoryScreen> {
  late final Future<List<SavedWeeklyReport>> _reportsFuture =
      DbService.instance.listWeeklyReports();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPro = context.watch<SubscriptionStore>().isPro;

    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.weeklyReportHistoryTitle)),
        body: ProFeatureGate(
          title: l10n.weeklyReportTitle,
          description: l10n.weeklyReportProLockedDescription,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyReportHistoryTitle)),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackgroundImage()),
          SafeArea(
            child: FutureBuilder<List<SavedWeeklyReport>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data ?? const <SavedWeeklyReport>[];
                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.weeklyReportHistoryEmpty,
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final locale = Localizations.localeOf(context).toString();
                    final dateRange =
                        '${DateFormat('yyyy.MM.dd').format(report.weekStart)} – '
                        '${DateFormat('MM.dd').format(report.weekEnd)}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.colorScheme.surface.withValues(alpha: 0.88),
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: Text(dateRange),
                        subtitle: Text(
                          report.insights.moodHeadline.isNotEmpty
                              ? report.insights.moodHeadline
                              : DateFormat.yMMMd(locale).format(report.createdAt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WeeklyReportScreen(savedReport: report),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
