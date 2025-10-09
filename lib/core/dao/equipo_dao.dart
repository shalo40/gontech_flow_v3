import '../database/database_helper.dart';
import '../models/equipo.dart';

class EquipoDao {
  final tabla = 'equipos';
  final dbProvider = DatabaseHelper();

  Future<int> insertar(Equipo eq) async {
    final db = await DatabaseHelper().db;
    return await db.insert(tabla, eq.toMap());
  }

  Future<List<Equipo>> listarPorCliente(int idCliente) async {
    final db = await DatabaseHelper().db;
    final res = await db.query(
      tabla,
      where: 'id_cliente = ?',
      whereArgs: [idCliente],
    );
    return res.map((e) => Equipo.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
    final res = await db.rawQuery('''
      SELECT e.*, c.nombre AS nombre_cliente
      FROM equipos e
      LEFT JOIN clientes c ON e.id_cliente = c.id_cliente
      ORDER BY e.id_equipo DESC
    ''');
    return res;
  }
}
