// ---------- lib/core/session/auth_service.dart ----------
import '../dao/usuario_dao.dart';
import 'session_manager.dart';

class AuthService {
  final UsuarioDao _usuario_dao = UsuarioDao();
  final SessionManager _session = SessionManager();

  Future<bool> login(String correo, String contrasena) async {
    final usuario = await _usuario_dao.autenticar(correo, contrasena);
    if (usuario != null) {
      await _session.iniciar_sesion(
        correo: usuario.correo,
        nombre: usuario.nombre,
        rol: usuario.rol,
      );
      return true;
    }
    return false;
  }

  Future<void> logout() async => _session.cerrar_sesion();
}
