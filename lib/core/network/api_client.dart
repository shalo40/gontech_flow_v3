import 'package:dio/dio.dart';
import '../config/api_config.dart';

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

    return _dio!;
  }
}