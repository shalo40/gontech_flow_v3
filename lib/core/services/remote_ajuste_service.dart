import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteAjusteService {
  
  // Obtener todos los ajustes como un diccionario rápido (Clave => Valor)
  Future<Map<String, dynamic>> obtenerAjustes() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/ajustes');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        // Laravel nos devuelve la data ya procesada como un mapa directo
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error en RemoteAjusteService.obtenerAjustes: $e');
      throw Exception('Error al conectar con el servidor para obtener la configuración.');
    }
  }

  // Actualizar múltiples ajustes de golpe
  Future<bool> actualizarAjustesEnMasa(List<Map<String, dynamic>> ajustesData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/ajustes/bulk',
        data: {'ajustes': ajustesData},
      );
      
      return response.statusCode == 200;
      
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
      throw Exception('Error inesperado al guardar los ajustes del sistema.');
    }
  }
}