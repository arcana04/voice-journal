/// 1回の録音の最大長。
///
/// 現在は無料版のみで一律この秒数。将来、課金プランごとに上限を変える場合は
/// ここを差し替える（例: 有料版は180秒など）。
const int kMaxRecordingSeconds = 60;

const Duration kMaxRecordingDuration = Duration(seconds: kMaxRecordingSeconds);

/// これより連続して静かな状態が続いたら、話し終えたとみなして録音を自動停止する。
const Duration kSilenceAutoStopDuration = Duration(seconds: 30);

/// この音量(dBFS)を下回っていたら無音とみなす。0が最大音量、値が低いほど静か。
const double kSilenceThresholdDb = -35.0;
