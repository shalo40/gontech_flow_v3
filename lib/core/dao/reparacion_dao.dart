import '../database/database_helper.dart';
import '../models/reparacion.dart';

class ReparacionDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Reparacion reparacion) async {
    final db = await dbProvider.db;
    return await db.insert('reparaciones', reparacion.toMap());
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
    final res = await db.rawQuery('''
      SELECT r.*, d.descripcion_falla, e.marca, e.tipo_equipo, i.id_ingreso
      FROM reparaciones r
      LEFT JOIN diagnosticos d ON r.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos i ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
      ORDER BY r.id_reparacion DESC
    ''');
    return res;
  }

  Future<int> actualizarEstado(int idReparacion, String nuevoEstado) async {
    final db = await dbProvider.db;
    return await db.update(
      'reparaciones',
      {'estado': nuevoEstado},
      where: 'id_reparacion = ?',
      whereArgs: [idReparacion],
    );
  }
}
