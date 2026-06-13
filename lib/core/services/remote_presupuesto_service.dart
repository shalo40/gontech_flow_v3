import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemotePresupuestoService {
  
  // Obtener todos los presupuestos (Laravel enviará el árbol completo: diagnóstico -> ingreso -> equipo -> cliente)
  Future<List<dynamic>> obtenerPresupuestos() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/presupuestos');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemotePresupuestoService.obtenerPresupuestos: $e');
      throw Exception('Error al conectar con el servidor para obtener los presupuestos.');
    }
  }

  // Registrar un presupuesto nuevo
  Future<Map<String, dynamic>?> crearPresupuesto(Map<String, dynamic> presupuestoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/presupuestos',
        data: presupuestoData,
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
      throw Exception('Error inesperado al registrar el presupuesto.');
    }
  }

  // Actualizar un presupuesto (útil para cambiar de "pendiente" a "autorizado" o "rechazado")
  Future<Map<String, dynamic>?> actualizarPresupuesto(int id, Map<String, dynamic> presupuestoData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/presupuestos/$id',
        data: presupuestoData,
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
      throw Exception('Error al actualizar el presupuesto.');
    }
  }

  // Eliminar un presupuesto
  Future<bool> eliminarPresupuesto(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/presupuestos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el presupuesto del servidor.');
    }
  }
}
