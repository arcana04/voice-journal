import EventKit
import Flutter

/// iPhone標準の「リマインダー」アプリ（EKReminder）と連携するためのMethodChannel。
/// CalendarService（Dart側）が使うdevice_calendarプラグインはEKEvent（予定）しか
/// 扱えないため、EKReminderはこのチャンネルで別途ブリッジする。
class AppleRemindersChannel: NSObject {
  private let eventStore = EKEventStore()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "voicejournal/apple_reminders",
      binaryMessenger: registrar.messenger()
    )
    let instance = AppleRemindersChannel()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hasPermission":
      result(Self.isAuthorized())
    case "requestPermission":
      requestPermission(result: result)
    case "fetchLists":
      result(fetchLists())
    case "upsertReminder":
      upsertReminder(call: call, result: result)
    case "deleteReminder":
      deleteReminder(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func isAuthorized() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    if #available(iOS 17.0, *) {
      return status == .fullAccess
    }
    return status == .authorized
  }

  private func requestPermission(result: @escaping FlutterResult) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToReminders { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    } else {
      eventStore.requestAccess(to: .reminder) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    }
  }

  private func fetchLists() -> [[String: String]] {
    return eventStore.calendars(for: .reminder)
      .filter { $0.allowsContentModifications }
      .map { ["id": $0.calendarIdentifier, "title": $0.title] }
  }

  /// Dartの`DateTime.toIso8601String()`（オフセット無し、ローカル時刻、
  /// ミリ秒あり/なしどちらもあり得る）をパースする。
  private static func parseIsoLocal(_ value: String) -> Date? {
    let withMillis = DateFormatter()
    withMillis.locale = Locale(identifier: "en_US_POSIX")
    withMillis.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    if let date = withMillis.date(from: value) { return date }

    let withoutMillis = DateFormatter()
    withoutMillis.locale = Locale(identifier: "en_US_POSIX")
    withoutMillis.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return withoutMillis.date(from: value)
  }

  private func upsertReminder(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let listId = args["listId"] as? String,
      let title = args["title"] as? String
    else {
      result(FlutterError(code: "bad_args", message: "missing listId/title", details: nil))
      return
    }
    guard let calendar = eventStore.calendar(withIdentifier: listId) else {
      result(FlutterError(code: "list_not_found", message: "reminder list not found", details: nil))
      return
    }

    let reminderId = args["reminderId"] as? String
    let reminder: EKReminder
    if let reminderId = reminderId,
      let existing = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder
    {
      reminder = existing
    } else {
      reminder = EKReminder(eventStore: eventStore)
    }
    reminder.calendar = calendar
    reminder.title = title
    reminder.isCompleted = args["completed"] as? Bool ?? false

    if let dueDateStr = args["dueDate"] as? String, let dueDate = Self.parseIsoLocal(dueDateStr) {
      let includesTime = args["includesTime"] as? Bool ?? true
      let components: Set<Calendar.Component> = includesTime
        ? [.year, .month, .day, .hour, .minute]
        : [.year, .month, .day]
      reminder.dueDateComponents = Calendar.current.dateComponents(components, from: dueDate)
      reminder.alarms = includesTime ? [EKAlarm(absoluteDate: dueDate)] : nil
    } else {
      reminder.dueDateComponents = nil
      reminder.alarms = nil
    }

    do {
      try eventStore.save(reminder, commit: true)
      result(reminder.calendarItemIdentifier)
    } catch {
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func deleteReminder(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let reminderId = args["reminderId"] as? String
    else {
      result(FlutterError(code: "bad_args", message: "missing reminderId", details: nil))
      return
    }
    guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
      result(nil)
      return
    }
    do {
      try eventStore.remove(reminder, commit: true)
      result(nil)
    } catch {
      result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
    }
  }
}
