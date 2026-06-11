import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteIngresoService {
  
  // Obtener todos los ingresos (incluyendo equipo, cliente y diagnósticos asociados)
  Future<List<dynamic>> obtenerIngresos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/ingresos');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
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
      final response = await dio.post(
        '/ingresos',
        data: ingresoData,
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
      throw Exception('Error inesperado al registrar el ingreso.');
    }
  }

  // Actualizar un ingreso (ej: cambio de estado)
  Future<Map<String, dynamic>?> actualizarIngreso(int id, Map<String, dynamic> ingresoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/ingresos/$id',
        data: ingresoData,
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
      throw Exception('Error al actualizar el ingreso.');
    }
  }

  // Eliminar un ingreso
  Future<bool> eliminarIngreso(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/ingresos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el ingreso.');
    }
  }
}