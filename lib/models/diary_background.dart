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
  parkDay('park_day', 'assets/images/diary_backgrounds/diary_bg_park_day.png'),
  nightSky(
    'night_sky',
    'assets/images/diary_backgrounds/diary_bg_night_sky.png',
  ),
  sleepingCat(
    'sleeping_cat',
    'assets/images/diary_backgrounds/diary_bg_sleeping_cat.png',
  ),
  blueCheckBouquet(
    'blue_check_bouquet',
    'assets/images/diary_backgrounds/diary_bg_blue_check_bouquet.png',
  ),
  vintageCamera(
    'vintage_camera',
    'assets/images/diary_backgrounds/diary_bg_vintage_camera.png',
  ),
  shopping(
    'shopping',
    'assets/images/diary_backgrounds/diary_bg_shopping.png',
  ),
  newYork('new_york', 'assets/images/diary_backgrounds/diary_bg_new_york.png'),
  beach('beach', 'assets/images/diary_backgrounds/diary_bg_beach.png'),
  palmTree(
    'palm_tree',
    'assets/images/diary_backgrounds/diary_bg_palm_tree.png',
  ),
  europeanStreet(
    'european_street',
    'assets/images/diary_backgrounds/diary_bg_european_street.png',
  ),
  running('running', 'assets/images/diary_backgrounds/diary_bg_running.png'),
  livingRoom(
    'living_room',
    'assets/images/diary_backgrounds/diary_bg_living_room.png',
  ),
  musicNote(
    'music_note',
    'assets/images/diary_backgrounds/diary_bg_music_note.png',
  ),
  letter('letter', 'assets/images/diary_backgrounds/diary_bg_letter.png'),
  deepSea(
    'deep_sea',
    'assets/images/diary_backgrounds/diary_bg_deep_sea.png',
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
    DiaryBackground.parkDay => l10n.diaryBgParkDay,
    DiaryBackground.nightSky => l10n.diaryBgNightSky,
    DiaryBackground.sleepingCat => l10n.diaryBgSleepingCat,
    DiaryBackground.blueCheckBouquet => l10n.diaryBgBlueCheckBouquet,
    DiaryBackground.vintageCamera => l10n.diaryBgVintageCamera,
    DiaryBackground.shopping => l10n.diaryBgShopping,
    DiaryBackground.newYork => l10n.diaryBgNewYork,
    DiaryBackground.beach => l10n.diaryBgBeach,
    DiaryBackground.palmTree => l10n.diaryBgPalmTree,
    DiaryBackground.europeanStreet => l10n.diaryBgEuropeanStreet,
    DiaryBackground.running => l10n.diaryBgRunning,
    DiaryBackground.livingRoom => l10n.diaryBgLivingRoom,
    DiaryBackground.musicNote => l10n.diaryBgMusicNote,
    DiaryBackground.letter => l10n.diaryBgLetter,
    DiaryBackground.deepSea => l10n.diaryBgDeepSea,
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
