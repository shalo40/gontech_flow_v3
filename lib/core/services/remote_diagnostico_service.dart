// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteDiagnosticoService {
  
  // Obtener todos los diagnósticos (Laravel ya incluirá ingreso, equipo, cliente y técnico)
  Future<List<dynamic>> obtenerDiagnosticos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/diagnosticos');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteDiagnosticoService.obtenerDiagnosticos: $e');
      throw Exception('Error al conectar con el servidor para obtener los diagnósticos.');
    }
  }

  // Registrar un diagnóstico nuevo
  Future<Map<String, dynamic>?> crearDiagnostico(Map<String, dynamic> diagnosticoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      // Bug 2: sanitiza cualquier campo de fecha antes de enviar al servidor
      final payload = _sanitizarFechas(diagnosticoData);
      final response = await dio.post(
        '/diagnosticos',
        data: payload,
      );
      
      if (response.statusCode == 201 && response.data['data'] != null) {
        return response.data['data']; 
      }
      return null;
      
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('message')) {
            throw Exception(responseData['message']);
          }
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first[0];
            throw Exception(firstError);
          }
        }
      }
      throw Exception('Error inesperado al registrar el diagnóstico.');
    }
  }

  /// Recorre el mapa del payload y convierte cualquier valor con formato ISO 8601
  /// (detectado por el patrón 'T' + zona horaria) al formato `yyyy-MM-dd HH:mm:ss`
  /// que exige MySQL DATETIME. Opera sin depender del paquete intl.
  Map<String, dynamic> _sanitizarFechas(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String && _esIso8601(value)) {
        return MapEntry(key, _toMysqlDatetime(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Detecta si un String parece una fecha ISO 8601 con zona horaria.
  bool _esIso8601(String s) {
    // Coincide con: 2026-07-12T01:06:47+00:00 o 2026-07-12T01:06:47.000Z
    return RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(s);
  }

  /// Convierte un String ISO 8601 a `yyyy-MM-dd HH:mm:ss`.
  String _toMysqlDatetime(String iso) {
    try {
      final dt = DateTime.parse(iso).toUtc();
      final y  = dt.year.toString().padLeft(4, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final d  = dt.day.toString().padLeft(2, '0');
      final h  = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      final s  = dt.second.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi:$s';
    } catch (_) {
      return iso; // si falla el parse, devuelve el original sin explotar
    }
  }

  // Actualizar un diagnóstico existente
  Future<Map<String, dynamic>?> actualizarDiagnostico(int id, Map<String, dynamic> diagnosticoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/diagnosticos/$id',
        data: diagnosticoData,
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
      
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          throw Exception(responseData['message']);
        }
      }
      throw Exception('Error al actualizar el diagnóstico.');
    }
  }

  // Eliminar un diagnóstico
  Future<bool> eliminarDiagnostico(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/diagnosticos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el diagnóstico del servidor.');
    }
  }
}