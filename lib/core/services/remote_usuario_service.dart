// ignore_for_file: avoid_print
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../models/usuario.dart';

/// Servicio remoto para gestión de usuarios.
/// Expone la consulta de técnicos activos para poblar dropdowns operativos.
class RemoteUsuarioService {

  /// Retorna la lista de usuarios con rol == 'tecnico'.
  /// Intenta primero con query params; si falla con 404, reintenta sin filtros
  /// y filtra en cliente (para APIs que no soporten query params en ese endpoint).
  Future<List<Usuario>> obtenerTecnicos() async {
    try {
      final dio = await ApiClient.instance.dio;

      // Log de diagnóstico: confirma token y URL exacta
      print('🔍 [RemoteUsuarioService] GET ${dio.options.baseUrl}/usuarios');

      Response response;
      try {
        // Intento 1: endpoint filtrado por rol
        response = await dio.get(
          '/usuarios',
          queryParameters: {'rol': 'tecnico', 'activo': 1},
        );
      } on DioException catch (e1) {
        // Si el servidor devuelve 404 (ruta no acepta query params), reintenta sin filtros
        if (e1.response?.statusCode == 404) {
          print('⚠️ [RemoteUsuarioService] 404 con query params, reintentando sin filtros...');
          response = await dio.get('/usuarios');
        } else {
          rethrow;
        }
      }

      print('✅ [RemoteUsuarioService] status=${response.statusCode}');

      if (response.statusCode == 200) {
        final raw = response.data;

        // Tolera lista directa o envuelta en {data: [...]}
        final List<dynamic> lista = (raw is Map && raw.containsKey('data'))
            ? (raw['data'] as List<dynamic>)
            : (raw as List<dynamic>);

        // Si el endpoint no filtra en servidor, filtramos aquí
        final tecnicosMaps = lista.where((json) {
          final map = json as Map;
          final rol = (map['rol'] ?? map['role'] ?? '').toString().toLowerCase();
          return rol == 'tecnico' || rol == 'technician';
        }).toList();

        return tecnicosMaps.map((json) {
          final map = Map<String, dynamic>.from(json as Map);
          // Normaliza variantes de clave del UsuarioResource de Laravel
          map['id_usuario'] ??= map['id'];
          map['nombre']     ??= map['name'] ?? 'Sin nombre';
          map['correo']     ??= map['email'] ?? '';
          map['contrasena'] ??= '';   // no viaja por seguridad
          map['rol']        ??= 'tecnico';
          return Usuario.fromMap(map);
        }).toList();
      }

      print('⚠️ [RemoteUsuarioService] Respuesta inesperada: ${response.statusCode}');
      return [];

    } catch (e) {
      if (e is DioException) {
        // Log completo para diagnóstico en consola
        print('❌ [RemoteUsuarioService] DioException status=${e.response?.statusCode}');
        print('❌ [RemoteUsuarioService] body=${e.response?.data}');

        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          throw Exception(data['message']);
        }
        if (e.response?.statusCode == 401) {
          throw Exception('No autorizado: verifica que el token de sesión sea válido.');
        }
        if (e.response?.statusCode == 404) {
          throw Exception('Endpoint /usuarios no encontrado. Verifica las rutas de Laravel.');
        }
      }
      // Devuelve lista vacía en lugar de explotar el modal
      print('❌ [RemoteUsuarioService] Error: $e');
      return [];
    }
  }
}
