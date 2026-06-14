import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _kBackendMode = 'backend_mode';
  static const String _kApiBaseUrl = 'api_base_url';

  static const String modeLocal = 'local';
  static const String modeApi = 'api';

  // URL por defecto para desarrollo local (Emulador Android)
  static const String defaultLocalUrl = 'http://10.0.2.2:8000/api';
  // URL de tu nuevo servidor productivo
  static const String defaultProductionUrl = 'https://api.helpdesk.gontechsolutions.cl/api';

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
    final String? savedUrl = prefs.getString(_kApiBaseUrl);
    
    // Si no hay nada guardado, decide automáticamente según el modo
    if (savedUrl == null) {
      final isApiMode = await useApiMode();
      return isApiMode ? defaultProductionUrl : defaultLocalUrl;
    }
    return savedUrl.trim();
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBaseUrl, url.trim());
  }

  // Método helper para reiniciar a valores de fábrica si algo falla
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBackendMode);
    await prefs.remove(_kApiBaseUrl);
  }
}