import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/calendar_store.dart';

/// 設定画面から開く「連携」画面。端末にすでに登録されているカレンダー
/// （iOS標準カレンダー・Googleアカウントなど）から連携先を選ぶ。
class IntegrationSelectScreen extends StatefulWidget {
  const IntegrationSelectScreen({super.key});

  @override
  State<IntegrationSelectScreen> createState() =>
      _IntegrationSelectScreenState();
}

class _IntegrationSelectScreenState extends State<IntegrationSelectScreen> {
  late Future<({bool granted, List<Calendar> calendars})> _calendarsFuture;

  @override
  void initState() {
    super.initState();
    _calendarsFuture = context.read<CalendarStore>().requestCalendars();
  }

  void _refresh() {
    setState(() {
      _calendarsFuture = context.read<CalendarStore>().requestCalendars();
    });
  }

  void _select(Calendar? calendar) {
    context.read<CalendarStore>().setCalendar(calendar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selectedId = context.watch<CalendarStore>().selectedCalendarId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.integrationsScreenTitle)),
      body: SafeArea(
        child: RadioGroup<String?>(
          groupValue: selectedId,
          onChanged: (value) {
            if (value == null) {
              _select(null);
              return;
            }
            _calendarsFuture.then((result) {
              for (final calendar in result.calendars) {
                if (calendar.id == value) {
                  _select(calendar);
                  return;
                }
              }
            });
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                l10n.integrationsDescription,
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
              FutureBuilder<({bool granted, List<Calendar> calendars})>(
                future: _calendarsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final granted = snapshot.data?.granted ?? false;
                  final calendars = snapshot.data?.calendars ?? const <Calendar>[];
                  if (!granted) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.integrationsPermissionDenied,
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
                  if (calendars.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.integrationsNoCalendars,
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
                      for (final calendar in calendars)
                        RadioListTile<String?>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(calendar.name ?? calendar.id ?? ''),
                          subtitle: calendar.accountName == null
                              ? null
                              : Text(calendar.accountName!),
                          value: calendar.id,
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
