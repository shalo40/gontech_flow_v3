import '../database/database_helper.dart';
import '../models/entrega.dart';

class EntregaDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Entrega entrega) async {
    final db = await dbProvider.db;
    return await db.insert('entregas', entrega.toMap());
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
    final res = await db.rawQuery('''
      SELECT e.*, r.descripcion_trabajo, d.descripcion_falla, c.nombre AS cliente,
             eq.marca, eq.tipo_equipo
      FROM entregas e
      LEFT JOIN reparaciones r ON e.id_reparacion = r.id_reparacion
      LEFT JOIN diagnosticos d ON r.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos i ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos eq ON i.id_equipo = eq.id_equipo
      LEFT JOIN clientes c ON i.id_cliente = c.id_cliente
      ORDER BY e.id_entrega DESC
    ''');
    return res;
  }
}
