// ---------- lib/core/session/session_manager.dart ----------
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _k_sesion_iniciada = 'sesion_iniciada';
  static const _k_usuario_correo = 'usuario_correo';
  static const _k_usuario_nombre = 'usuario_nombre';
  static const _k_usuario_rol = 'usuario_rol';

  Future<void> iniciar_sesion({
    required String correo,
    required String nombre,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_k_sesion_iniciada, true);
    await prefs.setString(_k_usuario_correo, correo);
    await prefs.setString(_k_usuario_nombre, nombre);
    await prefs.setString(_k_usuario_rol, rol);
  }

  Future<bool> esta_autenticado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_k_sesion_iniciada) ?? false;
  }

  Future<Map<String, String?>> obtener_usuario() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'correo': prefs.getString(_k_usuario_correo),
      'nombre': prefs.getString(_k_usuario_nombre),
      'rol': prefs.getString(_k_usuario_rol),
    };
  }

  Future<void> cerrar_sesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_k_sesion_iniciada);
    await prefs.remove(_k_usuario_correo);
    await prefs.remove(_k_usuario_nombre);
    await prefs.remove(_k_usuario_rol);
  }
}
