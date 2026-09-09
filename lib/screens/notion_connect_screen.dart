import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/notion_page.dart';
import '../services/backend_service.dart';
import '../state/notion_store.dart';
import '../state/subscription_store.dart';
import '../widgets/pro_feature_gate.dart';

/// 設定画面から開くNotion連携画面。未接続時はトークン入力→共有済みページの
/// 選択→データベース作成、接続済み時は接続先の表示と解除を行う
/// ([IntegrationSelectScreen]のNotion版)。
class NotionConnectScreen extends StatefulWidget {
  const NotionConnectScreen({super.key});

  @override
  State<NotionConnectScreen> createState() => _NotionConnectScreenState();
}

class _NotionConnectScreenState extends State<NotionConnectScreen> {
  final _tokenController = TextEditingController();
  List<NotionPage>? _pages;
  String? _pendingToken;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pages = await context.read<NotionStore>().connect(
        token,
        locale: _locale,
      );
      if (!mounted) return;
      setState(() {
        _pages = pages;
        _pendingToken = token;
      });
    } on BackendServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDatabase(NotionPage page) async {
    final token = _pendingToken;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<NotionStore>().finishSetup(
        token,
        page,
        locale: _locale,
      );
    } on BackendServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDisconnect() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notionDisconnectConfirmTitle),
        content: Text(l10n.notionDisconnectConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.notionDisconnectButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final notionStore = context.read<NotionStore>();
    setState(() => _loading = true);
    try {
      await notionStore.disconnect(locale: _locale);
      if (!mounted) return;
      setState(() {
        _pages = null;
        _pendingToken = null;
        _tokenController.clear();
      });
    } on BackendServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isPro = context.watch<SubscriptionStore>().isPro;

    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.notionScreenTitle)),
        body: ProFeatureGate(
          title: l10n.notionScreenTitle,
          description: l10n.notionProLockedDescription,
        ),
      );
    }

    final isConnected = context.watch<NotionStore>().isConnected;
    final connectedPageTitle = context.watch<NotionStore>().connectedPageTitle;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notionScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            if (isConnected) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.notionConnectedStatusLabel),
                subtitle: connectedPageTitle == null
                    ? null
                    : Text(connectedPageTitle),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _confirmDisconnect,
                child: Text(l10n.notionDisconnectButton),
              ),
            ] else ...[
              Text(
                l10n.notionIntroDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 20),
              if (_pages == null) ...[
                Text(
                  l10n.notionTokenHelpText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.notionTokenFieldLabel,
                    hintText: l10n.notionTokenFieldHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submitToken,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.notionConnectButton),
                ),
              ] else ...[
                Text(
                  l10n.notionSelectPageTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_pages!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.notionNoPagesFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                else
                  for (final page in _pages!)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          page.title.isEmpty ? page.id : page.title,
                        ),
                        trailing: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _loading ? null : () => _createDatabase(page),
                      ),
                    ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                          _pages = null;
                          _pendingToken = null;
                        }),
                  child: Text(l10n.notionConnectButton),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
