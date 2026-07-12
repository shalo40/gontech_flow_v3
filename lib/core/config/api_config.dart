class ApiConfig {
  static const String defaultLocalUrl = 'http://10.0.2.2:8000/api';
  static const String defaultProductionUrl = 'https://api.helpdesk.gontechsolutions.cl/api';

  // 🔥 LA REGLA DE ORO 🔥
  // Mantenemos 'true' a la fuerza. Esto mantiene SQLite apagado y obliga a usar tu Laravel en cPanel.
  static Future<bool> useApiMode() async {
    return true; 
  }

  // 📡 EL ENRUTAMIENTO (MODO PRODUCCIÓN)
  // Forzamos la conexión a la nube (cPanel)
  static Future<String> getBaseUrl() async {
    return defaultProductionUrl; // 👈 CAMBIO MAESTRO AQUÍ
  }

  // 🛡️ MÉTODOS DE RELLENO (Defensivos)
  // Los dejamos vacíos para evitar que algún estado residual de la app intente cambiar la ruta.
  static Future<void> setUseApiMode(bool enabled) async {}
  static Future<void> setBaseUrl(String url) async {}
  static Future<void> resetToDefaults() async {}
}