import 'dart:async';
import 'dart:core';

import 'package:dio/dio.dart';
import '../network/api_client.dart';

class RemoteEntregaService {
  
  // Obtener todas las entregas registradas (Laravel resolverá el árbol relacional completo)
  Future<List<dynamic>> obtenerEntregas() async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.get('/entregas');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error en RemoteEntregaService.obtenerEntregas: $e');
      throw Exception('Error al conectar con el servidor para obtener el listado de entregas.');
    }
  }

  // Registrar una entrega formalizando el cierre (Incluye firma_base64)
  Future<Map<String, dynamic>?> crearEntrega(Map<String, dynamic> entregaData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.post(
        '/entregas',
        data: entregaData,
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
      throw Exception('Error inesperado al registrar la entrega técnica.');
    }
  }

  // Actualizar datos de entrega o parchar el estado
  Future<Map<String, dynamic>?> actualizarEntrega(int id, Map<String, dynamic> entregaData) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.put(
        '/entregas/$id',
        data: entregaData,
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
      
    } catch (e) {
      if (e is DioException && e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          throw Exception(responseData['message']);
        }
      }
      throw Exception('Error al actualizar la hoja de entrega.');
    }
  }

  // Eliminar un registro de entrega
  Future<bool> eliminarEntrega(int id) async {
    try {
      final dio = await ApiClient.instance.dio;
      final response = await dio.delete('/entregas/$id');
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al eliminar la entrega del servidor.');
    }
  }
}