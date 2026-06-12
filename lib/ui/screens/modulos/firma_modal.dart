import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarFirmaModal(
  BuildContext context,
  int idEntrega,
  Function onGuardado,
) async {
  final signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.tealAccent,
    exportBackgroundColor: Colors.black,
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
                    const Text(
                      'Por favor, firme dentro del recuadro:',
                      style: TextStyle(color: Colors.white70),
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
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (signatureController.isNotEmpty) {
                              final Uint8List? data = await signatureController.toPngBytes();
                              
                              if (data != null) {
                                // 1. Convertimos los bytes del lienzo a un string Base64
                                final String base64Firma = 'data:image/png;base64,${base64Encode(data)}';

                                // 2. Empaquetamos la actualización
                                final actualizacionEntrega = {
                                  'firma_base64': base64Firma,
                                  'estado': 'entregado',
                                };

                                try {
                                  // 3. Enviamos la carga útil al Cerebro
                                  final provider = context.read<HelpdeskProvider>();
                                  await provider.actualizarEntrega(idEntrega, actualizacionEntrega);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    onGuardado();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✍️ Firma guardada y entrega finalizada con éxito',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ Error al guardar firma: $e'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
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