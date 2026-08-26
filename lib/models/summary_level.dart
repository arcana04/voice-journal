import '../l10n/app_localizations.dart';

/// 録音・テキスト入力をAIが日記（notes）に整形する際の要約度。
/// tasksの簡潔さには影響せず、notesのリライトの強さだけを変える。
enum SummaryLevel {
  /// 原型重視：要約・圧縮せず、生の感情や言い回しをできる限り残す。
  preserve,

  /// 標準：冗長な繰り返しは整理しつつ、日記らしい自然な長さを保つ。
  standard,

  /// 超コンパクト：核心だけを1〜2文程度に短くまとめる。
  compact,
}

extension SummaryLevelX on SummaryLevel {
  String get wireValue => switch (this) {
        SummaryLevel.preserve => 'preserve',
        SummaryLevel.standard => 'standard',
        SummaryLevel.compact => 'compact',
      };

  String labelFor(AppLocalizations l10n) => switch (this) {
        SummaryLevel.preserve => l10n.summaryLevelPreserveLabel,
        SummaryLevel.standard => l10n.summaryLevelStandardLabel,
        SummaryLevel.compact => l10n.summaryLevelCompactLabel,
      };

  String descriptionFor(AppLocalizations l10n) => switch (this) {
        SummaryLevel.preserve => l10n.summaryLevelPreserveDescription,
        SummaryLevel.standard => l10n.summaryLevelStandardDescription,
        SummaryLevel.compact => l10n.summaryLevelCompactDescription,
      };

  static SummaryLevel fromWireValue(String? value) {
    return SummaryLevel.values.firstWhere(
      (level) => level.wireValue == value,
      orElse: () => SummaryLevel.preserve,
    );
  }
}
