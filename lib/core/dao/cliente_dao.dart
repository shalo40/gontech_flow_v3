import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClienteDao {
  final _tabla = 'clientes';

  Future<void> crear_tabla(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS clientes (
  id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  rut TEXT,
  telefono TEXT,
  correo TEXT,
  direccion TEXT,
  notas TEXT,
  foto_path TEXT
);
''');

    // 🧠 Verificación y migración si la BD ya existía sin foto_path
    final columnas = await db.rawQuery("PRAGMA table_info(clientes)");
    final tieneFoto = columnas.any((c) => c['name'] == 'foto_path');
    if (!tieneFoto) {
      await db.execute(
        "ALTER TABLE clientes ADD COLUMN foto_path TEXT DEFAULT '';",
      );
      debugPrint('✅ Columna foto_path agregada correctamente.');
    }
  }

  Future<int> insertar(Cliente cliente) async {
    final db = await DatabaseHelper().db;
    return db.insert(_tabla, cliente.to_map());
  }

  Future<List<Cliente>> listar() async {
    final db = await DatabaseHelper().db;
    final res = await db.query(_tabla, orderBy: 'nombre ASC');
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
