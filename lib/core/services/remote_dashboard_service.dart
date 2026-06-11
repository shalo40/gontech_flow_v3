import '../network/api_client.dart';

class RemoteDashboardService {
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/dashboard');

      if (response.statusCode == 200) {
        // Laravel nos envía { "status": "success", "data": { "resumen": {...} } }
        // Retornamos directamente lo que está dentro de 'data' para que el Provider lo lea sin problemas.
        if (response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        }
        return response.data;
      }
      return {};
    } catch (e) {
      print('Error en RemoteDashboardService.fetchDashboard: $e');
      return {};
    }
  }
}