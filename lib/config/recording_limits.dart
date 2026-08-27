/// 1回の録音の最大長（無料プラン）。
const int kMaxRecordingSeconds = 60;

const Duration kMaxRecordingDuration = Duration(seconds: kMaxRecordingSeconds);

/// 1回の録音の最大長（Proプラン）＝15分。
const int kProMaxRecordingSeconds = 15 * 60;

const Duration kProMaxRecordingDuration = Duration(seconds: kProMaxRecordingSeconds);

/// 加入プランに応じた1回の録音の最大長。
Duration maxRecordingDurationFor(bool isPro) =>
    isPro ? kProMaxRecordingDuration : kMaxRecordingDuration;

/// これより連続して静かな状態が続いたら、話し終えたとみなして録音を自動停止する。
const Duration kSilenceAutoStopDuration = Duration(seconds: 30);

/// この音量(dBFS)を下回っていたら無音とみなす。0が最大音量、値が低いほど静か。
const double kSilenceThresholdDb = -35.0;
