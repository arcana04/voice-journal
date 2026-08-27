import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/diary_background.dart';
import '../models/emotion_tag.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../state/text_style_store.dart';
import '../utils/note_text_style.dart';
import '../widgets/diary_screen_background.dart';
import '../widgets/media_gallery.dart';
import '../widgets/scrim_text.dart';

class _NoteDraft {
  final NoteItem note;
  final TextEditingController titleController;
  final TextEditingController contentController;

  _NoteDraft(this.note)
    : titleController = TextEditingController(text: note.title ?? ''),
      contentController = TextEditingController(text: note.content);

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}

/// 日記の編集画面。写真・動画の追加はここでのみ行える。
class DiaryEditScreen extends StatefulWidget {
  final int entryId;

  const DiaryEditScreen({super.key, required this.entryId});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  List<_NoteDraft>? _drafts;
  late double _fontScale;
  late int _fontFamilyIndex;
  late Color? _textColor;
  String? _backgroundId;

  JournalEntry? _findEntry(JournalStore store) {
    for (final e in store.entries) {
      if (e.id == widget.entryId) return e;
    }
    return null;
  }

  List<_NoteDraft> _ensureDrafts(JournalEntry entry) {
    final existing = _drafts;
    if (existing != null) return existing;

    final feelingNotes = entry.notes
        .where((n) => n.category == kNoteCategoryFeeling)
        .toList();
    // 既にスタイルが保存されているノートがあればそれを初期値にし、なければ
    // アプリ全体のデフォルトスタイルを使う（[[TextStyleStore]]参照）。
    final styleSource = feelingNotes.isNotEmpty ? feelingNotes.first : null;
    final defaults = context.read<TextStyleStore>();
    _fontFamilyIndex = styleSource?.fontFamilyIndex ?? defaults.fontFamilyIndex;
    _textColor = styleSource?.fontFamilyIndex != null
        ? (styleSource!.textColorValue != null
              ? Color(styleSource.textColorValue!)
              : null)
        : defaults.textColor;
    _fontScale = styleSource?.fontScale ?? defaults.fontScale;
    _backgroundId = styleSource?.backgroundId;

    return _drafts = feelingNotes.map((n) => _NoteDraft(n)).toList();
  }

  @override
  void dispose() {
    for (final d in _drafts ?? const <_NoteDraft>[]) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _save(JournalStore store, JournalEntry entry) async {
    for (final d in _drafts ?? const <_NoteDraft>[]) {
      final title = d.titleController.text.trim();
      var content = d.contentController.text.trim();
      if (content.isEmpty) content = d.note.content;
      await store.updateNoteText(
        entry,
        d.note,
        title: title.isEmpty ? null : title,
        content: content,
      );
      await store.updateNoteStyle(
        entry,
        d.note,
        fontFamilyIndex: _fontFamilyIndex,
        textColor: _textColor,
        fontScale: _fontScale,
        backgroundId: _backgroundId,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickMedia(JournalStore store, JournalEntry entry) async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultipleMedia(imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mediaPickFailed('$e')),
        ),
      );
      return;
    }
    if (picked.isEmpty) return;
    await store.addMediaToEntry(
      entry,
      picked.map((x) => File(x.path)).toList(),
    );
  }

  Future<void> _openMediaSheet(JournalStore store, JournalEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.pickFromLibrary),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickMedia(store, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openBackgroundSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.backgroundSheetTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                    children: [
                      _DiaryBackgroundTile(
                        label: l10n.backgroundNone,
                        selected: _backgroundId == null,
                        onTap: () {
                          setState(() => _backgroundId = null);
                          Navigator.of(sheetContext).pop();
                        },
                        child: const ColoredBox(
                          color: Color(0x11000000),
                          child: Icon(Icons.block, color: Colors.grey),
                        ),
                      ),
                      for (final background in DiaryBackground.values)
                        _DiaryBackgroundTile(
                          label: background.labelFor(l10n),
                          selected: _backgroundId == background.id,
                          onTap: () {
                            setState(() => _backgroundId = background.id);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Image.asset(
                            background.asset,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEmotionSheet(JournalStore store, JournalEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.emotionSheetTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _EmotionTile(
                    label: l10n.emotionNone,
                    selected: entry.emotion == null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await store.updateEntryEmotion(entry, null);
                    },
                    child: Icon(
                      Icons.block,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  for (final tag in EmotionTag.values)
                    _EmotionTile(
                      label: tag.labelFor(l10n),
                      selected: entry.emotion == tag,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await store.updateEntryEmotion(entry, tag);
                      },
                      child: Text(
                        tag.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTextStyleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget sizeOption(String label, double scale) {
              final selected = _fontScale == scale;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _fontScale = scale);
                    setSheetState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? Colors.blue
                            : Colors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget colorOption(Color? color) {
              final selected = _textColor == color;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _textColor = color);
                    setSheetState(() {});
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color ?? Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? Colors.blue
                            : Colors.grey.withValues(alpha: 0.4),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: color == null
                        ? Icon(
                            Icons.block,
                            size: 18,
                            color: Colors.grey.withValues(alpha: 0.6),
                          )
                        : null,
                  ),
                ),
              );
            }

            Widget fontOption(int index) {
              final option = noteFontOptions[index];
              final selected = _fontFamilyIndex == index;
              final label = option.labelFor(AppLocalizations.of(context)!);
              return GestureDetector(
                onTap: () {
                  setState(() => _fontFamilyIndex = index);
                  setSheetState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.blue.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.blue
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: option.apply(const TextStyle(fontSize: 15)),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.fontSheetTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.star_border),
                            tooltip: AppLocalizations.of(context)!
                                .setAsDefaultTooltip,
                            onPressed: () {
                              context.read<TextStyleStore>().setDefault(
                                fontFamilyIndex: _fontFamilyIndex,
                                textColor: _textColor,
                                fontScale: _fontScale,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .setAsDefaultSnackbar,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            tooltip: AppLocalizations.of(context)!.closeTooltip,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          sizeOption('H1', 1.5),
                          sizeOption('H2', 1.25),
                          sizeOption('H3', 1.0),
                          sizeOption('H4', 0.85),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final color in noteTextColorOptions)
                              colorOption(color),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.6,
                        children: [
                          for (var i = 0; i < noteFontOptions.length; i++)
                            fontOption(i),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalStore>(
      builder: (context, store, _) {
        final entry = _findEntry(store);
        if (entry == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final theme = Theme.of(context);
        final drafts = _ensureDrafts(entry);
        final locale = Localizations.localeOf(context).toString();
        final day = DateFormat('d', locale).format(entry.createdAt);
        final monthYearLabel = DateFormat.yMMMM(locale).format(entry.createdAt);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () => _save(store, entry),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomToolbar(store, entry),
          body: Stack(
            children: [
              Positioned.fill(
                child: DiaryScreenBackground(backgroundId: _backgroundId),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ScrimText(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    day,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.primary,
                                          height: 1,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      monthYearLabel,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        _openEmotionSheet(store, entry),
                                    child: entry.emotion != null
                                        ? Text(
                                            entry.emotion!.emoji,
                                            style: const TextStyle(
                                              fontSize: 32,
                                            ),
                                            semanticsLabel: entry.emotion!
                                                .labelFor(
                                                  AppLocalizations.of(context)!,
                                                ),
                                          )
                                        : Icon(
                                            Icons.add_reaction_outlined,
                                            size: 28,
                                            color: theme.colorScheme.outline,
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 48,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final d in drafts) _buildNoteBlock(theme, d),
                        if (entry.imagePaths.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          MediaGallery(
                            paths: entry.imagePaths,
                            onRemove: (index) => store.removeMediaFromEntry(
                              entry,
                              entry.imagePaths[index],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomToolbar(JournalStore store, JournalEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolbarButton(
              icon: Icons.add_photo_alternate_outlined,
              label: l10n.toolbarMedia,
              onTap: () => _openMediaSheet(store, entry),
            ),
            _ToolbarButton(
              icon: Icons.wallpaper_outlined,
              label: l10n.toolbarBackground,
              onTap: _openBackgroundSheet,
            ),
            _ToolbarButton(
              icon: Icons.text_fields,
              label: l10n.toolbarText,
              onTap: _openTextStyleSheet,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _styledText(TextStyle? base) {
    if (base == null) return null;
    final scaled = base.copyWith(
      fontSize: (base.fontSize ?? 16) * _fontScale,
      color: _textColor ?? base.color,
    );
    return noteFontOptions[_fontFamilyIndex].apply(scaled);
  }

  Widget _buildNoteBlock(ThemeData theme, _NoteDraft d) {
    final l10n = AppLocalizations.of(context)!;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: d.titleController,
          style: _styledText(
            theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: l10n.titleHint,
            hintStyle: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: d.contentController,
          minLines: 3,
          maxLines: null,
          style: _styledText(theme.textTheme.bodyLarge),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: l10n.bodyHint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: content);
  }
}

class _EmotionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _EmotionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(
                alpha: selected ? 0.15 : 0.05,
              ),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DiaryBackgroundTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _DiaryBackgroundTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 画像を見て選ぶ形式にするため、見出しテキストは表示しない
    // （読み上げ用のラベルとしてのみ[label]を使う）。
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              child: child,
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
