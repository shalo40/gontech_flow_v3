import '../database/database_helper.dart';
import '../models/ingreso.dart';

class IngresoDAO {
  final dbProvider = DatabaseHelper();

  /// Inserta un nuevo ingreso en la base de datos
  Future<int> insertar(Ingreso ingreso) async {
    final db = await dbProvider.database;
    return await db.insert('ingresos', ingreso.toMap());
  }

  /// Retorna todos los ingresos con detalles de equipo y cliente
  Future<List<Map<String, dynamic>>> listarIngresosDetallados() async {
    final db = await dbProvider.database;
    final res = await db.rawQuery('''
      SELECT 
        i.*,
        e.tipo_equipo,
        e.marca,
        e.modelo,
        c.nombre AS nombre_cliente
      FROM ingresos i
      LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY i.fecha_ingreso DESC
    ''');
    return res;
  }

  /// Actualiza el estado de un ingreso directamente por su ID
  Future<int> actualizarEstado(int idIngreso, String nuevoEstado) async {
    final db = await dbProvider.database;
    return await db.update(
      'ingresos',
      {'estado_ingreso': nuevoEstado},
      where: 'id_ingreso = ?',
      whereArgs: [idIngreso],
    );
  }

  /// Actualiza el estado de un ingreso a partir de un diagnóstico relacionado
  Future<int> actualizarEstadoDesdeDiagnostico(
    int idDiagnostico,
    String nuevoEstado,
  ) async {
    final db = await dbProvider.database;

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
      print(
        '⚠️ No se encontró ingreso relacionado al diagnóstico $idDiagnostico',
      );
      return 0;
    }
  }

  /// Actualiza el estado del ingreso asociado a una reparación específica
  Future<int> actualizarEstadoDesdeReparacion(
    int idReparacion,
    String nuevoEstado,
  ) async {
    final db = await dbProvider.database;

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
      print(
        '⚠️ No se encontró ingreso relacionado a la reparación $idReparacion',
      );
      return 0;
    }
  }

  /// Obtiene un ingreso específico por su ID
  Future<Ingreso?> obtenerPorId(int idIngreso) async {
    final db = await dbProvider.database;
    final res = await db.query(
      'ingresos',
      where: 'id_ingreso = ?',
      whereArgs: [idIngreso],
      limit: 1,
    );
    if (res.isNotEmpty) return Ingreso.fromMap(res.first);
    return null;
  }

  /// Elimina un ingreso (si no tiene dependencias)
  Future<int> eliminar(int idIngreso) async {
    final db = await dbProvider.database;
    return await db.delete(
      'ingresos',
      where: 'id_ingreso = ?',
      whereArgs: [idIngreso],
    );
  }
}
