import 'package:flutter/material.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../../core/models/repuesto.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarRepuestoModal({
  required BuildContext context,
  required int idReferencia,
  required String origen, // 'diagnostico' o 'reparacion'
}) async {
  final dao = RepuestoDao();
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
              if (nombreCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes ingresar al menos el nombre.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final repuesto = Repuesto(
                nombre: nombreCtrl.text,
                proveedor: proveedorCtrl.text,
                cantidad: int.tryParse(cantidadCtrl.text) ?? 1,
                costoUnitario: double.tryParse(costoCtrl.text) ?? 0.0,
                estado: origen == 'diagnostico' ? 'sugerido' : 'instalado',
                origen: origen,
                idDiagnostico: origen == 'diagnostico' ? idReferencia : null,
                idPresupuesto: null,
              );

              if (origen == 'reparacion') {
                // si en tu modelo agregas id_reparacion
                repuesto.idPresupuesto = idReferencia;
              }

              await dao.insertar(repuesto);

              if (context.mounted) {
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
