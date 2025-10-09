import 'package:flutter/material.dart';
import '../../../core/models/presupuesto.dart';
import '../../../core/dao/presupuesto_dao.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarPresupuestoModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final dao = PresupuestoDao();
  final descripcionCtrl = TextEditingController();
  final totalCtrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Crear presupuesto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(
                descripcionCtrl,
                'Descripción del trabajo',
                Icons.description,
              ),
              _campo(
                totalCtrl,
                'Total estimado (CLP)',
                Icons.attach_money,
                tipo: TextInputType.number,
              ),
            ],
          ),
        ),
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
              if (descripcionCtrl.text.isEmpty || totalCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Completa todos los campos antes de continuar',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final presupuesto = Presupuesto(
                idDiagnostico: idDiagnostico,
                descripcion: descripcionCtrl.text,
                total: double.tryParse(totalCtrl.text) ?? 0.0,
                estado: 'pendiente',
                fechaCreacion: DateTime.now().toIso8601String(),
              );

              await dao.insertar(presupuesto);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Presupuesto creado correctamente'),
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
