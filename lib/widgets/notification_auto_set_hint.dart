import 'package:flutter/material.dart';

/// 「時刻付きタスクには自動で通知が設定される」ことを伝える、一度きりで
/// 消せるヒント。アプリ全体のアクセントカラーに寄せた淡い縁取りカードで、
/// エラー/警告バナー(root_screen.dartの`_StatusBanner`)とは違い押し付け
/// がましくならないよう常設ではなく閉じるボタンで即座に消せる。
///
/// 通知の自動設定は(1)録音・テキスト入力をAIが仕分けた直後の確認画面
/// （[entry_review.dart]）と、(2)手動でのタスク作成・既存タスクの編集
/// （どちらも[TaskScheduleEditor]、`manual_task_screen.dart`/
/// `task_edit_screen.dart`）の2箇所で起こりうる。ユーザーが一度も時刻を
/// 話さず、常に手動で時刻を追加するタイプだと前者だけに出しても永遠に
/// 気づけないため、両方の画面から同じヒントを呼べるよう共通化している。
class NotificationAutoSetHint extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const NotificationAutoSetHint({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
