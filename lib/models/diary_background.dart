import '../l10n/app_localizations.dart';

/// 日記の各ノート（感情ログ）に個別に設定できる背景イラスト。
/// アプリ全体の単色背景とは独立で、未設定（null）が既定値。
enum DiaryBackground {
  fruit('fruit', 'assets/images/diary_backgrounds/diary_bg_fruit.png'),
  mintPlant(
    'mint_plant',
    'assets/images/diary_backgrounds/diary_bg_mint_plant.png',
  ),
  coffee('coffee', 'assets/images/diary_backgrounds/diary_bg_coffee.png'),
  cake('cake', 'assets/images/diary_backgrounds/diary_bg_cake.png'),
  picnic('picnic', 'assets/images/diary_backgrounds/diary_bg_picnic.png'),
  heartBalloon(
    'heart_balloon',
    'assets/images/diary_backgrounds/diary_bg_heart_balloon.png',
  ),
  sakuraStation(
    'sakura_station',
    'assets/images/diary_backgrounds/diary_bg_sakura_station.png',
  ),
  autumnLeaves(
    'autumn_leaves',
    'assets/images/diary_backgrounds/diary_bg_autumn_leaves.png',
  ),
  studyDesk(
    'study_desk',
    'assets/images/diary_backgrounds/diary_bg_study_desk.png',
  ),
  home('home', 'assets/images/diary_backgrounds/diary_bg_home.png'),
  parkDay('park_day', 'assets/images/diary_backgrounds/diary_bg_park_day.png'),
  nightSky(
    'night_sky',
    'assets/images/diary_backgrounds/diary_bg_night_sky.png',
  ),
  sadBoy('sad_boy', 'assets/images/diary_backgrounds/diary_bg_sad_boy.png'),
  beachGirl(
    'beach_girl',
    'assets/images/diary_backgrounds/diary_bg_beach_girl.png',
  ),
  sleepingCat(
    'sleeping_cat',
    'assets/images/diary_backgrounds/diary_bg_sleeping_cat.png',
  );

  final String id;
  final String asset;
  const DiaryBackground(this.id, this.asset);

  String labelFor(AppLocalizations l10n) => switch (this) {
    DiaryBackground.fruit => l10n.diaryBgFruit,
    DiaryBackground.mintPlant => l10n.diaryBgMintPlant,
    DiaryBackground.coffee => l10n.diaryBgCoffee,
    DiaryBackground.cake => l10n.diaryBgCake,
    DiaryBackground.picnic => l10n.diaryBgPicnic,
    DiaryBackground.heartBalloon => l10n.diaryBgHeartBalloon,
    DiaryBackground.sakuraStation => l10n.diaryBgSakuraStation,
    DiaryBackground.autumnLeaves => l10n.diaryBgAutumnLeaves,
    DiaryBackground.studyDesk => l10n.diaryBgStudyDesk,
    DiaryBackground.home => l10n.diaryBgHome,
    DiaryBackground.parkDay => l10n.diaryBgParkDay,
    DiaryBackground.nightSky => l10n.diaryBgNightSky,
    DiaryBackground.sadBoy => l10n.diaryBgSadBoy,
    DiaryBackground.beachGirl => l10n.diaryBgBeachGirl,
    DiaryBackground.sleepingCat => l10n.diaryBgSleepingCat,
  };

  /// 未設定（背景なし）を表すnullを含め、保存済みIDから復元する。
  static DiaryBackground? fromId(String? id) {
    if (id == null) return null;
    for (final b in DiaryBackground.values) {
      if (b.id == id) return b;
    }
    return null;
  }
}
