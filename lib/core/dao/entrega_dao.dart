import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/entrega.dart';

class EntregaDao {
  final _tabla = 'entregas';

  Future<int> insertar(Entrega entrega) async {
    final db = await DatabaseHelper().db;
    return db.insert(_tabla, entrega.toMap());
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await DatabaseHelper().db;
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

  Future<int> eliminar(int id) async {
    final db = await DatabaseHelper().db;
    return db.delete(_tabla, where: 'id_entrega = ?', whereArgs: [id]);
  }

  Future<int> actualizar(Entrega entrega) async {
    final db = await DatabaseHelper().db;
    return db.update(
      _tabla,
      entrega.toMap(),
      where: 'id_entrega = ?',
      whereArgs: [entrega.id_entrega],
    );
  }
}
