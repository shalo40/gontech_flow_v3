import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteDocumentoService {
  
  // Obtener documentos globales o filtrados opcionalmente por una entidad polimórfica
  Future<List<dynamic>> obtenerDocumentos({String? tipo, int? id}) async {
    try {
      final dio = await ApiClient.instance.dio;
      
      final Map<String, dynamic> queryParameters = {};
      if (tipo != null && id != null) {
        queryParameters['tipo'] = tipo;
        queryParameters['id'] = id;
      }

      final response = await dio.get(
        '/documentos',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteDocumentoService.obtenerDocumentos: $e');
      throw Exception('Error al conectar con el servidor para obtener el archivo central de documentos.');
    }
  }

  // Subir un archivo binario al servidor vinculándolo polimórficamente a cualquier módulo
  Future<Map<String, dynamic>?> subirDocumento({
    required String entidadTipo,
    required int entidadId,
    required String filePath,
    String? nombreArchivo,
  }) async {
    try {
      final dio = await ApiClient.instance.dio;

      // Construcción del cuerpo Multipart para la transferencia de archivos binarios
      final formData = FormData.fromMap({
        'entidad_tipo': entidadTipo,
        'entidad_id': entidadId,
        'nombre_archivo': nombreArchivo,
        'archivo': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await dio.post(
        '/documentos',
        data: formData,
      );

      if (response.statusCode == 201 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
      
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
      throw Exception('Error inesperado al subir el archivo al almacenamiento central.');
    }
  }

  // Eliminar un registro de archivo y purgarlo del disco físico del servidor
  Future<bool> eliminarDocumento(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/documentos/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar el documento del almacenamiento central.');
    }
  }
}