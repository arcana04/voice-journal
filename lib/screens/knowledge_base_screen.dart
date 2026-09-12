import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/knowledge_base_source.dart';
import '../services/backend_service.dart';
import '../services/recorder_service.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../utils/journal_context_format.dart';
import '../widgets/app_background_image.dart';
import '../widgets/emotion_bubble.dart';
import '../widgets/pro_feature_gate.dart';
import '../widgets/scrim_text.dart';
import 'account_screen.dart';

class _ChatMessage {
  final String question;
  String? answer;
  String? error;
  bool loading = true;
  List<KnowledgeBaseSource> sources = const [];

  /// 匿名アカウントのまま埋め込み検索の同期記録が無く(≒[sources]が空のまま)
  /// 応答が返ってきた、まさにその瞬間だけアカウント連携を促す。セッション中に
  /// 一度出したら以降は繰り返さない([_KnowledgeBaseScreenState._signInNudgeShown]参照)。
  bool showSignInNudge = false;

  _ChatMessage({required this.question});
}

/// マイクボタンの3状態。録音→文字起こしの間はテキスト送信と分けて扱う。
enum _VoiceState { idle, recording, transcribing }

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final BackendService _backend = BackendService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RecorderService _recorder = RecorderService();
  final List<_ChatMessage> _messages = [];
  bool _signInNudgeShown = false;
  _VoiceState _voiceState = _VoiceState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalStore>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();
    await _ask(question);
  }

  /// マイクボタンのタップを録音開始/停止の2状態にトグルする。
  Future<void> _toggleVoiceQuestion() async {
    if (_voiceState == _VoiceState.recording) {
      await _finishVoiceQuestion();
      return;
    }
    if (_voiceState != _VoiceState.idle) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.micPermissionDenied)));
      return;
    }
    try {
      await _recorder.start();
    } catch (_) {
      // 録音タブと違い補助的な導線のため、失敗時は静かに諦めてテキスト入力に戻す。
      return;
    }
    if (!mounted) return;
    setState(() => _voiceState = _VoiceState.recording);
  }

  Future<void> _finishVoiceQuestion() async {
    setState(() => _voiceState = _VoiceState.transcribing);
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    if (path == null) {
      if (!mounted) return;
      setState(() => _voiceState = _VoiceState.idle);
      return;
    }

    final locale = Localizations.localeOf(context).languageCode;
    try {
      final question = await _backend.transcribeQuestion(File(path), locale: locale);
      if (!mounted) return;
      setState(() => _voiceState = _VoiceState.idle);
      if (question.isEmpty) return;
      await _ask(question);
    } catch (e) {
      if (!mounted) return;
      setState(() => _voiceState = _VoiceState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is BackendServiceException
                ? e.message
                : AppLocalizations.of(context)!.knowledgeBaseErrorTitle,
          ),
        ),
      );
    }
  }

  /// 参照カードを出す最大件数。裏側の埋め込み検索自体はより多くの記録を
  /// AIのコンテキストに渡すことがあるが、UI上は「答えの裏付け」がぱっと
  /// 見て分かる程度の枚数に絞り、横スクロールが煩雑にならないようにする。
  static const _maxDisplayedSources = 5;

  /// 直近のやり取りをそのまま会話の履歴としてサーバーへ渡す。「それって
  /// どういうこと？」のような追撃質問に対応するため
  /// （[[project_voicejournal_knowledge_base_chat]]参照）。回答が返ってきた
  /// メッセージだけを対象にする（読み込み中・エラーのものは除く）。
  static const _maxHistoryTurns = 6;

  List<Map<String, String>> _buildHistory() {
    return _messages
        .where((m) => m.answer != null && m.answer!.isNotEmpty)
        .map((m) => {'question': m.question, 'answer': m.answer!})
        .toList()
        .reversed
        .take(_maxHistoryTurns)
        .toList()
        .reversed
        .toList();
  }

  /// テキスト入力・音声質問どちらもここに合流する。
  Future<void> _ask(String question) async {
    final history = _buildHistory();
    final message = _ChatMessage(question: question);
    setState(() => _messages.add(message));
    _scrollToBottom();

    final locale = Localizations.localeOf(context).languageCode;
    final entries = context.read<JournalStore>().entries;
    final contextText = formatEntriesAsContext(entries, locale);

    try {
      final result = await _backend.askKnowledgeBase(
        question,
        context: contextText,
        locale: locale,
        history: history,
      );
      if (!mounted) return;
      final isAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
      setState(() {
        message.answer = result.answer;
        message.sources = result.sources.take(_maxDisplayedSources).toList();
        message.loading = false;
        if (isAnonymous && result.sources.isEmpty && !_signInNudgeShown) {
          message.showSignInNudge = true;
          _signInNudgeShown = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message.error = e is BackendServiceException
            ? e.message
            : AppLocalizations.of(context)!.knowledgeBaseErrorTitle;
        message.loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPro = context.watch<SubscriptionStore>().isPro;

    if (!isPro) {
      return Scaffold(
        body: ProFeatureGate(
          title: l10n.knowledgeBaseTitle,
          description: l10n.knowledgeBaseProLockedDescription,
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackgroundImage()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: ScrimText(
                    child: Text(
                      l10n.knowledgeBaseTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ScrimText(
                              child: Text(
                                l10n.knowledgeBaseDescription,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _ChatBubbles(message: _messages[index]),
                        ),
                ),
                if (_voiceState != _VoiceState.idle)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _voiceState == _VoiceState.recording
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _voiceState == _VoiceState.recording
                              ? l10n.knowledgeBaseRecordingQuestion
                              : l10n.knowledgeBaseTranscribing,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                theme.colorScheme.surface.withValues(alpha: 0.85),
                            hintText: l10n.knowledgeBaseInputHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _voiceState == _VoiceState.transcribing
                            ? null
                            : _toggleVoiceQuestion,
                        icon: Icon(
                          _voiceState == _VoiceState.recording
                              ? Icons.stop_circle_rounded
                              : Icons.mic_none_rounded,
                          color: _voiceState == _VoiceState.recording
                              ? theme.colorScheme.error
                              : null,
                        ),
                        tooltip: l10n.knowledgeBaseVoiceQuestion,
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.arrow_upward),
                        tooltip: l10n.knowledgeBaseSend,
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

class _ChatBubbles extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubbles({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.question,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: message.loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.knowledgeBaseThinking,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Text(
                      message.error ?? message.answer ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: message.error != null
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
            ),
          ),
          if (!message.loading && message.sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: _SourceCardRow(sources: message.sources),
              ),
            ),
          ],
          if (message.showSignInNudge) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: const _SignInNudgeCard(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 匿名アカウントのまま埋め込み検索の対象記録が無かった(≒クラウド同期
/// されていない)ことが分かった直後に、その場でアカウント連携を促すカード。
/// セッション中1回だけ、実際に限界にぶつかった文脈でのみ出す
/// (オンボーディングに追加すると初回体験の摩擦になるため避けた judgment)。
class _SignInNudgeCard extends StatelessWidget {
  const _SignInNudgeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.knowledgeBaseSignInNudgeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
              child: Text(l10n.knowledgeBaseSignInNudgeCta),
            ),
          ),
        ],
      ),
    );
  }
}

/// 回答の下に横スクロールで並ぶ「参照した記録」カード列。埋め込み検索で
/// 実際に選ばれた上位K件をそのまま出しているため、AIの自己申告と違い
/// 確実に「本当にコンテキストへ渡された記録」になる。
class _SourceCardRow extends StatelessWidget {
  final List<KnowledgeBaseSource> sources;

  const _SourceCardRow({required this.sources});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            l10n.knowledgeBaseSourcesLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sources.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _SourceCard(source: sources[index]),
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final KnowledgeBaseSource source;

  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = source.date;
    final dateLabel = date != null
        ? DateFormat.Md(Localizations.localeOf(context).languageCode)
            .format(date)
        : '';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openSource(context, source),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dateLabel.isNotEmpty)
              Text(
                dateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              source.excerpt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _openSource(BuildContext context, KnowledgeBaseSource source) {
    final entries = context.read<JournalStore>().entries;
    JournalEntry? match;
    for (final entry in entries) {
      if (entry.remoteId == source.entryId) {
        match = entry;
        break;
      }
    }
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.knowledgeBaseSourceNotFound),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SourceEntrySheet(entry: match!),
    );
  }
}

/// ソースカードをタップした時に表示する、その記録の中身そのもの
/// (要約・日記/アイデアのノート・タスク)を見せるシート。特定の画面種別
/// (日記のみ/アイデアのみ)に依存せず、実際にAIへ渡った内容をそのまま出す。
class _SourceEntrySheet extends StatelessWidget {
  final JournalEntry entry;

  const _SourceEntrySheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(entry.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.knowledgeBaseSourceSheetTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              if (entry.emotion != null) ...[
                const SizedBox(width: 8),
                EmotionBubble(tag: entry.emotion!, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.summary.trim().isNotEmpty) ...[
                    Text(entry.summary, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                  ],
                  for (final note in entry.notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SourceItemRow(
                        label: note.category == kNoteCategoryIdea
                            ? l10n.navIdea
                            : l10n.navDiary,
                        text: note.content,
                      ),
                    ),
                  for (final task in entry.tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SourceItemRow(
                        label: l10n.navTask,
                        text: task.title,
                        done: task.done,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceItemRow extends StatelessWidget {
  final String label;
  final String text;
  final bool done;

  const _SourceItemRow({
    required this.label,
    required this.text,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? theme.colorScheme.outline : null,
            ),
          ),
        ),
      ],
    );
  }
}
