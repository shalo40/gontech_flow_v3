import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteReparacionService {
  
  // --- 📡 MÉTODOS PÚBLICOS ---

  /// Obtiene todas las reparaciones (incluyendo el árbol jerárquico desde Laravel)
  Future<List<dynamic>> obtenerReparaciones() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/reparaciones');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('❌ Error en RemoteReparacionService.obtenerReparaciones: $e');
      throw Exception('Error al conectar con el servidor para obtener las reparaciones.');
    }
  }

  /// Registra una reparación nueva automáticamente tras la aprobación de un presupuesto
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
      // 🧠 Usamos el manejador de errores inteligente extraído abajo
      throw _manejarError('registrar', e);
    }
  }

  /// Actualiza una reparación (ej. cambiar estado, asignar técnico, cerrar fechas)
  Future<Map<String, dynamic>?> actualizarReparacion(int id, Map<String, dynamic> reparacionData) async {
    try {
      final dio = await ApiClient.instance.dio;
      // Usamos PUT para actualizaciones RESTful
      final response = await dio.put(
        '/reparaciones/$id',
        data: reparacionData,
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
      
    } catch (e) {
      // 🧠 Ahora la actualización también tiene manejo inteligente de errores de Laravel
      throw _manejarError('actualizar', e);
    }
  }

  /// Elimina una reparación
  Future<bool> eliminarReparacion(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/reparaciones/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error en RemoteReparacionService.eliminarReparacion: $e');
      throw Exception('Error al eliminar la reparación del servidor.');
    }
  }

  // --- 🧠 INGENIERÍA PRIVADA: Manejo Inteligente de Errores de Laravel ---

  /// Analiza la DioException para extraer mensajes de error útiles o errores de validación
  Exception _manejarError(String accion, Object e) {
    print('❌ Error al $accion reparación: $e');

    if (e is DioException && e.response != null) {
      final responseData = e.response!.data;
      
      if (responseData is Map<String, dynamic>) {
        // 1. Manejo de Errores de Validación de Laravel (errors: { campo: [mensaje] })
        if (responseData.containsKey('errors')) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            // Extraemos solo el primer mensaje de error para mostrar en el SnackBar
            final firstErrorListing = errors.values.first;
            if (firstErrorListing is List && firstErrorListing.isNotEmpty) {
              return Exception(firstErrorListing[0]);
            }
          }
        }
        
        // 2. Manejo de Mensajes Generales de Excepción (message: "error...")
        if (responseData.containsKey('message')) {
          return Exception(responseData['message']);
        }
      }
    }
    
    // 3. Fallback para errores de red o desconocidos
    return Exception('Error inesperado al $accion la reparación. Verifique su conexión.');
  }
}