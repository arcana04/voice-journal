import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/review_category.dart';
import '../services/nav_icon_anchors.dart';
import '../utils/task_format.dart';

enum DraftItemType { diary, task }

/// 録音直後のAI仕分け結果を、ユーザーが保存前に確認・修正するための下書き。
class DraftItem {
  DraftItem({
    required this.id,
    required this.type,
    required this.text,
    this.dueHint,
    this.dueDate,
    this.reminderAt,
    this.reminderEndAt,
    this.isAllDay = false,
    this.notifyAt,
    this.noteCategory = kNoteCategoryIdea,
    this.noteTitle,
  });

  final String id;
  DraftItemType type;
  String text;
  final String? dueHint;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final DateTime? reminderEndAt;
  final bool isAllDay;
  final DateTime? notifyAt;
  String noteCategory;
  final String? noteTitle;
}

ReviewCategory _bucketOf(DraftItem item) {
  if (item.type == DraftItemType.task) return ReviewCategory.task;
  return item.noteCategory == kNoteCategoryIdea
      ? ReviewCategory.idea
      : ReviewCategory.diary;
}

/// 録音結果を「日記」「アイデア」「タスク」のカテゴリに分けて表示し、テキスト修正と
/// ドラッグ＆ドロップによるカテゴリの入れ替えができるレビューUI。[enabledCategories]は
/// 録音前にユーザーが絞り込んだカテゴリ（1〜3個）で、それ以外のセクションは表示しない。
/// 1個だけの場合は移動先が無いのでドラッグ＆ドロップ自体を無効にする。
class EntryReview extends StatefulWidget {
  final String summary;
  final List<DraftItem> initialItems;
  final Set<ReviewCategory> enabledCategories;
  final void Function(List<TaskItem> tasks, List<NoteItem> notes) onSave;
  final VoidCallback onDiscard;

  const EntryReview({
    super.key,
    required this.summary,
    required this.initialItems,
    required this.enabledCategories,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  State<EntryReview> createState() => _EntryReviewState();
}

class _EntryReviewState extends State<EntryReview> {
  late final List<DraftItem> _items = List.of(widget.initialItems);
  int _newItemSeq = 0;
  String? _autofocusId;
  int _cardStaggerIndex = 0;
  final GlobalKey _saveButtonKey = GlobalKey();

  void _addItem(ReviewCategory bucket) {
    final id = 'new_${_newItemSeq++}';
    final item = switch (bucket) {
      ReviewCategory.task => DraftItem(
        id: id,
        type: DraftItemType.task,
        text: '',
      ),
      ReviewCategory.idea => DraftItem(
        id: id,
        type: DraftItemType.diary,
        text: '',
        noteCategory: kNoteCategoryIdea,
      ),
      ReviewCategory.diary => DraftItem(
        id: id,
        type: DraftItemType.diary,
        text: '',
        noteCategory: kNoteCategoryFeeling,
      ),
    };
    setState(() {
      _items.add(item);
      _autofocusId = id;
    });
  }

  void _moveTo(DraftItem item, ReviewCategory bucket) {
    if (_bucketOf(item) == bucket) return;
    setState(() {
      switch (bucket) {
        case ReviewCategory.task:
          item.type = DraftItemType.task;
        case ReviewCategory.idea:
          item.type = DraftItemType.diary;
          item.noteCategory = kNoteCategoryIdea;
        case ReviewCategory.diary:
          item.type = DraftItemType.diary;
          item.noteCategory = kNoteCategoryFeeling;
      }
    });
  }

  void _removeItem(DraftItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
  }

  /// 保存ボタンから、実際に仕分けられた各項目のカテゴリに応じて日記/アイデア/
  /// タスクのナビゲーションアイコンへ、光の粒が飛んでいく演出。ボタン自身の
  /// 位置を発射点にし、[NavIconAnchors]から取得した各アイコンの矩形の中心を
  /// 着地点にする。アイコンが未レイアウト(取得失敗)ならそのカテゴリ分だけ
  /// 静かにスキップする。
  void _flyToNavIcons() {
    final buttonBox =
        _saveButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null || !buttonBox.hasSize) return;
    final origin = buttonBox.localToGlobal(buttonBox.size.center(Offset.zero));
    final overlay = Overlay.of(context, rootOverlay: true);
    final targetCache = <ReviewCategory, Rect?>{};
    var seed = 0;
    for (final item in _items) {
      if (item.text.trim().isEmpty) continue;
      final category = _bucketOf(item);
      final target = targetCache.putIfAbsent(
        category,
        () => NavIconAnchors.instance.rectFor(category),
      );
      if (target == null) continue;
      seed++;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _FlyingLight(
          origin: origin,
          target: target.center,
          seed: seed,
          onDone: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
    }
  }

  void _save() {
    _flyToNavIcons();
    final tasks = _items
        .where((i) => i.type == DraftItemType.task && i.text.trim().isNotEmpty)
        .map(
          (i) => TaskItem(
            title: i.text.trim(),
            dueHint: i.dueHint,
            dueDate: i.dueDate,
            reminderAt: i.reminderAt,
            reminderEndAt: i.reminderEndAt,
            isAllDay: i.isAllDay,
            notifyAt: i.notifyAt,
          ),
        )
        .toList();
    final notes = _items
        .where((i) => i.type == DraftItemType.diary && i.text.trim().isNotEmpty)
        .map(
          (i) => NoteItem(
            category: i.noteCategory,
            title: i.noteTitle,
            content: i.text.trim(),
          ),
        )
        .toList();
    widget.onSave(tasks, notes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // 表示順は常に日記→アイデア→タスクで固定（[widget.enabledCategories]が
    // 絞り込んだ集合なので、含まれるものだけを表示する）。
    final visibleCategories = [
      for (final c in ReviewCategory.values)
        if (widget.enabledCategories.contains(c)) c,
    ];
    final allowDrag = visibleCategories.length > 1;
    final hasContent = _items.any((i) => i.text.trim().isNotEmpty);
    _cardStaggerIndex = 0;

    return Stack(
      children: [
        _buildColumn(theme, l10n, visibleCategories, allowDrag, hasContent),
        const Positioned.fill(child: IgnorePointer(child: _BurstOverlay())),
      ],
    );
  }

  Widget _buildColumn(
    ThemeData theme,
    AppLocalizations l10n,
    List<ReviewCategory> visibleCategories,
    bool allowDrag,
    bool hasContent,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reviewTitle, style: theme.textTheme.titleMedium),
              if (widget.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                allowDrag
                    ? l10n.reviewDescription
                    : l10n.reviewDescriptionNoDrag,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              for (final category in visibleCategories) ...[
                _buildSection(
                  theme,
                  bucket: category,
                  title: category.labelFor(l10n),
                  icon: category.icon,
                  items: _items.where((i) => _bucketOf(i) == category).toList(),
                  allowDrag: allowDrag,
                  l10n: l10n,
                ),
                if (category != visibleCategories.last)
                  const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDiscard,
                  child: Text(l10n.discard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: _saveButtonKey,
                  onPressed: hasContent ? _save : null,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required ReviewCategory bucket,
    required String title,
    required IconData icon,
    required List<DraftItem> items,
    required bool allowDrag,
    required AppLocalizations l10n,
  }) {
    Widget buildContent(bool isHover) {
      return Container(
        decoration: BoxDecoration(
          color: isHover
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
          border: Border.all(
            color: isHover
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isHover ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(title, style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  allowDrag ? l10n.dragCardHere : l10n.sectionEmptyPlaceholder,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCard(theme, item, allowDrag: allowDrag),
                ),
              ),
            _AddCardButton(
              label: l10n.addCardButton,
              onTap: () => _addItem(bucket),
            ),
          ],
        ),
      );
    }

    if (!allowDrag) return buildContent(false);

    return DragTarget<DraftItem>(
      onWillAcceptWithDetails: (details) => _bucketOf(details.data) != bucket,
      onAcceptWithDetails: (details) => _moveTo(details.data, bucket),
      builder: (context, candidateData, rejectedData) =>
          buildContent(candidateData.isNotEmpty),
    );
  }

  Widget _buildCard(
    ThemeData theme,
    DraftItem item, {
    required bool allowDrag,
  }) {
    final cardShell = _CardShell(
      theme: theme,
      dragHandle: allowDrag
          ? Icon(Icons.drag_indicator, color: theme.colorScheme.outline)
          : null,
      item: item,
      autofocus: item.id == _autofocusId,
      // setStateを伴わずitem.textだけ更新すると、保存ボタンのhasContent判定
      // （build()内で毎回計算）が次の再描画まで更新されない。全カードを消して
      // 空の新規カードを追加した直後にここへ文字を入力すると、他に再描画の
      // トリガーが無いため保存ボタンが無効のまま固まっていた。
      onChanged: (value) => setState(() => item.text = value),
      onRemove: () => _removeItem(item),
    );

    final built = !allowDrag
        ? cardShell
        : LongPressDraggable<DraftItem>(
            data: item,
            delay: const Duration(milliseconds: 250),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 260,
                child: _CardShell(theme: theme, item: item, dragging: true),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: cardShell),
            child: cardShell,
          );

    // AIの仕分け結果が現れる瞬間を「光がカードへ収束する」演出にするため、
    // カード出現時だけ表示順に少しずつ遅れてポップインさせる（キー付きなので
    // 文字入力等の再ビルドでは初期化されず、一度きりのアニメーションになる）。
    return _PopIn(
      key: ValueKey('pop_${item.id}'),
      index: _cardStaggerIndex++,
      child: built,
    );
  }
}

/// [child]を、[index]に応じて少し遅れながら拡大・フェードでポップインさせる。
/// 同じキーのインスタンスが再利用される限り(＝テキスト編集などでの再ビルド時)は
/// 一度再生したら再アニメーションしない。
class _PopIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _PopIn({super.key, required this.index, required this.child});

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: 60 + widget.index * 70), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.82 + 0.18 * _scale.value, child: child),
      ),
    );
  }
}

/// AI処理中のオーブから光が弾けて画面に広がるような、レビュー画面出現時
/// 一度きりのフラッシュ演出。タップを奪わないよう常に[IgnorePointer]配下で使う。
class _BurstOverlay extends StatefulWidget {
  const _BurstOverlay();

  @override
  State<_BurstOverlay> createState() => _BurstOverlayState();
}

class _BurstOverlayState extends State<_BurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        if (t >= 1) return const SizedBox.shrink();
        final scale = 0.05 + 1.6 * t;
        final opacity = (1 - t) * 0.5;
        return Align(
          alignment: const Alignment(0, -0.55),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: opacity),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [origin]から[target]へ、光の粒が弧を描いて飛んでいく一度きりのアニメーション。
/// 保存されたカードがナビゲーションバーの該当タブへ吸い込まれていくように
/// 見せるための演出で、[Overlay]に直接挿入して使う(レビュー画面自体は保存直後
/// にホーム画面の待機表示へ切り替わって消えるため、その上に独立して残る)。
/// [seed]は同時に複数飛ばした際に軌道と速さを少しずつ変えて重ならないようにする。
class _FlyingLight extends StatefulWidget {
  final Offset origin;
  final Offset target;
  final int seed;
  final VoidCallback onDone;

  const _FlyingLight({
    required this.origin,
    required this.target,
    required this.seed,
    required this.onDone,
  });

  @override
  State<_FlyingLight> createState() => _FlyingLightState();
}

class _FlyingLightState extends State<_FlyingLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 420 + (widget.seed % 4) * 35),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final delta = widget.target - widget.origin;
    final normalLength = delta.distance == 0 ? 1.0 : delta.distance;
    // 進行方向に垂直な向きへ弧を描くように持ち上げる(中間地点で最大、
    // 両端でゼロになる山なりのオフセット)。seedの偶奇で左右どちらに
    // 膨らむかを変え、複数同時発射でも軌道が重ならないようにする。
    final unitNormal = Offset(-delta.dy, delta.dx) / normalLength;
    final arcSign = widget.seed.isEven ? 1.0 : -1.0;
    final arcHeight = 46.0 + (widget.seed % 3) * 14.0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInCubic.transform(_controller.value);
          final straight = Offset.lerp(widget.origin, widget.target, t)!;
          final arc = unitNormal * (arcSign * arcHeight * 4 * t * (1 - t));
          final position = straight + arc;
          final size = 22.0 + (4.0 - 22.0) * t;
          final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
          return Positioned(
            left: position.dx - size / 2,
            top: position.dy - size / 2,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accent, accent.withValues(alpha: 0)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.55),
                      blurRadius: size * 0.8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddCardButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final ThemeData theme;
  final DraftItem item;
  final Widget? dragHandle;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRemove;
  final bool dragging;
  final bool autofocus;

  const _CardShell({
    required this.theme,
    required this.item,
    this.dragHandle,
    this.onChanged,
    this.onRemove,
    this.dragging = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final dueLabel = dueLabelFor(
      dueDate: item.dueDate,
      dueHint: item.dueHint,
      locale: Localizations.localeOf(context).toString(),
    );
    final reminderAt = item.reminderAt;
    final reminderEndAt = item.reminderEndAt;
    final reminderLabel = reminderAt == null
        ? null
        : reminderEndAt == null
        ? DateFormat('HH:mm').format(reminderAt)
        : '${DateFormat('HH:mm').format(reminderAt)}-${DateFormat('HH:mm').format(reminderEndAt)}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ]
            : null,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dragHandle != null) ...[
            Padding(padding: const EdgeInsets.only(top: 10), child: dragHandle),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragging
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          item.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : TextFormField(
                        initialValue: item.text,
                        autofocus: autofocus,
                        minLines: 1,
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: onChanged,
                      ),
                if (dueLabel != null || reminderAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (dueLabel != null)
                          Text(
                            dueLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        if (dueLabel != null && reminderAt != null)
                          const SizedBox(width: 8),
                        if (reminderAt != null) ...[
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            reminderLabel!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
