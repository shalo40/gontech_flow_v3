import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteReparacionService {
  
  // Obtener todas las reparaciones (Laravel enviará el árbol: diagnostico/presupuesto -> ingreso -> equipo -> cliente)
  Future<List<dynamic>> obtenerReparaciones() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/reparaciones');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteReparacionService.obtenerReparaciones: $e');
      throw Exception('Error al conectar con el servidor para obtener las reparaciones.');
    }
  }

  // Registrar una reparación nueva
  Future<Map<String, dynamic>?> crearReparacion(Map<String, dynamic> reparacionData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/reparaciones',
        data: reparacionData,
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
      throw Exception('Error inesperado al registrar la reparación.');
    }
  }

  // Actualizar una reparación (ej. cambiar estado a en_proceso o finalizado)
  Future<Map<String, dynamic>?> actualizarReparacion(int id, Map<String, dynamic> reparacionData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/reparaciones/$id',
        data: reparacionData,
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
      throw Exception('Error al actualizar la reparación.');
    }
  }

  // Eliminar una reparación
  Future<bool> eliminarReparacion(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/reparaciones/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar la reparación del servidor.');
    }
  }
}