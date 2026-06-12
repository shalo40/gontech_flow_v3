import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VisorMediaScreen extends StatelessWidget {
  final String urlImagen;
  final String titulo;

  const VisorMediaScreen({
    super.key,
    required this.urlImagen,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Un fondo negro puro ayuda a resaltar los detalles de las fotografías técnicas
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0, // Permite un zoom de hasta 4x para ver soldaduras o detalles
          child: Image.network(
            urlImagen,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.tealAccent,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No se pudo cargar la imagen.\nVerifica tu conexión a internet.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}