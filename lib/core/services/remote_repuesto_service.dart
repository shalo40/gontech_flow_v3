import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteRepuestoService {
  
  // Obtener todos los repuestos registrados en el sistema
  Future<List<dynamic>> obtenerRepuestos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/repuestos');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteRepuestoService.obtenerRepuestos: $e');
      throw Exception('Error al conectar con el servidor para obtener los repuestos.');
    }
  }

  // Vincular un repuesto (puede asociarse a diagnostico_id, presupuesto_id o reparacion_id)
  Future<Map<String, dynamic>?> crearRepuesto(Map<String, dynamic> repuestoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/repuestos',
        data: repuestoData,
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
      throw Exception('Error inesperado al registrar el repuesto.');
    }
  }

  // Actualizar datos o estado de un repuesto (ej: cambiar de 'sugerido' a 'instalado')
  Future<Map<String, dynamic>?> actualizarRepuesto(int id, Map<String, dynamic> repuestoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/repuestos/$id',
        data: repuestoData,
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
      throw Exception('Error al actualizar el repuesto.');
    }
  }

  // Eliminar un repuesto del inventario o del flujo
  Future<bool> eliminarRepuesto(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/repuestos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el repuesto del servidor.');
    }
  }
}