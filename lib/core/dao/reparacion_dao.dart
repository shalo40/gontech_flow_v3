import '../database/database_helper.dart';
import '../models/reparacion.dart';

class ReparacionDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Reparacion r) async {
    final db = await dbProvider.db;
    return await db.insert('reparaciones', r.toMap());
  }

  Future<List<Reparacion>> listarPorDiagnostico(int idDiagnostico) async {
    final db = await dbProvider.db;
    final res = await db.query(
      'reparaciones',
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
      orderBy: 'id_reparacion DESC',
    );
    return res.map((e) => Reparacion.fromMap(e)).toList();
  }

  Future<void> actualizarEstado(int idReparacion, String nuevoEstado) async {
    final db = await dbProvider.db;
    await db.update(
      'reparaciones',
      {'estado': nuevoEstado, 'fecha_fin': DateTime.now().toIso8601String()},
      where: 'id_reparacion = ?',
      whereArgs: [idReparacion],
    );
  }

  Future<void> eliminar(int idReparacion) async {
    final db = await dbProvider.db;
    await db.delete(
      'reparaciones',
      where: 'id_reparacion = ?',
      whereArgs: [idReparacion],
    );
  }

  // 👇 NUEVO MÉTODO
  Future<void> insertarDesdePresupuesto(
    int idPresupuesto,
    int idDiagnostico,
  ) async {
    final db = await dbProvider.db;
    await db.insert('reparaciones', {
      'id_presupuesto': idPresupuesto,
      'id_diagnostico': idDiagnostico,
      'descripcion':
          'Reparación generada automáticamente al autorizar el presupuesto.',
      'fecha_inicio': DateTime.now().toIso8601String(),
      'estado': 'en_proceso',
    });
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
    return await db.rawQuery('''
      SELECT 
        r.id_reparacion,
        r.descripcion,
        r.estado,
        r.fecha_inicio,
        r.fecha_fin,
        r.notas,
        d.descripcion_falla,
        d.conclusiones,
        e.marca, e.modelo,
        c.nombre AS cliente
      FROM reparaciones r
      LEFT JOIN diagnosticos d ON r.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos i     ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos e      ON i.id_equipo = e.id_equipo
      LEFT JOIN clientes c     ON e.id_cliente = c.id_cliente
      ORDER BY r.id_reparacion DESC;
    ''');
  }
}
