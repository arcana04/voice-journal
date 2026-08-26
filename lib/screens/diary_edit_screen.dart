import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../state/journal_store.dart';
import '../state/text_style_store.dart';
import '../utils/note_text_style.dart';
import '../widgets/media_gallery.dart';

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
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.backgroundSheetTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.blue),
              title: Text(l10n.backgroundNone),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.comingSoon,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
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
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed: () => _save(store, entry),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomToolbar(store, entry),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        day,
                        style: theme.textTheme.headlineMedium?.copyWith(
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
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
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
                  const SizedBox(height: 20),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
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
