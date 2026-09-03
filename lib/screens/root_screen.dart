import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/deep_link_service.dart';
import '../services/reminder_service.dart';
import '../state/account_store.dart';
import '../state/idea_brainstorm_request_store.dart';
import '../state/journal_store.dart';
import '../state/record_trigger_store.dart';
import '../state/subscription_store.dart';
import '../widgets/floating_nav_bar.dart';
import 'account_screen.dart';
import 'diary_screen.dart';
import 'home_screen.dart';
import 'idea_screen.dart';
import 'knowledge_base_screen.dart';
import 'task_screen.dart';
import 'weekly_report_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  final DeepLinkService _deepLinks = DeepLinkService();
  bool? _lastIsPro;

  static const _screens = [
    HomeScreen(),
    DiaryScreen(),
    IdeaScreen(),
    TaskScreen(),
    KnowledgeBaseScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _deepLinks.init(onRecordRequested: _handleRecordRequested);
    ReminderService.instance.weeklyReportRequests
        .addListener(_handleWeeklyReportRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncOnStartupIfSignedIn());
  }

  /// アプリ起動のたびに、サインイン済み(匿名でない)アカウントならクラウドから
  /// 自動で取り込む。これまでは「アカウントを復元」ボタンを手動で押さない限り
  /// クラウド上の変更（例: Apple Watch単体で録音・保存したエントリ）が
  /// この端末に一切反映されなかったため。
  Future<void> _syncOnStartupIfSignedIn() async {
    if (!mounted) return;
    if (!context.read<AccountStore>().isSignedIn) return;
    final store = context.read<JournalStore>();
    // fullSyncは現在のentriesと突き合わせて「まだ無いものだけ」取り込むため、
    // Provider作成時の非同期loadと競合してentriesが空のまま呼ばれると、
    // 既にローカルにあるエントリまで新規として再挿入してしまう。ここで
    // 一度loadしてentriesを最新化してからfullSyncする。
    await store.load();
    if (!mounted) return;
    final canSyncMedia = context.read<SubscriptionStore>().isProWithMediaSync;
    await store.fullSync(canSyncMedia: canSyncMedia);
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    ReminderService.instance.weeklyReportRequests
        .removeListener(_handleWeeklyReportRequested);
    super.dispose();
  }

  void _handleRecordRequested() {
    // initState中（アプリ起動直後）に呼ばれると、HomeScreen側がまだ
    // RecordTriggerStoreのリスナー登録（didChangeDependencies）を終えておらず、
    // notifyListeners()が届かず録音開始が無視されてしまう。最初のフレーム
    // 描画後まで発火を遅らせることで、リスナー登録後に確実に届くようにする。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _index = 0);
      context.read<RecordTriggerStore>().requestRecordNow();
    });
  }

  void _handleWeeklyReportRequested() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isPro = context.watch<SubscriptionStore>().isPro;
    if (_lastIsPro != isPro) {
      _lastIsPro = isPro;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isPro) {
          ReminderService.instance.scheduleWeeklyReportNotification();
        } else {
          ReminderService.instance.cancelWeeklyReportNotification();
        }
      });
    }

    // アイデア画面の「AIで深掘り」ボタンが押されたら、相談タブへ自動で
    // 切り替える。実際にブレインストームを開始してチャットへ積むのは
    // KnowledgeBaseScreen側（IndexedStackで常にマウントされているので
    // タブが非表示でも同じフレームでpendingを検知できる）。
    final hasPendingBrainstorm =
        context.watch<IdeaBrainstormRequestStore>().pending != null;
    if (hasPendingBrainstorm && _index != 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = 4);
      });
    }

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          Consumer<JournalStore>(
            builder: (context, store, _) {
              if (store.loadError != null) {
                return _StatusBanner(
                  icon: Icons.error_outline,
                  message: l10n.loadErrorBannerMessage,
                  actionLabel: l10n.loadErrorBannerAction,
                  onAction: store.load,
                );
              }
              if (store.syncError) {
                return _StatusBanner(
                  icon: Icons.cloud_off,
                  message: l10n.syncErrorBannerMessage,
                  actionLabel: l10n.syncErrorBannerAction,
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                );
              }
              final mediaUsage = store.mediaUsage;
              if (mediaUsage != null && mediaUsage.isWarning) {
                return _StatusBanner(
                  icon: Icons.storage_outlined,
                  message: mediaUsage.isOverCap
                      ? l10n.mediaStorageFullBannerMessage
                      : l10n.mediaStorageWarningBannerMessage,
                  actionLabel: l10n.mediaStorageBannerAction,
                  onAction: () => setState(() => _index = 1),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          FloatingNavDestination(
            icon: Icons.mic_none,
            selectedIcon: Icons.mic,
            label: l10n.navRecord,
          ),
          FloatingNavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            label: l10n.navDiary,
          ),
          FloatingNavDestination(
            icon: Icons.lightbulb_outline,
            selectedIcon: Icons.lightbulb,
            label: l10n.navIdea,
          ),
          FloatingNavDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: l10n.navTask,
          ),
          FloatingNavDestination(
            icon: Icons.psychology_outlined,
            selectedIcon: Icons.psychology,
            label: l10n.navKnowledgeBase,
          ),
        ],
      ),
    );
  }
}

/// クラウド同期失敗・データ読み込み失敗を、タブに関わらず常に見える形で
/// 知らせる細いバナー。それまでこの手の失敗はdebugPrintで握りつぶされ、
/// ユーザーからは一切見えなかった。
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Material(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
