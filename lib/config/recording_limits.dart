/// 1回の録音の最大長。
///
/// 現在は無料版のみで一律この秒数。将来、課金プランごとに上限を変える場合は
/// ここを差し替える（例: 有料版は180秒など）。
const int kMaxRecordingSeconds = 60;

const Duration kMaxRecordingDuration = Duration(seconds: kMaxRecordingSeconds);
