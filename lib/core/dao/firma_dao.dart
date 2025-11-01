import 'dart:typed_data';
import 'dart:io';
import 'package:gontech_flow_v2/core/database/database_helper.dart';

class FirmaDao {
  final String table = 'entregas';

  /// 🧾 Actualiza la firma del cliente en la tabla `entregas`
  Future<void> actualizarFirma(
    int idEntrega,
    String firmaPath,
    Uint8List? data,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        table,
        {'firma_path': firmaPath},
        where: 'id_entrega = ?',
        whereArgs: [idEntrega],
      );

      // Guarda una copia temporal (opcional)
      final backupDir = Directory('${Directory.systemTemp.path}/firmas_backup');
      if (!backupDir.existsSync()) backupDir.createSync(recursive: true);

      final backupFile = File(
        '${backupDir.path}/firma_${idEntrega}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      if (data != null) await backupFile.writeAsBytes(data);
    } catch (e) {
      print('❌ Error al actualizar firma: $e');
      rethrow;
    }
  }

  /// 📂 Obtiene la ruta de firma desde la base de datos
  Future<String?> obtenerFirma(int idEntrega) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        table,
        columns: ['firma_path'],
        where: 'id_entrega = ?',
        whereArgs: [idEntrega],
      );
      if (result.isNotEmpty) {
        return result.first['firma_path'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener firma: $e');
      return null;
    }
  }

  /// 🗑️ Permite eliminar una firma del sistema
  Future<void> eliminarFirma(int idEntrega) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final path = await obtenerFirma(idEntrega);
      if (path != null && File(path).existsSync()) {
        File(path).deleteSync();
      }

      await db.update(
        table,
        {'firma_path': ''},
        where: 'id_entrega = ?',
        whereArgs: [idEntrega],
      );
    } catch (e) {
      print('❌ Error al eliminar firma: $e');
    }
  }
}
