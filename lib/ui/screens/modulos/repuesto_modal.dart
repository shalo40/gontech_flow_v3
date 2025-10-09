import 'package:flutter/material.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../../core/models/repuesto.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarRepuestoModal({
  required BuildContext context,
  required int idReferencia,
  required String origen, // "diagnostico" o "presupuesto"
}) async {
  final dao = RepuestoDao();

  final nombreCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController(text: '1');
  final costoCtrl = TextEditingController();
  final proveedorCtrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        origen == 'diagnostico'
            ? 'Agregar repuesto sugerido'
            : 'Agregar repuesto al presupuesto',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, 'Nombre del repuesto'),
            _campo(cantidadCtrl, 'Cantidad', tipo: TextInputType.number),
            if (origen == 'presupuesto')
              _campo(
                costoCtrl,
                'Costo unitario (CLP)',
                tipo: TextInputType.number,
              ),
            if (origen == 'presupuesto') _campo(proveedorCtrl, 'Proveedor'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
          onPressed: () async {
            if (nombreCtrl.text.isEmpty) return;

            final repuesto = Repuesto(
              nombre: nombreCtrl.text,
              cantidad: int.tryParse(cantidadCtrl.text) ?? 1,
              costo_unitario: double.tryParse(costoCtrl.text),
              proveedor: proveedorCtrl.text,
              origen: origen,
              id_diagnostico: origen == 'diagnostico' ? idReferencia : null,
              id_presupuesto: origen == 'presupuesto' ? idReferencia : null,
            );

            await dao.insertar(repuesto);
            if (context.mounted) Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  origen == 'diagnostico'
                      ? 'Repuesto sugerido agregado 🧩'
                      : 'Repuesto añadido al presupuesto 💰',
                ),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Widget _campo(
  TextEditingController ctrl,
  String label, {
  TextInputType tipo = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
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
