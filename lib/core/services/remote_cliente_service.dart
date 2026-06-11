import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteClienteService {
  
  // Obtener todos los clientes
  Future<List<dynamic>> obtenerClientes() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/clientes');
      
      // Laravel devuelve: { "status": "success", "data": [...] }
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteClienteService.obtenerClientes: $e');
      throw Exception('Error al conectar con el servidor para obtener clientes.');
    }
  }

  // Crear un cliente nuevo
  Future<Map<String, dynamic>?> crearCliente(Map<String, dynamic> clienteData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/clientes',
        data: clienteData,
      );
      
      if (response.statusCode == 201 && response.data['data'] != null) {
        return response.data['data']; // Retorna el cliente recién creado
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
      throw Exception('Error inesperado al registrar el cliente en el servidor.');
    }
  }

  // Actualizar un cliente existente
  Future<Map<String, dynamic>?> actualizarCliente(int id, Map<String, dynamic> clienteData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/clientes/$id',
        data: clienteData,
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
      throw Exception('Error al actualizar el cliente en el servidor.');
    }
  }

  // Eliminar un cliente
  Future<bool> eliminarCliente(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/clientes/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el cliente del servidor.');
    }
  }
}