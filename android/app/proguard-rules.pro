# flutter_local_notificationsが内部でGsonを使って予約通知をシリアライズしており、
# R8のデフォルト圧縮だとTypeTokenのジェネリクス情報が消えて端末再起動時に
# ScheduledNotificationBootReceiverがクラッシュする(実機のリリースビルドで発生確認済み)。
# パッケージ公式ドキュメント記載のkeepルール。
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.dexterous.**

# device_calendarも同様に、カレンダー情報(Calendarモデル等)をGsonでJSON化して
# Dart側へ渡している。R8がフィールド名を難読化するとJSONのキーが一致せず、
# カレンダー名・IDが空文字になる(連携画面で実機確認済みのバグ)。
-keep class com.builttoroam.devicecalendar.** { *; }
-dontwarn com.builttoroam.devicecalendar.**
