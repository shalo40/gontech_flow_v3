// ignore_for_file: constant_identifier_names
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _k_sesion_iniciada = 'sesion_iniciada';
  static const _k_usuario_correo  = 'usuario_correo';
  static const _k_usuario_nombre  = 'usuario_nombre';
  static const _k_usuario_rol     = 'usuario_rol';
  static const _k_usuario_id      = 'usuario_id';   // ← ID numérico del técnico
  static const _k_api_token       = 'api_token';

  Future<void> iniciar_sesion({
    required String correo,
    required String nombre,
    required String rol,
    String?  apiToken,
    int?     idUsuario,   // ← nuevo parámetro opcional
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k_sesion_iniciada, true);
    await prefs.setString(_k_usuario_correo, correo);
    await prefs.setString(_k_usuario_nombre, nombre);
    await prefs.setString(_k_usuario_rol, rol);
    if (idUsuario != null) {
      await prefs.setInt(_k_usuario_id, idUsuario);
    }
    if (apiToken != null && apiToken.isNotEmpty) {
      await prefs.setString(_k_api_token, apiToken);
    }
  }

  Future<bool> esta_autenticado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_k_sesion_iniciada) ?? false;
  }

  Future<Map<String, dynamic>> obtener_usuario() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'correo':      prefs.getString(_k_usuario_correo),
      'nombre':      prefs.getString(_k_usuario_nombre),
      'rol':         prefs.getString(_k_usuario_rol),
      'id_usuario':  prefs.getInt(_k_usuario_id),    // ← expone el ID numérico
    };
  }

  Future<void> cerrar_sesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_k_sesion_iniciada);
    await prefs.remove(_k_usuario_correo);
    await prefs.remove(_k_usuario_nombre);
    await prefs.remove(_k_usuario_rol);
    await prefs.remove(_k_usuario_id);   // ← limpia también el id
    await prefs.remove(_k_api_token);
  }

  Future<String?> obtener_token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_k_api_token);
  }
}
