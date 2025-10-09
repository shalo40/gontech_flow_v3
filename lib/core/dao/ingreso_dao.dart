import '../database/database_helper.dart';
import '../models/ingreso.dart';

class IngresoDao {
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Ingreso ingreso) async {
    final db = await dbProvider.db;
    return await db.insert('ingresos', ingreso.toMap());
  }

  Future<List<Map<String, dynamic>>> listarIngresosDetallados() async {
    final db = await dbProvider.db;
    return await db.rawQuery('''
    SELECT i.*, e.marca, e.tipo_equipo, c.nombre AS nombre_cliente
    FROM ingresos i
    LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
    LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
    ORDER BY i.fecha_ingreso DESC
  ''');
  }

  Future<int> actualizarEstado(int idIngreso, String nuevoEstado) async {
    final db = await dbProvider.db;
    return await db.update(
      'ingresos',
      {'estado_ingreso': nuevoEstado},
      where: 'id_ingreso = ?',
      whereArgs: [idIngreso],
    );
  }

  Future<int> actualizarEstadoDesdeDiagnostico(
    int idDiagnostico,
    String nuevoEstado,
  ) async {
    final db = await dbProvider.db;

    // Busca el id_ingreso relacionado al diagnóstico
    final resultado = await db.query(
      'diagnosticos',
      columns: ['id_ingreso'],
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
    );

    if (resultado.isNotEmpty) {
      final idIngreso = resultado.first['id_ingreso'] as int;
      return await actualizarEstado(idIngreso, nuevoEstado);
    } else {
      print('⚠️ No se encontró ingreso para diagnóstico $idDiagnostico');
      return 0;
    }
  }

  Future<int> actualizarEstadoDesdeReparacion(
    int idReparacion,
    String nuevoEstado,
  ) async {
    final db = await dbProvider.db;

    final resultado = await db.rawQuery(
      '''
    SELECT d.id_ingreso
    FROM reparaciones r
    LEFT JOIN diagnosticos d ON r.id_diagnostico = d.id_diagnostico
    WHERE r.id_reparacion = ?
  ''',
      [idReparacion],
    );

    if (resultado.isNotEmpty) {
      final idIngreso = resultado.first['id_ingreso'] as int;
      return await actualizarEstado(idIngreso, nuevoEstado);
    } else {
      print('⚠️ No se encontró ingreso para reparación $idReparacion');
      return 0;
    }
  }
}
