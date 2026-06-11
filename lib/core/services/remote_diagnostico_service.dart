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
      final response = await dio.post(
        '/diagnosticos',
        data: diagnosticoData,
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