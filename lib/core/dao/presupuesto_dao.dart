import '../database/database_helper.dart';
import '../models/presupuesto.dart';
import 'reparacion_dao.dart'; // 👈 nuevo

class PresupuestoDao {
  final dbProvider = DatabaseHelper();
  final _reparacionDao = ReparacionDao(); // 👈 nuevo

  Future<int> insertar(Presupuesto p) async {
    final db = await dbProvider.database;
    return await db.insert('presupuestos', p.toMap());
  }

  Future<List<Presupuesto>> listarTodos() async {
    final db = await dbProvider.database;
    final res = await db.query('presupuestos');
    return res.map((e) => Presupuesto.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.database;
    final res = await db.rawQuery('''
      SELECT p.*, d.descripcion_falla, e.marca, e.tipo_equipo, c.nombre AS cliente
      FROM presupuestos p
      LEFT JOIN diagnosticos d ON p.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos i ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY p.id_presupuesto DESC
    ''');
    return res;
  }

  Future<int> actualizarEstado(int idPresupuesto, String nuevoEstado) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'presupuestos',
      where: 'id_presupuesto = ?',
      whereArgs: [idPresupuesto],
      limit: 1,
    );

    if (res.isEmpty) return 0;
    final presupuesto = Presupuesto.fromMap(res.first);

    // Actualiza el estado normal
    final rows = await db.update(
      'presupuestos',
      {'estado': nuevoEstado},
      where: 'id_presupuesto = ?',
      whereArgs: [idPresupuesto],
    );

    // 🚀 Si fue autorizado, crear reparación automáticamente
    if (nuevoEstado == 'autorizado') {
      await _reparacionDao.insertarDesdePresupuesto(
        idPresupuesto,
        presupuesto.idDiagnostico,
      );
    }

    return rows;
  }

  Future<void> eliminar(int idPresupuesto) async {
    final db = await dbProvider.database;
    await db.delete(
      'presupuestos',
      where: 'id_presupuesto = ?',
      whereArgs: [idPresupuesto],
    );
  }
}
