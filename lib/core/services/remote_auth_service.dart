import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // <-- Importante para el catch
import '../network/api_client.dart';

class RemoteAuthService {
  Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
    final dio = await ApiClient.instance.dio;
    
    try {
      final res = await dio.post(
        '/auth/login',
        data: {'email': correo, 'password': contrasena},
      );
      
      final data = res.data;
      
      if (data is Map<String, dynamic> && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return data; 
      }
      return null;
      
    } catch (e) {
      // 1. Verificamos si el error viene de la petición HTTP (Dio)
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          
          // 2. Extraemos el mensaje específico de Laravel
          if (responseData is Map<String, dynamic>) {
            
            // Si es un error de validación (422) o nuestro mensaje personalizado (401/403)
            if (responseData.containsKey('message')) {
              // Lanzamos la excepción con el mensaje exacto del backend
              throw Exception(responseData['message']);
            } 
            
            // Si Laravel envía el array clásico de 'errors'
            if (responseData.containsKey('errors')) {
              final errors = responseData['errors'] as Map<String, dynamic>;
              final firstError = errors.values.first[0];
              throw Exception(firstError);
            }
          }
          // Error del servidor (ej. 500)
          throw Exception('Error del servidor: código ${e.response!.statusCode}');
        } else {
          // Error de red (timeout, sin conexión al localhost)
          throw Exception('No se pudo conectar con el servidor. Revisa tu red.');
        }
      }
      
      // Cualquier otro error interno de Flutter
      throw Exception('Ocurrió un error inesperado: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}