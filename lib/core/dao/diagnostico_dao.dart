import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../database/database_helper.dart';
import '../models/diagnostico.dart';

class DiagnosticoDao {
  final dbProvider = DatabaseHelper();

  // ==========================
  // INSERTAR
  // ==========================
  Future<int> insertar(Diagnostico d) async {
    final db = await dbProvider.db;
    return await db.insert(
      'diagnosticos',
      d.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================
  // LISTAR POR INGRESO
  // ==========================
  Future<List<Diagnostico>> listarPorIngreso(int idIngreso) async {
    final db = await dbProvider.db;
    final res = await db.query(
      'diagnosticos',
      where: 'id_ingreso = ?',
      whereArgs: [idIngreso],
      orderBy: 'id_diagnostico DESC',
    );
    return res.map((e) => Diagnostico.fromMap(e)).toList();
  }

  // ==========================
  // LISTAR TODOS
  // ==========================
  Future<List<Diagnostico>> listarTodos() async {
    final db = await dbProvider.db;
    final res = await db.query('diagnosticos', orderBy: 'id_diagnostico DESC');
    return res.map((e) => Diagnostico.fromMap(e)).toList();
  }

  // ==========================
  // LISTADO DETALLADO (con equipo y fecha)
  // ==========================
  Future<List<Map<String, dynamic>>> listarDetallado() async {
    final db = await dbProvider.db;
    final res = await db.rawQuery('''
      SELECT 
        d.id_diagnostico,
        d.descripcion_falla,
        d.pruebas_realizadas,
        d.conclusiones,
        d.estado,
        d.creado_en,
        e.marca,
        e.tipo_equipo,
        i.fecha_ingreso
      FROM diagnosticos d
      LEFT JOIN ingresos i ON d.id_ingreso = i.id_ingreso
      LEFT JOIN equipos e ON i.id_equipo = e.id_equipo
      ORDER BY d.id_diagnostico DESC;
    ''');
    return res;
  }

  // ==========================
  // ACTUALIZAR ESTADO
  // ==========================
  Future<int> actualizarEstado(int idDiagnostico, String nuevoEstado) async {
    final db = await dbProvider.db;
    return await db.update(
      'diagnosticos',
      {'estado': nuevoEstado},
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
    );
  }

  // ==========================
  // ELIMINAR (por id)
  // ==========================
  Future<int> eliminar(int idDiagnostico) async {
    final db = await dbProvider.db;
    return await db.delete(
      'diagnosticos',
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
    );
  }
}
