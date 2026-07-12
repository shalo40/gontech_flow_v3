import '../database/database_helper.dart';
import '../models/usuario.dart';
import '../session/password_hasher.dart';

class UsuarioDao {
  final _tabla = 'usuarios';

  Future<Usuario?> autenticar(String correo, String contrasena) async {
    final db = await DatabaseHelper().database;
    final res = await db.query(
      _tabla,
      where: 'correo = ?',
      whereArgs: [correo.trim()],
      limit: 1,
    );
    if (res.isEmpty) return null;

    final usuario = Usuario.fromMap(res.first);
    if (PasswordHasher.verify(contrasena, usuario.contrasena)) {
      return usuario;
    }
    return null;
  }

  Future<int> crear(Usuario usuario) async {
    final db = await DatabaseHelper().database;
    final map = usuario.toMap();
    map['contrasena'] = PasswordHasher.hash(usuario.contrasena);
    return db.insert(_tabla, map);
  }

  /// Retorna los usuarios con rol == 'tecnico' para poblar dropdowns
  /// en modo offline (SQLite local).
  Future<List<Usuario>> listarTecnicos() async {
    final db = await DatabaseHelper().database;
    final res = await db.query(
      _tabla,
      where: 'rol = ?',
      whereArgs: ['tecnico'],
    );
    return res.map((row) => Usuario.fromMap(row)).toList();
  }
}

