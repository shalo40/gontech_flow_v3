import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../session/session_manager.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  Dio? _dio;

  Future<Dio> get dio async {
    if (_dio != null) return _dio!;

    final baseUrl = await ApiConfig.getBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          // ESTO ES OBLIGATORIO PARA LARAVEL
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Agregar interceptor para el token de autenticación
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Extraemos el pase VIP directamente desde SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Si el servidor responde 401 (No autorizado) podríamos cerrar sesión aquí
          if (e.response?.statusCode == 401) {
            // Manejo de token expirado o sesión inválida
            await SessionManager().cerrar_sesion();
          }
          return handler.next(e);
        },
      ),
    );

    return _dio!;
  }
}