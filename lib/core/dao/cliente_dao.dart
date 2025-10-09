import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClienteDao {
  final _tabla = 'clientes';

  Future<void> crear_tabla(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tabla (
        id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        direccion TEXT,
        notas TEXT
      );
    ''');
  }

  Future<int> insertar(Cliente cliente) async {
    final db = await DatabaseHelper().db;
    return db.insert(_tabla, cliente.to_map());
  }

  Future<List<Cliente>> listar() async {
    final db = await DatabaseHelper().db;
    final res = await db.query(_tabla, orderBy: 'id_cliente DESC');
    return res.map((e) => Cliente.from_map(e)).toList();
  }

  Future<int> eliminar(int id) async {
    final db = await DatabaseHelper().db;
    return db.delete(_tabla, where: 'id_cliente = ?', whereArgs: [id]);
  }

  Future<int> actualizar(Cliente cliente) async {
    final db = await DatabaseHelper().db;
    return db.update(
      _tabla,
      cliente.to_map(),
      where: 'id_cliente = ?',
      whereArgs: [cliente.id_cliente],
    );
  }
}
