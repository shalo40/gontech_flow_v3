import '../database/database_helper.dart';
import '../models/equipo.dart';

class EquipoDao {
  final tabla = 'equipos';
  final dbProvider = DatabaseHelper();

  /// Inserta un nuevo equipo en la base de datos
  Future<int> insertar(Equipo equipo) async {
    final db = await dbProvider.database;
    return await db.insert(tabla, equipo.toMap());
  }

  /// Retorna todos los equipos registrados
  Future<List<Equipo>> listar() async {
    final db = await dbProvider.database;
    final res = await db.query(tabla, orderBy: 'id_equipo DESC');
    return res.map((e) => Equipo.fromMap(e)).toList();
  }

  /// Retorna equipos pertenecientes a un cliente específico
  Future<List<Equipo>> listarPorCliente(int idCliente) async {
    final db = await dbProvider.database;
    final res = await db.query(
      tabla,
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
      orderBy: 'id_equipo DESC',
    );
    return res.map((e) => Equipo.fromMap(e)).toList();
  }

  /// Retorna un detalle de equipos junto al nombre del cliente
  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.database;
    final res = await db.rawQuery('''
      SELECT e.*, c.nombre AS nombre_cliente
      FROM equipos e
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY e.id_equipo DESC
    ''');
    return res;
  }

  /// Obtiene un equipo por su ID
  Future<Equipo?> obtenerPorId(int idEquipo) async {
    final db = await dbProvider.database;
    final res = await db.query(
      tabla,
      where: 'id_equipo = ?',
      whereArgs: [idEquipo],
      limit: 1,
    );
    if (res.isNotEmpty) return Equipo.fromMap(res.first);
    return null;
  }

  /// Actualiza un equipo existente
  Future<int> actualizar(Equipo equipo) async {
    final db = await dbProvider.database;
    return await db.update(
      tabla,
      equipo.toMap(),
      where: 'id_equipo = ?',
      whereArgs: [equipo.id_equipo],
    );
  }

  /// Elimina un equipo por su ID
  Future<int> eliminar(int idEquipo) async {
    final db = await dbProvider.database;
    return await db.delete(
      tabla,
      where: 'id_equipo = ?',
      whereArgs: [idEquipo],
    );
  }
}
