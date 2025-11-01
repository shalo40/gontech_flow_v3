import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/entrega.dart';

class EntregaDao {
  final _tabla = 'entregas';

  /// 🟢 Inserta una nueva entrega
  Future<int> insertar(Entrega entrega) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      _tabla,
      entrega.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📋 Lista todas las entregas con detalles de la reparación
  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT 
        e.id_entrega,
        e.id_reparacion,
        e.nombre_receptor,
        e.rut_receptor,
        e.observaciones,
        e.firma_path,
        e.fecha_entrega,
        e.estado,
        r.descripcion AS descripcion_reparacion
      FROM entregas e
      LEFT JOIN reparaciones r ON e.id_reparacion = r.id_reparacion
      ORDER BY e.id_entrega DESC;
    ''');
  }

  /// 🧾 Obtiene una entrega específica (por ID)
  Future<Map<String, dynamic>?> obtenerPorId(int idEntrega) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        e.*,
        r.descripcion AS descripcion_reparacion
      FROM entregas e
      LEFT JOIN reparaciones r ON e.id_reparacion = r.id_reparacion
      WHERE e.id_entrega = ?
      LIMIT 1;
      ''',
      [idEntrega],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// ✍️ Actualiza la ruta de la firma del cliente
  Future<void> actualizarFirma(int idEntrega, String firmaPath) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tabla,
      {'firma_path': firmaPath},
      where: 'id_entrega = ?',
      whereArgs: [idEntrega],
    );
  }

  /// 🔄 Cambia el estado de una entrega
  Future<void> actualizarEstado(int idEntrega, String nuevoEstado) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tabla,
      {'estado': nuevoEstado},
      where: 'id_entrega = ?',
      whereArgs: [idEntrega],
    );
  }

  /// 🧩 Actualiza todos los campos de una entrega
  Future<int> actualizar(Entrega entrega) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      _tabla,
      entrega.toMap(),
      where: 'id_entrega = ?',
      whereArgs: [entrega.id_entrega],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 🗑️ Elimina una entrega por su ID
  Future<int> eliminar(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(_tabla, where: 'id_entrega = ?', whereArgs: [id]);
  }
}
