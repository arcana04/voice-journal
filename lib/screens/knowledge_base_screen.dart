import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/idea_brainstorm.dart';
import '../services/backend_service.dart';
import '../state/idea_brainstorm_request_store.dart';
import '../state/journal_store.dart';
import '../state/subscription_store.dart';
import '../utils/journal_context_format.dart';
import '../widgets/app_background_image.dart';
import '../widgets/idea_angle_card.dart';
import '../widgets/pro_feature_gate.dart';
import '../widgets/scrim_text.dart';

class _ChatMessage {
  final String question;
  String? answer;
  List<IdeaAngle>? angles;
  String? error;
  bool loading = true;

  _ChatMessage({required this.question});
}

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final BackendService _backend = BackendService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

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
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    _controller.clear();

    final message = _ChatMessage(question: question);
    setState(() => _messages.add(message));
    _scrollToBottom();

    final locale = Localizations.localeOf(context).languageCode;
    final entries = context.read<JournalStore>().entries;
    final contextText = formatEntriesAsContext(entries, locale);

    try {
      final answer = await _backend.askKnowledgeBase(
        question,
        context: contextText,
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        message.answer = answer;
        message.loading = false;
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

  /// アイデア画面の「AIで深掘り」ボタン（[IdeaBrainstormRequestStore]経由）から
  /// 起動される。通常の質問と同じ吹き出しの流れに乗せつつ、回答は3枚の
  /// カード（[IdeaAngle]）として表示する。
  Future<void> _sendBrainstorm(IdeaBrainstormRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final question = l10n.ideaBrainstormChatQuestion(request.title);
    final message = _ChatMessage(question: question);
    setState(() => _messages.add(message));
    _scrollToBottom();

    final locale = Localizations.localeOf(context).languageCode;

    try {
      final angles = await _backend.brainstormIdea(
        title: request.title,
        content: request.content,
        locale: locale,
      );
      if (!mounted) return;
      setState(() {
        message.angles = angles;
        message.loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message.error = e is BackendServiceException
            ? e.message
            : AppLocalizations.of(context)!.ideaBrainstormErrorTitle;
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

    final pendingBrainstorm = context.watch<IdeaBrainstormRequestStore>().pending;
    if (pendingBrainstorm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final store = context.read<IdeaBrainstormRequestStore>();
        if (store.pending == null) return; // 別フレームで既に消費済み
        store.consume();
        _sendBrainstorm(pendingBrainstorm);
      });
    }

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
                      const SizedBox(width: 8),
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
                  : message.error == null && (message.angles?.isNotEmpty ?? false)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final angle in message.angles!) IdeaAngleCard(angle: angle),
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
        ],
      ),
    );
  }
}
