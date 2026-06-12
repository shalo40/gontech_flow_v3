import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers/helpdesk_provider.dart';
// Nota: evitamos importar api_config debido a rutas relativas inconsistentes.
// Usaremos la URL pública tal cual viene desde el backend.
import '../../../core/utils/permission_util.dart'; // <-- Integración del escudo de permisos
import '../theme/app_colors.dart';
import '../screens/modulos/visor_media_screen.dart';

Future<void> mostrarAdjuntosModal({
  required BuildContext context,
  required String entidadTipo,
  required int entidadId,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: _AdjuntosModalContent(
          entidadTipo: entidadTipo,
          entidadId: entidadId,
        ),
      );
    },
  );
}

class _AdjuntosModalContent extends StatefulWidget {
  final String entidadTipo;
  final int entidadId;

  const _AdjuntosModalContent({
    required this.entidadTipo,
    required this.entidadId,
  });

  @override
  State<_AdjuntosModalContent> createState() => _AdjuntosModalContentState();
}

class _AdjuntosModalContentState extends State<_AdjuntosModalContent> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpdeskProvider>().recargarDocumentos(
            tipo: widget.entidadTipo,
            id: widget.entidadId,
          );
    });
  }

  Future<void> _seleccionarYSubir() async {
    // 1. Intercepción de seguridad: Solicitar permisos antes de abrir el explorador
    final tienePermiso = await PermissionUtil.solicitarPermisosArchivos(context);
    if (!tienePermiso) return;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);
        
        final provider = context.read<HelpdeskProvider>();
        final exito = await provider.asociarDocumentoAEntidad(
          tipo: widget.entidadTipo,
          id: widget.entidadId,
          rutaLocal: result.files.single.path!,
          nombrePersonalizado: result.files.single.name,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exito ? '✅ Archivo subido con éxito' : '❌ Error al subir'),
              backgroundColor: exito ? Colors.teal : Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final isLoading = provider.loading || _isUploading;
    
    final documentos = provider.documentos.where((doc) => 
      doc['entidad_tipo'] == widget.entidadTipo && 
      doc['entidad_id'] == widget.entidadId
    ).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Archivos Adjuntos',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: documentos.isEmpty && !isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No hay archivos adjuntos.', style: TextStyle(color: Colors.white54)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: documentos.length,
                    itemBuilder: (context, index) {
                      final doc = documentos[index];
                      final isPdf = doc['nombre_archivo'].toString().toLowerCase().endsWith('.pdf');
                      
                      return ListTile(
                        leading: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.image, 
                          color: isPdf ? Colors.orangeAccent : Colors.blueAccent
                        ),
                        title: Text(
                          doc['nombre_archivo'] ?? 'Documento', 
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          if (isPdf) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Función de visor PDF en desarrollo...')),
                            );
                          } else {
                            final urlPublica = (doc['url_publica'] ?? '').toString();
                            if (urlPublica.isNotEmpty) {
                              final fullUrl = urlPublica; // Asumir URL completa desde backend
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VisorMediaScreen(
                                    urlImagen: fullUrl,
                                    titulo: doc['nombre_archivo'] ?? 'Evidencia',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            await provider.borrarDocumento(doc['id']);
                          },
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isUploading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.upload_file, color: Colors.black),
              label: Text(_isUploading ? 'Subiendo...' : 'Adjuntar nuevo archivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: _isUploading ? null : _seleccionarYSubir,
            ),
          ),
        ],
      ),
    );
  }
}