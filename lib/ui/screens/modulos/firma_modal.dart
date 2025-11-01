import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/dao/entrega_dao.dart';

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

  final entregaDao = EntregaDao();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Firma del Cliente',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Por favor, firme dentro del recuadro.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Signature(
                controller: signatureController,
                backgroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.tealAccent),
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
                  ),
                  onPressed: () async {
                    if (signatureController.isNotEmpty) {
                      final Uint8List? data = await signatureController
                          .toPngBytes();
                      if (data != null) {
                        final dir = await getApplicationDocumentsDirectory();
                        final filePath =
                            '${dir.path}/firma_${DateTime.now().millisecondsSinceEpoch}.png';
                        final file = File(filePath);
                        await file.writeAsBytes(data);

                        await entregaDao.actualizarFirma(
                          idEntrega,
                          filePath,
                          data,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          onGuardado();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✍️ Firma guardada correctamente'),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
