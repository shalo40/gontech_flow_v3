import 'dart:core';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteEntregaService {
  
  // --- 📡 MÉTODOS PÚBLICOS ---

  /// Obtiene todas las entregas registradas (Laravel resolverá el árbol relacional completo)
  Future<List<dynamic>> obtenerEntregas() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/entregas');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('❌ Error en RemoteEntregaService.obtenerEntregas: $e');
      throw Exception('Error al conectar con el servidor para obtener el listado de entregas.');
    }
  }

  /// Registra una entrega formalizando el cierre (Incluye firma_base64)
  Future<Map<String, dynamic>?> crearEntrega(Map<String, dynamic> entregaData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/entregas',
        data: entregaData,
      );
      
      if (response.statusCode == 201 && response.data['data'] != null) {
        return response.data['data']; 
      }
      return null;
      
    } catch (e) {
      throw _manejarError('registrar', e);
    }
  }

  /// Actualiza datos de entrega o parcha el estado (Ej: subir la firma después de creada)
  Future<Map<String, dynamic>?> actualizarEntrega(int id, Map<String, dynamic> entregaData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/entregas/$id',
        data: entregaData,
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
      
    } catch (e) {
      throw _manejarError('actualizar', e);
    }
  }

  /// Elimina un registro de entrega
  Future<bool> eliminarEntrega(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/entregas/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en RemoteEntregaService.eliminarEntrega: $e');
      throw Exception('Error al eliminar la entrega del servidor.');
    }
  }

  // --- 🧠 INGENIERÍA PRIVADA: Manejo Inteligente de Errores de Laravel ---

  /// Analiza la DioException para extraer mensajes de error útiles o errores de validación
  Exception _manejarError(String accion, Object e) {
    print('❌ Error al $accion entrega: $e');

    if (e is DioException && e.response != null) {
      final responseData = e.response!.data;
      
      if (responseData is Map<String, dynamic>) {
        // 1. Manejo de Errores de Validación de Laravel
        if (responseData.containsKey('errors')) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstErrorListing = errors.values.first;
            if (firstErrorListing is List && firstErrorListing.isNotEmpty) {
              return Exception(firstErrorListing[0]);
            }
          }
        }
        
        // 2. Manejo de Mensajes Generales
        if (responseData.containsKey('message')) {
          return Exception(responseData['message']);
        }
      }
    }
    
    // 3. Fallback genérico
    return Exception('Error inesperado al $accion la entrega técnica. Verifique su conexión.');
  }
}