import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _kBackendMode = 'backend_mode';
  static const String _kApiBaseUrl = 'api_base_url';

  static const String modeLocal = 'local';
  static const String modeApi = 'api';

  static Future<bool> useApiMode() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_kBackendMode) ?? modeLocal) == modeApi;
  }

  static Future<void> setUseApiMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackendMode, enabled ? modeApi : modeLocal);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
return prefs.getString(_kApiBaseUrl) ?? 'http://10.0.2.2:8000/api';
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBaseUrl, url.trim());
  }
}

