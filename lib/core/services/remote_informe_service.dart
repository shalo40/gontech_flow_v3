import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteInformeService {
  
  // Obtener todos los informes (Laravel enviará el árbol relacional completo)
  Future<List<dynamic>> obtenerInformes() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/informes');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteInformeService.obtenerInformes: $e');
      throw Exception('Error al conectar con el servidor para obtener los informes.');
    }
  }

  // Crear un nuevo informe técnico
  Future<Map<String, dynamic>?> crearInforme(Map<String, dynamic> informeData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/informes',
        data: informeData,
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
      throw Exception('Error inesperado al registrar el informe.');
    }
  }

  // Actualizar un informe existente (ej: corregir conclusiones o recomendaciones)
  Future<Map<String, dynamic>?> actualizarInforme(int id, Map<String, dynamic> informeData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/informes/$id',
        data: informeData,
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
      throw Exception('Error al actualizar el informe técnico.');
    }
  }

  // Eliminar un informe
  Future<bool> eliminarInforme(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/informes/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el informe del servidor.');
    }
  }
}