import '../database/database_helper.dart';
import '../models/presupuesto.dart';

class PresupuestoDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Presupuesto p) async {
    final db = await dbProvider.db;
    return await db.insert('presupuestos', p.toMap());
  }

  Future<List<Presupuesto>> listarTodos() async {
    final db = await dbProvider.db;
    final res = await db.query('presupuestos');
    return res.map((e) => Presupuesto.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
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
    final db = await dbProvider.db;
    return await db.update(
      'presupuestos',
      {'estado': nuevoEstado},
      where: 'id_presupuesto = ?',
      whereArgs: [idPresupuesto],
    );
  }

  Future<void> eliminar(int idPresupuesto) async {
    final db = await dbProvider.db;
    await db.delete(
      'presupuestos',
      where: 'id_presupuesto = ?',
      whereArgs: [idPresupuesto],
    );
  }
}
