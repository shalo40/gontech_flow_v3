import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../session/session_manager.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final SessionManager _session = SessionManager();
  Dio? _dio;

  Future<Dio> get dio async {
    if (_dio != null) return _dio!;
    final baseUrl = await ApiConfig.getBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _session.obtener_token();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
    return _dio!;
  }

  Future<void> refreshBaseUrl() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    _dio?.options.baseUrl = baseUrl;
  }
}

