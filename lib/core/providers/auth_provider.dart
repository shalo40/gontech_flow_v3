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
  String _nombre  = '';
  String _correo  = '';
  String _rol     = '';
  int?   _idUsuario;          // ← ID numérico del técnico en sesión
  bool _loading = false;

  bool   get isAuthenticated => _isAuthenticated;
  String get nombre          => _nombre;
  String get correo          => _correo;
  String get rol             => _rol;
  int?   get idUsuario       => _idUsuario;   // ← getter público
  bool   get loading         => _loading;

  bool get isAdmin => _rol == 'admin';
  bool get isTecnico => _rol == 'tecnico';

  Future<void> checkSession() async {
    final autenticado = await _session.esta_autenticado();
    if (autenticado) {
      final datos = await _session.obtener_usuario();
      _isAuthenticated = true;
      _correo     = datos['correo']     as String? ?? '';
      _nombre     = datos['nombre']     as String? ?? '';
      _rol        = datos['rol']        as String? ?? '';
      _idUsuario  = datos['id_usuario'] as int?;     // ← restaura el ID
    }
    notifyListeners();
  }

  Future<bool> login(String correo, String contrasena) async {
    _loading = true;
    notifyListeners();

    try {
      final useApi = await ApiConfig.useApiMode(); // ← era ApiConfig.isProduction (ya no existe)
      if (useApi) {
        // Si hay error 401 o de red, esto lanza la Excepción y salta directo al catch
        final remote = await _remoteAuth.login(correo, contrasena);
        if (remote != null) {
          // UsuarioResource devuelve: id_usuario, nombre, correo, rol, creado_en, actualizado_en
          final user = (remote['user'] as Map<String, dynamic>? ?? {});
          final idNum = (user['id_usuario'] ?? user['id']) as int?;
          await _session.iniciar_sesion(
            correo:     (user['correo'] ?? correo).toString(),
            nombre:     (user['nombre'] ?? '').toString(),
            rol:        (user['rol']    ?? 'tecnico').toString(),
            apiToken:   (remote['token'] ?? '').toString(),
            idUsuario:  idNum,                          // ← persiste el ID
          );
          _isAuthenticated = true;
          _correo     = (user['correo'] ?? correo).toString();
          _nombre     = (user['nombre'] ?? '').toString();
          _rol        = (user['rol']    ?? 'tecnico').toString();
          _idUsuario  = idNum;                          // ← carga en memoria
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
    _nombre     = '';
    _correo     = '';
    _rol        = '';
    _idUsuario  = null;
    notifyListeners();
  }
}