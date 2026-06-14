import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteAuthService {
  Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
    final dio = await ApiClient.instance.dio;
    
    try {
      // Imprimimos la URL exacta que está intentando golpear para confirmar
      print('🚀 Intentando login en: ${dio.options.baseUrl}/auth/login');
      
      final res = await dio.post(
        '/auth/login',
        data: {'email': correo, 'password': contrasena},
      );
      
      final data = res.data;
      
      if (data is Map<String, dynamic> && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        print('✅ Login exitoso. Token guardado.');
        return data; 
      }
      return null;
      
    } catch (e) {
      // --- BLOQUE DE DEPURACIÓN EXTREMA ---
      print('🔥 ERROR CAPTURADO EN LOGIN 🔥');
      print('Tipo de error crudo: ${e.runtimeType}');
      print('Detalle crudo: $e');

      // 1. Verificamos si el error viene de la petición HTTP (Dio)
      if (e is DioException) {
        print('DioException Type: ${e.type}');
        print('DioException Message: ${e.message}');
        print('DioException Error: ${e.error}');

        if (e.response != null) {
          final responseData = e.response!.data;
          print('Status Code: ${e.response!.statusCode}');
          print('Response Data: $responseData');
          
          // 2. Extraemos el mensaje específico de Laravel
          if (responseData is Map<String, dynamic>) {
            
            // Si es un error de validación (422) o nuestro mensaje personalizado (401/403)
            if (responseData.containsKey('message')) {
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
          // Si cae aquí, es porque NUNCA llegó al servidor (Error de certificado, DNS, o Timeout)
          // Lanzamos el error real de Dio para que lo veas en el SnackBar en lugar del genérico
          throw Exception('Fallo de conexión interno: ${e.message ?? e.error.toString()}');
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