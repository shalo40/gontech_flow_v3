import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart'; // <-- Para crear el archivo temporal
import '../../../core/providers/helpdesk_provider.dart';

Future<void> mostrarFirmaModal(
  BuildContext context,
  int idEntidad, 
  String tipoEntidad, // <-- ¡NUEVO! 'ingreso' o 'entrega'
  Function onGuardado,
) async {
  final signatureController = SignatureController(
    penStrokeWidth: 3, // Un poco más grueso para que se vea mejor en PDF
    penColor: Colors.tealAccent,
    exportBackgroundColor: Colors.transparent, // Transparente para usarla sobre recibos blancos
  );

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: constraints.maxHeight * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Firma del Cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tipoEntidad == 'ingreso' 
                        ? 'Firme para aceptar las condiciones de recepción:'
                        : 'Firme para confirmar la entrega del equipo:',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 🖋 Área de firma
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.tealAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Signature(
                        controller: signatureController,
                        backgroundColor: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔘 Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.tealAccent,
                          ),
                          label: const Text(
                            'Borrar',
                            style: TextStyle(color: Colors.tealAccent),
                          ),
                          onPressed: () => signatureController.clear(),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: const Text('Guardar firma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (signatureController.isNotEmpty) {
                              // Obtenemos los bytes del dibujo
                              final Uint8List? data = await signatureController.toPngBytes();
                              
                              if (data != null) {
                                try {
                                  // 1. Creamos un archivo temporal físico en el dispositivo
                                  final tempDir = await getTemporaryDirectory();
                                  final file = await File('${tempDir.path}/firma_${tipoEntidad}_$idEntidad.png').create();
                                  await file.writeAsBytes(data);

                                  // 2. Usamos tu API Polimórfica para subir la firma como documento
                                  final provider = context.read<HelpdeskProvider>();
                                  await provider.asociarDocumentoAEntidad(
                                    tipo: tipoEntidad,
                                    id: idEntidad,
                                    rutaLocal: file.path,
                                    nombrePersonalizado: 'firma_cliente.png',
                                  );

                                  // 3. (Opcional) Si es entrega, actualizamos el estado
                                  if (tipoEntidad == 'entrega') {
                                    await provider.actualizarEntrega(idEntidad, {'estado': 'entregado'});
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context); // Cierra el modal
                                    onGuardado();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ Error al guardar firma: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('El lienzo de firma está vacío.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}