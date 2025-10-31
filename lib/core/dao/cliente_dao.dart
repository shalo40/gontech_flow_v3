import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClienteDao {
  static const _tabla = 'clientes';
  final dbProvider = DatabaseHelper();

  /// 🏗️ Crea o migra la tabla clientes.
  Future<void> crearTabla(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tabla (
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

    // 🧩 Verifica columnas y aplica migraciones automáticas si faltan
    final columnas = await db.rawQuery("PRAGMA table_info($_tabla)");
    final campos = columnas.map((c) => c['name']).toList();

    final columnasFaltantes = <String, String>{
      'rut': 'TEXT DEFAULT ""',
      'telefono': 'TEXT DEFAULT ""',
      'correo': 'TEXT DEFAULT ""',
      'direccion': 'TEXT DEFAULT ""',
      'notas': 'TEXT DEFAULT ""',
      'foto_path': 'TEXT DEFAULT ""',
    };

    for (final entry in columnasFaltantes.entries) {
      if (!campos.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE $_tabla ADD COLUMN ${entry.key} ${entry.value};',
        );
        debugPrint('✅ Columna agregada: ${entry.key}');
      }
    }
  }

  /// ➕ Inserta un nuevo cliente
  Future<int> insertar(Cliente cliente) async {
    final db = await dbProvider.db;
    return await db.insert(_tabla, cliente.toMap());
  }

  /// 📋 Lista todos los clientes
  Future<List<Cliente>> listar() async {
    final db = await dbProvider.db;
    final res = await db.query(_tabla, orderBy: 'nombre ASC');
    return res.map((e) => Cliente.fromMap(e)).toList();
  }

  /// 🔍 Busca cliente por ID
  Future<Cliente?> obtenerPorId(int id) async {
    final db = await dbProvider.db;
    final res = await db.query(
      _tabla,
      where: 'id_cliente = ?',
      whereArgs: [id],
    );
    return res.isNotEmpty ? Cliente.fromMap(res.first) : null;
  }

  /// 🧹 Elimina un cliente
  Future<int> eliminar(int id) async {
    final db = await dbProvider.db;
    return await db.delete(_tabla, where: 'id_cliente = ?', whereArgs: [id]);
  }

  /// ✏️ Actualiza un cliente existente
  Future<int> actualizar(Cliente cliente) async {
    final db = await dbProvider.db;
    return await db.update(
      _tabla,
      cliente.toMap(),
      where: 'id_cliente = ?',
      whereArgs: [cliente.idCliente],
    );
  }

  /// 🧠 Cuenta cuántos clientes hay
  Future<int> contar() async {
    final db = await dbProvider.db;
    final res = await db.rawQuery('SELECT COUNT(*) AS total FROM $_tabla');
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
