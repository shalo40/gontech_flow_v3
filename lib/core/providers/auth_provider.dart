import 'package:flutter/material.dart';
import '../dao/usuario_dao.dart';
import '../config/api_config.dart';
import '../session/session_manager.dart';
import '../services/remote_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final UsuarioDao _usuarioDao = UsuarioDao();
  final SessionManager _session = SessionManager();
  final RemoteAuthService _remoteAuth = RemoteAuthService();

  bool _isAuthenticated = false;
  String _nombre = '';
  String _correo = '';
  String _rol = '';
  bool _loading = false;

  bool get isAuthenticated => _isAuthenticated;
  String get nombre => _nombre;
  String get correo => _correo;
  String get rol => _rol;
  bool get loading => _loading;

  bool get isAdmin => _rol == 'admin';
  bool get isTecnico => _rol == 'tecnico';

  Future<void> checkSession() async {
    final autenticado = await _session.esta_autenticado();
    if (autenticado) {
      final datos = await _session.obtener_usuario();
      _isAuthenticated = true;
      _correo = datos['correo'] ?? '';
      _nombre = datos['nombre'] ?? '';
      _rol = datos['rol'] ?? '';
    }
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) async {
    _loading = true;
    notifyListeners();

    try {
      final useApi = await ApiConfig.useApiMode();
      if (useApi) {
        // Si hay error 401 o de red, esto lanza la Excepción y salta directo al catch
        final remote = await _remoteAuth.login(correo, contrasena);
        if (remote != null) {
          final user = (remote['user'] as Map<String, dynamic>? ?? {});
          await _session.iniciar_sesion(
            correo: (user['email'] ?? correo).toString(),
            nombre: (user['name'] ?? '').toString(),
            rol: (user['role'] ?? 'tecnico').toString(),
            apiToken: (remote['token'] ?? '').toString(),
          );
          _isAuthenticated = true;
          _correo = (user['email'] ?? correo).toString();
          _nombre = (user['name'] ?? '').toString();
          _rol = (user['role'] ?? 'tecnico').toString();
          notifyListeners();
          return true;
        }
        return false;
      }

      final usuario = await _usuarioDao.autenticar(correo, contrasena);
      if (usuario != null) {
        await _session.iniciar_sesion(
          correo: usuario.correo,
          nombre: usuario.nombre,
          rol: usuario.rol,
        );
        _isAuthenticated = true;
        _correo = usuario.correo;
        _nombre = usuario.nombre;
        _rol = usuario.rol;
        notifyListeners();
        return true;
      }
      return false;
      
    } catch (e) {
      // Atrapamos el error y le quitamos la palabra "Exception:" para que el 
      // texto llegue totalmente limpio a la vista del usuario.
      throw Exception(e.toString().replaceAll('Exception: ', ''));
      
    } finally {
      // Ya sea que haya éxito o error, apagamos el loader
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _session.cerrar_sesion();
    _isAuthenticated = false;
    _nombre = '';
    _correo = '';
    _rol = '';
    notifyListeners();
  }
}