import 'package:flutter/material.dart';
import '../dao/usuario_dao.dart';
import '../session/session_manager.dart';

class AuthProvider extends ChangeNotifier {
  final UsuarioDao _usuarioDao = UsuarioDao();
  final SessionManager _session = SessionManager();

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
    } finally {
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
