import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteEquipoService {
  
  // Obtener todos los equipos (Laravel ya incluirá los datos del cliente dueño)
  Future<List<dynamic>> obtenerEquipos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/equipos');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteEquipoService.obtenerEquipos: $e');
      throw Exception('Error al conectar con el servidor para obtener los equipos.');
    }
  }

  // Crear un equipo nuevo asociado a un cliente
  Future<Map<String, dynamic>?> crearEquipo(Map<String, dynamic> equipoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/equipos',
        data: equipoData,
      );
      
      if (response.statusCode == 201 && response.data['data'] != null) {
        return response.data['data']; // Retorna el equipo recién creado con su ID real
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
      throw Exception('Error inesperado al registrar el equipo en el servidor.');
    }
  }

  // Actualizar un equipo existente
  Future<Map<String, dynamic>?> actualizarEquipo(int id, Map<String, dynamic> equipoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/equipos/$id',
        data: equipoData,
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
      throw Exception('Error al actualizar el equipo en el servidor.');
    }
  }

  // Eliminar un equipo
  Future<bool> eliminarEquipo(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/equipos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el equipo del servidor.');
    }
  }
}