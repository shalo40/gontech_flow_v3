import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../theme/app_colors.dart';

Future<void> mostrarRepuestoModal({
  required BuildContext context,
  required int idReferencia,
  required String origen, // 'diagnostico', 'presupuesto' o 'reparacion'
}) async {
  final nombreCtrl = TextEditingController();
  final proveedorCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController(text: '1');
  final costoCtrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.build_circle, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Text(
              origen == 'diagnostico'
                  ? 'Agregar repuesto sugerido'
                  : 'Agregar repuesto instalado',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombreCtrl, 'Nombre del repuesto', Icons.memory),
              _campo(proveedorCtrl, 'Proveedor', Icons.store_mall_directory),
              Row(
                children: [
                  Expanded(
                    child: _campo(
                      cantidadCtrl,
                      'Cantidad',
                      Icons.format_list_numbered,
                      tipo: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campo(
                      costoCtrl,
                      'Costo unitario',
                      Icons.attach_money,
                      tipo: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            label: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes ingresar al menos el nombre.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              // Empaquetamos exactamente como lo espera Laravel
              final repuestoParaLaravel = {
                'nombre': nombreCtrl.text.trim(),
                'proveedor': proveedorCtrl.text.trim(),
                'cantidad': int.tryParse(cantidadCtrl.text) ?? 1,
                'costo_unitario': double.tryParse(costoCtrl.text) ?? 0.0,
                'estado': origen == 'diagnostico' ? 'sugerido' : 'instalado',
                'origen': origen,
                // Asignamos la llave foránea correcta según el flujo
                'diagnostico_id': origen == 'diagnostico' ? idReferencia : null,
                'presupuesto_id': origen == 'presupuesto' ? idReferencia : null,
                'reparacion_id':  origen == 'reparacion'  ? idReferencia : null,
                'fecha_registro': DateTime.now().toIso8601String(),
              };

              try {
                final provider = context.read<HelpdeskProvider>();
                final exito = await provider.agregarRepuesto(repuestoParaLaravel);

                if (exito && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        origen == 'diagnostico'
                            ? '🔧 Repuesto sugerido agregado'
                            : '🧩 Repuesto instalado registrado',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error al guardar: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );
}

Widget _campo(
  TextEditingController ctrl,
  String label,
  IconData icono, {
  TextInputType tipo = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icono, color: Colors.tealAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
    ),
  );
}