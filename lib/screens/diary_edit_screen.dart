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
import '../state/subscription_store.dart';
import '../state/text_style_store.dart';
import '../utils/custom_background_picker.dart';
import '../utils/note_text_style.dart';
import '../widgets/diary_background_tile.dart';
import '../widgets/diary_screen_background.dart';
import '../widgets/icon_button_style.dart';
import '../widgets/media_gallery.dart';
import '../widgets/note_text_style_picker.dart';
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
    _backgroundId = styleSource?.backgroundId ?? defaults.backgroundId;

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

  /// 写真と動画をまとめて選ばせる[ImagePicker.pickMultipleMedia]は、混在メディア
  /// 対応のAndroidフォトピッカーが使えない端末では汎用ファイルブラウザ（Filesアプリ）
  /// にフォールバックしてしまう。写真・動画を別々に選ばせる（[pickMultiImage]/
  /// [pickVideo]）ことで、写真選択は常にグリッド表示のフォトピッカーが使われる。
  Future<void> _pickImages(JournalStore store, JournalEntry entry) async {
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mediaPickFailed('$e')),
        ),
      );
      return;
    }
    if (picked.isEmpty || !mounted) return;
    await store.addMediaToEntry(
      entry,
      picked.map((x) => File(x.path)).toList(),
      canSyncMedia: context.read<SubscriptionStore>().isProWithMediaSync,
    );
  }

  Future<void> _pickVideo(JournalStore store, JournalEntry entry) async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mediaPickFailed('$e')),
        ),
      );
      return;
    }
    if (picked == null || !mounted) return;
    await store.addMediaToEntry(
      entry,
      [File(picked.path)],
      canSyncMedia: context.read<SubscriptionStore>().isProWithMediaSync,
    );
  }

  Future<void> _openMediaSheet(JournalStore store, JournalEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MediaSheetOption(
                icon: Icons.image_outlined,
                color: _EditorColors.amber,
                title: l10n.pickPhotosFromLibrary,
                subtitle: l10n.pickPhotosFromLibrarySubtitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImages(store, entry);
                },
              ),
              const SizedBox(height: 12),
              _MediaSheetOption(
                icon: Icons.videocam_outlined,
                color: _EditorColors.indigo,
                title: l10n.pickVideoFromLibrary,
                subtitle: l10n.pickVideoFromLibrarySubtitle,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickVideo(store, entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBackgroundSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.backgroundSheetTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // 背景画像の実サイズ（841x1870）に合わせた比率。以前は0.8で、
                    // 実際は縦長の画像を横長のタイルにcoverで収めていたため上下が
                    // 大きく見切れていた。これで画像全体がクロップされずに見える。
                    childAspectRatio: 841 / 1870,
                    children: [
                      DiaryBackgroundTile(
                        label: l10n.backgroundNone,
                        selected: _backgroundId == null,
                        onTap: () {
                          setState(() => _backgroundId = null);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Container(
                          color: _EditorColors.indigo.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: _EditorColors.indigo,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.backgroundNone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _EditorColors.indigo,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final background in DiaryBackground.values)
                        DiaryBackgroundTile(
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
                      AddCustomBackgroundTile(
                        isPro: context.read<SubscriptionStore>().isPro,
                        onTap: () => pickCustomBackground(
                          sheetContext,
                          onPicked: (id) => setState(() => _backgroundId = id),
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
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.emotionSheetTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
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
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Material(
                            color: _EditorColors.indigo.withValues(alpha: 0.1),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: Icon(Icons.check, color: _EditorColors.indigo),
                              tooltip: AppLocalizations.of(context)!.closeTooltip,
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      NoteTextStylePicker(
                        fontFamilyIndex: _fontFamilyIndex,
                        textColor: _textColor,
                        fontScale: _fontScale,
                        onFontScaleChanged: (scale) {
                          setState(() => _fontScale = scale);
                          setSheetState(() {});
                        },
                        onTextColorChanged: (color) {
                          setState(() => _textColor = color);
                          setSheetState(() {});
                        },
                        onFontFamilyIndexChanged: (index) {
                          setState(() => _fontFamilyIndex = index);
                          setSheetState(() {});
                        },
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
        final entry = store.findById(widget.entryId);
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
                style: pressableIconButtonStyle(context),
                onPressed: () => _save(store, entry),
                child: Text(AppLocalizations.of(context)!.save),
              ),
              const SizedBox(width: 8),
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
                              canSyncMedia:
                                  context.read<SubscriptionStore>().isProWithMediaSync,
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolbarButton(
                icon: Icons.add_photo_alternate_rounded,
                color: _EditorColors.indigo,
                label: l10n.toolbarMedia,
                onTap: () => _openMediaSheet(store, entry),
              ),
              _ToolbarButton(
                icon: Icons.wallpaper_rounded,
                color: _EditorColors.green,
                label: l10n.toolbarBackground,
                onTap: _openBackgroundSheet,
              ),
              _ToolbarButton(
                icon: Icons.text_fields_rounded,
                color: _EditorColors.amber,
                label: l10n.toolbarText,
                onTap: _openTextStyleSheet,
              ),
            ],
          ),
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

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 日記編集画面のボトムシート群（写真・動画・背景・フォント）で使うアクセントカラー。
/// [_SettingsColors]（settings_screen.dart）・[_BenefitColors]（paywall_screen.dart）
/// と同系統の配色にして、アプリ全体で統一感を持たせている。
class _EditorColors {
  static const indigo = Color(0xFF6C5DD3);
  static const amber = Color(0xFFE2952F);
  static const green = Color(0xFF13A67D);
}

/// 「写真を選択」「動画を選択」シートの1行分。丸いアイコンチップ＋タイトル＋
/// 説明文＋丸背景のchevronという、設定画面のカードと揃えたビジュアル。
class _MediaSheetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MediaSheetOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.chevron_right_rounded, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
