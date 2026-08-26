import 'package:flutter/foundation.dart';

import '../models/summary_level.dart';
import '../services/settings_service.dart';

class SettingsStore extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  SummaryLevel summaryLevel = SummaryLevel.preserve;
  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    summaryLevel = await _service.getSummaryLevel();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSummaryLevel(SummaryLevel value) async {
    summaryLevel = value;
    await _service.setSummaryLevel(value);
    notifyListeners();
  }
}
