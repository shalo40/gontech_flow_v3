// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteIngresoService {
  
  // Obtener todos los ingresos (incluyendo equipo, cliente y diagnósticos asociados)
  Future<List<dynamic>> obtenerIngresos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/ingresos');
      
      if (response.statusCode == 200) {
        if (response.data is List) {
          return response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic> && response.data['data'] != null) {
          return response.data['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error en RemoteIngresoService.obtenerIngresos: $e');
      throw Exception('Error al conectar con el servidor para obtener ingresos.');
    }
  }

  // Registrar un ingreso nuevo
  Future<Map<String, dynamic>?> crearIngreso(Map<String, dynamic> ingresoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      // Sanitiza cualquier fecha ISO8601 residual antes de enviar
      final payload = _sanitizarFechas(ingresoData);

      print('📤 [RemoteIngresoService] POST /ingresos payload=$payload');

      final response = await dio.post('/ingresos', data: payload);

      print('📥 [RemoteIngresoService] status=${response.statusCode} body=${response.data}');

      // Bug 3: aceptar 200 Y 201 — algunos servidores Laravel retornan 200 para POST
      final statusOk = response.statusCode == 200 || response.statusCode == 201;
      if (statusOk) {
        // Intenta extraer el objeto creado de la respuesta
        try {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            return data['data'] as Map<String, dynamic>? ?? data;
          }
        } catch (_) {
          // Si no podemos parsear la respuesta pero el status fue exitoso,
          // devolvemos un mapa vacío como señal de éxito al provider
          return {};
        }
        return {};
      }
      return null;
      
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('❌ [RemoteIngresoService] DioException status=${e.response?.statusCode}');
        print('❌ [RemoteIngresoService] body=${e.response?.data}');
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
      throw Exception('Error inesperado al registrar el ingreso.');
    }
  }

  // Actualizar un ingreso (ej: cambio de estado)
  Future<Map<String, dynamic>?> actualizarIngreso(int id, Map<String, dynamic> ingresoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put('/ingresos/$id', data: ingresoData);
      
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data['data'] != null) {
          return response.data['data']; 
        }
        return response.data is Map<String, dynamic> ? response.data : {};
      }
      return null;
      
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          throw Exception(responseData['message']);
        }
      }
      throw Exception('Error al actualizar el ingreso.');
    }
  }

  // Eliminar un ingreso
  Future<bool> eliminarIngreso(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/ingresos/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error al eliminar el ingreso.');
    }
  }

  // ── Helpers de sanitización ──────────────────────────────────────────────────

  /// Convierte cualquier valor ISO 8601 en el mapa a 'yyyy-MM-dd HH:mm:ss'.
  Map<String, dynamic> _sanitizarFechas(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String && _esIso8601(value)) {
        return MapEntry(key, _toMysqlDatetime(value));
      }
      return MapEntry(key, value);
    });
  }

  bool _esIso8601(String s) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(s);

  String _toMysqlDatetime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y  = dt.year.toString().padLeft(4, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final d  = dt.day.toString().padLeft(2, '0');
      final h  = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      final s  = dt.second.toString().padLeft(2, '0');
      return '$y-$mo-$d $h:$mi:$s';
    } catch (_) {
      return iso;
    }
  }
}