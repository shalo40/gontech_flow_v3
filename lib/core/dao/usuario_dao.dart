// ---------- lib/core/dao/usuario_dao.dart ----------
import '../database/database_helper.dart';
import '../models/usuario.dart';

class UsuarioDao {
  final _tabla = 'usuarios';

  Future<Usuario?> autenticar(String correo, String contrasena) async {
    final db = await DatabaseHelper().database;
    final res = await db.query(
      _tabla,
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [correo.trim(), contrasena],
      limit: 1,
    );
    if (res.isNotEmpty) return Usuario.from_map(res.first);
    return null;
  }

  Future<int> crear(Usuario usuario) async {
    final db = await DatabaseHelper().database;
    return db.insert(_tabla, usuario.to_map());
  }
}
