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
  Map<String, dynamic> entregaData,
  VoidCallback onSuccess,
) async {
  final nombreCtrl = TextEditingController(text: entregaData['nombre_receptor'] ?? '');
  final rutCtrl = TextEditingController(text: entregaData['rut_receptor'] ?? '');

  final signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.tealAccent,
    exportBackgroundColor: Colors.transparent,
  );

  bool procesando = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      // 🚀 SOLUCIÓN: Usamos MediaQuery en vez de LayoutBuilder para evitar el crash
      final size = MediaQuery.of(context).size;

      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), 
              side: BorderSide(color: Colors.tealAccent.withOpacity(0.3))
            ),
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: size.height * 0.85, // Límite de altura seguro
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 🚀 Vital para que no ocupe toda la pantalla
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.draw, color: Colors.tealAccent),
                        SizedBox(width: 8),
                        Text('Firma de Recepción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Contenido Scrolleable para que el teclado no tape nada
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Datos de quien retira:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nombreCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Nombre Completo', labelStyle: const TextStyle(color: Colors.white54),
                                filled: true, fillColor: Colors.black45,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.person, color: Colors.white38),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: rutCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'RUT', labelStyle: const TextStyle(color: Colors.white54),
                                filled: true, fillColor: Colors.black45,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.badge, color: Colors.white38),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            const Text('Firme en el recuadro inferior:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            
                            // ✍️ EL PAD DE FIRMA
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.white12)),
                                child: Signature(
                                  controller: signatureController,
                                  height: 180,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => signatureController.clear(),
                                  icon: const Icon(Icons.clear, size: 14, color: Colors.redAccent),
                                  label: const Text('Limpiar pad', style: TextStyle(color: Colors.redAccent)),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    
                    // Botones de acción fijos abajo
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          // 🚀 FIX: Cerramos el modal primero, esperamos 300ms y luego matamos el controlador
                          onPressed: procesando ? null : () async {
                            Navigator.pop(context);
                            await Future.delayed(const Duration(milliseconds: 300));
                            signatureController.dispose();
                          },
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: procesando 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                            : const Icon(Icons.check_circle, color: Colors.black),
                          label: Text(procesando ? 'Guardando...' : 'Finalizar Entrega', style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: procesando ? null : () async {
                            if (nombreCtrl.text.isEmpty || rutCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Nombre y RUT son obligatorios.')));
                              return;
                            }
                            if (signatureController.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ La firma del cliente es obligatoria.')));
                              return;
                            }

                            setStateModal(() => procesando = true);

                            try {
                              final Uint8List? signatureBytes = await signatureController.toPngBytes();
                              if (signatureBytes == null) throw Exception("Error al procesar la firma");

                              final String base64Signature = 'data:image/png;base64,${base64Encode(signatureBytes)}';
                              final provider = context.read<HelpdeskProvider>();
                              
                              final exito = await provider.actualizarEntrega(idEntrega, {
                                'nombre_receptor': nombreCtrl.text.trim(),
                                'rut_receptor': rutCtrl.text.trim(),
                                'firma_base64': base64Signature,
                                'estado': 'entregado',
                              });

                              if (exito) {
                                if (context.mounted) {
                                  Navigator.pop(context); // 🚀 FIX: Cierra el modal de inmediato
                                  onSuccess(); 
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Equipo Entregado Exitosamente'), backgroundColor: Colors.green));
                                }
                                // 🚀 FIX: Esperamos que termine la animación de cerrado antes de hacer dispose
                                await Future.delayed(const Duration(milliseconds: 300));
                                signatureController.dispose();
                              }
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                            } finally {
                              if (context.mounted) setStateModal(() => procesando = false);
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
}