import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/apple_reminders_store.dart';

/// 設定画面から開く「リマインダー連携」画面。端末の「リマインダー」アプリに
/// すでに作成済みのリストから連携先を選ぶ（[IntegrationSelectScreen]のリマインダー版）。
class AppleRemindersSelectScreen extends StatefulWidget {
  const AppleRemindersSelectScreen({super.key});

  @override
  State<AppleRemindersSelectScreen> createState() =>
      _AppleRemindersSelectScreenState();
}

class _AppleRemindersSelectScreenState
    extends State<AppleRemindersSelectScreen> {
  late Future<({bool granted, List<({String id, String title})> lists})>
  _listsFuture;

  @override
  void initState() {
    super.initState();
    _listsFuture = context.read<AppleRemindersStore>().requestLists();
  }

  void _refresh() {
    setState(() {
      _listsFuture = context.read<AppleRemindersStore>().requestLists();
    });
  }

  void _select(({String id, String title})? list) {
    context.read<AppleRemindersStore>().setList(list);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selectedId = context.watch<AppleRemindersStore>().selectedListId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appleRemindersScreenTitle)),
      body: SafeArea(
        child: RadioGroup<String?>(
          groupValue: selectedId,
          onChanged: (value) {
            if (value == null) {
              _select(null);
              return;
            }
            _listsFuture.then((result) {
              for (final list in result.lists) {
                if (list.id == value) {
                  _select(list);
                  return;
                }
              }
            });
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                l10n.appleRemindersDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              RadioListTile<String?>(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.integrationsOff),
                value: null,
              ),
              const Divider(),
              FutureBuilder<
                ({bool granted, List<({String id, String title})> lists})
              >(
                future: _listsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final granted = snapshot.data?.granted ?? false;
                  final lists = snapshot.data?.lists ?? const [];
                  if (!granted) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appleRemindersPermissionDenied,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.allow),
                          ),
                        ],
                      ),
                    );
                  }
                  if (lists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appleRemindersNoLists,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.integrationsRefresh),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final list in lists)
                        RadioListTile<String?>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(list.title),
                          value: list.id,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
