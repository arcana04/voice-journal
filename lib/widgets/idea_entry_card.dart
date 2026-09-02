import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/idea_status.dart';
import '../models/journal_entry.dart';
import 'edit_icon_button.dart';

/// アイデア画面用のカード。ある録音から生まれた「アイデア」だけを表示する。
/// タイトル・本文の変更は鉛筆アイコンから編集画面で行うが、ピン留め・検討状況は
/// カード上で直接変更できる。
class IdeaEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final List<NoteItem> ideas;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(NoteItem idea, {required bool pinned}) onTogglePin;
  final void Function(NoteItem idea, {required String? ideaStatus})
  onChangeStatus;

  const IdeaEntryCard({
    super.key,
    required this.entry,
    required this.ideas,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onChangeStatus,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  Future<void> _pickStatus(BuildContext context, NoteItem idea) async {
    final l10n = AppLocalizations.of(context)!;
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<String?>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(value: null, child: Text(l10n.ideaStatusNone)),
        for (final status in IdeaStatus.values)
          PopupMenuItem(value: status.id, child: Text(status.labelFor(l10n))),
      ],
    );
    if (selected == idea.ideaStatus) return;
    onChangeStatus(idea, ideaStatus: selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeLabel =
        '${DateFormat.MMMd(locale).format(entry.createdAt)} ${DateFormat.Hm(locale).format(entry.createdAt)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                EditIconButton(onPressed: onEdit),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            for (final idea in ideas)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Builder(
                                builder: (buttonContext) => _StatusChip(
                                  status: IdeaStatus.fromId(idea.ideaStatus),
                                  onTap: () =>
                                      _pickStatus(buttonContext, idea),
                                ),
                              ),
                              if ((idea.tag ?? '').trim().isNotEmpty)
                                _TagChip(label: idea.tag!.trim()),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            idea.pinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 20,
                            color: idea.pinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          tooltip: idea.pinned
                              ? l10n.ideaUnpinTooltip
                              : l10n.ideaPinTooltip,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              onTogglePin(idea, pinned: !idea.pinned),
                        ),
                      ],
                    ),
                    if ((idea.title ?? '').isNotEmpty)
                      Text(
                        idea.title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(idea.content, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IdeaStatus? status;
  final VoidCallback onTap;

  const _StatusChip({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = status?.color ?? theme.colorScheme.outline;
    final label = status?.labelFor(l10n) ?? l10n.ideaStatusLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$label',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
