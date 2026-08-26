import '../l10n/app_localizations.dart';

/// アプリ全体（録音・日記・アイデア・タスクの4画面）の背景として選べる画像。
/// [id]はSharedPreferencesへの保存キー。nullは「デフォルト」（各画面固有の背景のまま）を表す。
enum AppBackground {
  aurora('aurora', 'assets/images/backgrounds/bg_aurora.png'),
  whitehavenBeach('whitehaven_beach', 'assets/images/backgrounds/bg_whitehaven_beach.png'),
  flowerPark('flower_park', 'assets/images/backgrounds/bg_flower_park.png'),
  starrySky('starry_sky', 'assets/images/backgrounds/bg_starry_sky.png'),
  balloon('balloon', 'assets/images/backgrounds/bg_balloon.png'),
  savanna('savanna', 'assets/images/backgrounds/bg_savanna.png'),
  desert('desert', 'assets/images/backgrounds/bg_desert.png'),
  deepSea('deep_sea', 'assets/images/backgrounds/bg_deep_sea.png'),
  amazon('amazon', 'assets/images/backgrounds/bg_amazon.png'),
  cat('cat', 'assets/images/backgrounds/bg_cat.png');

  final String id;
  final String asset;
  const AppBackground(this.id, this.asset);

  String labelFor(AppLocalizations l10n) => switch (this) {
        AppBackground.aurora => l10n.backgroundAurora,
        AppBackground.whitehavenBeach => l10n.backgroundWhitehavenBeach,
        AppBackground.flowerPark => l10n.backgroundFlowerPark,
        AppBackground.starrySky => l10n.backgroundStarrySky,
        AppBackground.balloon => l10n.backgroundBalloon,
        AppBackground.savanna => l10n.backgroundSavanna,
        AppBackground.desert => l10n.backgroundDesert,
        AppBackground.deepSea => l10n.backgroundDeepSea,
        AppBackground.amazon => l10n.backgroundAmazon,
        AppBackground.cat => l10n.backgroundCat,
      };

  static AppBackground? fromId(String? id) {
    if (id == null) return null;
    for (final b in AppBackground.values) {
      if (b.id == id) return b;
    }
    return null;
  }
}
