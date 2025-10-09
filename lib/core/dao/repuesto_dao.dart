import '../database/database_helper.dart';
import '../models/repuesto.dart';

class RepuestoDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Repuesto r) async {
    final db = await dbProvider.db;
    return await db.insert('repuestos', r.toMap());
  }

  Future<List<Repuesto>> listarPorDiagnostico(int idDiagnostico) async {
    final db = await dbProvider.db;
    final res = await db.query(
      'repuestos',
      where: 'id_diagnostico = ? AND origen = ?',
      whereArgs: [idDiagnostico, 'diagnostico'],
    );
    return res.map((e) => Repuesto.fromMap(e)).toList();
  }

  Future<List<Repuesto>> listarPorPresupuesto(int idPresupuesto) async {
    final db = await dbProvider.db;
    final res = await db.query(
      'repuestos',
      where: 'id_presupuesto = ? AND origen = ?',
      whereArgs: [idPresupuesto, 'presupuesto'],
    );
    return res.map((e) => Repuesto.fromMap(e)).toList();
  }

  Future<int> eliminar(int idRepuesto) async {
    final db = await dbProvider.db;
    return await db.delete(
      'repuestos',
      where: 'id_repuesto = ?',
      whereArgs: [idRepuesto],
    );
  }

  Future<int> actualizarEstado(int idRepuesto, String nuevoEstado) async {
    final db = await dbProvider.db;
    return await db.update(
      'repuestos',
      {'estado': nuevoEstado},
      where: 'id_repuesto = ?',
      whereArgs: [idRepuesto],
    );
  }
}
