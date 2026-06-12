import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionUtil {
  /// Solicita permisos de almacenamiento según la versión del SO
  static Future<bool> solicitarPermisosArchivos(BuildContext context) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ utiliza permisos granulares
        status = await Permission.photos.request();
      } else {
        // Android 12 e inferior
        status = await Permission.storage.request();
      }
    } else {
      // iOS
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _mostrarDialogoAjustes(context);
      }
    }

    return false;
  }

  static void _mostrarDialogoAjustes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permisos requeridos', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Gontech Solutions necesita acceso a tus archivos para poder adjuntar evidencias. Por favor, habilítalos en los ajustes del sistema.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ir a Ajustes', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}