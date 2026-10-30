import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// App settings. Right now that is only the key for the AI image-to-3D service.
class SettingsService extends ChangeNotifier {
  String _meshyApiKey = '';

  String get meshyApiKey => _meshyApiKey;
  bool get hasMeshyKey => _meshyApiKey.trim().isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _meshyApiKey = prefs.getString(AppConstants.prefsMeshyApiKey) ?? '';
    notifyListeners();
  }

  Future<void> saveMeshyKey(String key) async {
    _meshyApiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsMeshyApiKey, _meshyApiKey);
    notifyListeners();
  }
}
