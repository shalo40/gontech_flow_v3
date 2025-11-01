import '../database/database_helper.dart';
import '../models/repuesto.dart';

class RepuestoDao {
  final dbProvider = DatabaseHelper();

  // 🔹 Insertar nuevo repuesto
  Future<int> insertar(Repuesto r) async {
    final db = await dbProvider.database;
    return await db.insert('repuestos', r.toMap());
  }

  // 🔹 Listar todos los repuestos (básico)
  Future<List<Repuesto>> listarTodos() async {
    final db = await dbProvider.database;
    final res = await db.query('repuestos');
    return res.map((e) => Repuesto.fromMap(e)).toList();
  }

  // 🔹 Listado detallado con joins a diagnóstico, reparación, etc.
  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.database;
    final res = await db.rawQuery('''
      SELECT 
        r.id_repuesto,
        r.nombre,
        r.cantidad,
        r.costo_unitario,
        r.proveedor,
        r.estado,
        r.origen,
        r.fecha_registro,
        d.descripcion_falla,
        e.marca,
        e.tipo_equipo,
        c.nombre AS cliente
      FROM repuestos r
      LEFT JOIN diagnosticos d ON r.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos i ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY r.id_repuesto DESC;
    ''');
    return res;
  }

  // 🔹 Listar repuestos por diagnóstico
  Future<List<Map<String, dynamic>>> listarPorDiagnostico(
    int idDiagnostico,
  ) async {
    final db = await dbProvider.database;
    return await db.query(
      'repuestos',
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
      orderBy: 'id_repuesto DESC',
    );
  }

  // 🔹 Actualizar estado
  Future<void> actualizarEstado(int idRepuesto, String nuevoEstado) async {
    final db = await dbProvider.database;
    await db.update(
      'repuestos',
      {'estado': nuevoEstado},
      where: 'id_repuesto = ?',
      whereArgs: [idRepuesto],
    );
  }

  // 🔹 Eliminar
  Future<void> eliminar(int idRepuesto) async {
    final db = await dbProvider.database;
    await db.delete(
      'repuestos',
      where: 'id_repuesto = ?',
      whereArgs: [idRepuesto],
    );
  }
}
