import '../l10n/app_localizations.dart';

/// 日記（notes）をAIがリライトする際の文体（口調・言葉遣い）。
/// [SummaryLevel]（要約の強さ）とは独立の軸で、標準以外はPro限定機能。
enum DiaryStyle {
  /// 標準：飾らない自然な一人称の日記文体。
  standard,

  /// ギャル風：ハイテンション・絵文字多用のギャル語文体（Pro限定）。
  gal,

  /// 小説風：情景描写や内省的な心理変化を交えた文学的な文体（Pro限定）。
  novel,

  /// ポジティブモンスター風：どんな行動も全肯定する自己肯定感MAX文体（Pro限定）。
  positiveMonster,

  /// 箇条書き：事実・感情・次のアクションを3〜4行に絞るミニマル文体（Pro限定）。
  bulletPoints,

  /// 未来の自分へ：数ヶ月〜数年後の自分に語りかけるタイムカプセル文体（Pro限定）。
  futureSelf,

  /// ハードボイルド：感情を排し事実と決断だけを刻むストイックな文体（Pro限定）。
  hardboiled,

  /// 映画のワンシーン風：光・音・空気感を意識した映像的な文体（Pro限定）。
  cinematic,

  /// 歴史上の偉人風：日常を歴史的快挙に見立てる大言壮語な文体（Pro限定）。
  historicalHero,
}

extension DiaryStyleX on DiaryStyle {
  String get wireValue => switch (this) {
        DiaryStyle.standard => 'standard',
        DiaryStyle.gal => 'gal',
        DiaryStyle.novel => 'novel',
        DiaryStyle.positiveMonster => 'positive_monster',
        DiaryStyle.bulletPoints => 'bullet_points',
        DiaryStyle.futureSelf => 'future_self',
        DiaryStyle.hardboiled => 'hardboiled',
        DiaryStyle.cinematic => 'cinematic',
        DiaryStyle.historicalHero => 'historical_hero',
      };

  /// Pro加入が必要なスタイルかどうか。
  bool get requiresPro => this != DiaryStyle.standard;

  String labelFor(AppLocalizations l10n) => switch (this) {
        DiaryStyle.standard => l10n.diaryStyleStandardLabel,
        DiaryStyle.gal => l10n.diaryStyleGalLabel,
        DiaryStyle.novel => l10n.diaryStyleNovelLabel,
        DiaryStyle.positiveMonster => l10n.diaryStylePositiveMonsterLabel,
        DiaryStyle.bulletPoints => l10n.diaryStyleBulletPointsLabel,
        DiaryStyle.futureSelf => l10n.diaryStyleFutureSelfLabel,
        DiaryStyle.hardboiled => l10n.diaryStyleHardboiledLabel,
        DiaryStyle.cinematic => l10n.diaryStyleCinematicLabel,
        DiaryStyle.historicalHero => l10n.diaryStyleHistoricalHeroLabel,
      };

  String descriptionFor(AppLocalizations l10n) => switch (this) {
        DiaryStyle.standard => l10n.diaryStyleStandardDescription,
        DiaryStyle.gal => l10n.diaryStyleGalDescription,
        DiaryStyle.novel => l10n.diaryStyleNovelDescription,
        DiaryStyle.positiveMonster =>
          l10n.diaryStylePositiveMonsterDescription,
        DiaryStyle.bulletPoints => l10n.diaryStyleBulletPointsDescription,
        DiaryStyle.futureSelf => l10n.diaryStyleFutureSelfDescription,
        DiaryStyle.hardboiled => l10n.diaryStyleHardboiledDescription,
        DiaryStyle.cinematic => l10n.diaryStyleCinematicDescription,
        DiaryStyle.historicalHero => l10n.diaryStyleHistoricalHeroDescription,
      };

  static DiaryStyle fromWireValue(String? value) {
    return DiaryStyle.values.firstWhere(
      (style) => style.wireValue == value,
      orElse: () => DiaryStyle.standard,
    );
  }
}
