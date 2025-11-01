import '../database/database_helper.dart';
import '../models/informe.dart';

class InformeDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Informe i) async {
    final db = await dbProvider.database;
    return await db.insert('informes', i.toMap());
  }

  Future<List<Informe>> listarPorDiagnostico(int idDiagnostico) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'informes',
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
      orderBy: 'id_informe DESC',
    );
    return res.map((e) => Informe.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.database;
    return await db.rawQuery('''
      SELECT 
        i.id_informe,
        i.descripcion_general,
        i.conclusiones,
        i.recomendaciones,
        i.creado_en,
        d.descripcion_falla,
        e.marca, e.modelo,
        c.nombre AS cliente
      FROM informes i
      LEFT JOIN diagnosticos d ON i.id_diagnostico = d.id_diagnostico
      LEFT JOIN ingresos ing ON d.id_ingreso = ing.id_ingreso
      LEFT JOIN equipos e ON ing.id_equipo = e.id_equipo
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY i.id_informe DESC;
    ''');
  }

  Future<void> eliminar(int idInforme) async {
    final db = await dbProvider.database;
    await db.delete(
      'informes',
      where: 'id_informe = ?',
      whereArgs: [idInforme],
    );
  }
}
