import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// アイデアの検討状況。[NoteItem.ideaStatus]に生文字列の[id]で保存される。
enum IdeaStatus {
  considering('considering', Color(0xFF8A6D1D)),
  adopted('adopted', Color(0xFF2E7D4F)),
  rejected('rejected', Color(0xFF8A4A4A));

  final String id;
  final Color color;

  const IdeaStatus(this.id, this.color);

  String labelFor(AppLocalizations l10n) => switch (this) {
    IdeaStatus.considering => l10n.ideaStatusConsidering,
    IdeaStatus.adopted => l10n.ideaStatusAdopted,
    IdeaStatus.rejected => l10n.ideaStatusRejected,
  };

  static IdeaStatus? fromId(String? id) {
    if (id == null) return null;
    for (final s in IdeaStatus.values) {
      if (s.id == id) return s;
    }
    return null;
  }
}
