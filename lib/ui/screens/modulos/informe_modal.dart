import 'package:flutter/material.dart';
import '../../../core/dao/informe_dao.dart';
import '../../../core/models/informe.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarInformeModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final dao = InformeDao();

  final descripcionCtrl = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  final recomendacionesCtrl = TextEditingController();
  int? tecnicoSeleccionado;

  final List<Map<String, dynamic>> tecnicos = [
    {'id': 1, 'nombre': 'Gonzalo Castillo'},
    {'id': 2, 'nombre': 'Técnico 2'},
    {'id': 3, 'nombre': 'Técnico 3'},
  ];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Crear informe técnico',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(
                    descripcionCtrl,
                    'Descripción general',
                    Icons.description,
                  ),
                  _campo(
                    conclusionesCtrl,
                    'Conclusiones',
                    Icons.fact_check_outlined,
                  ),
                  _campo(
                    recomendacionesCtrl,
                    'Recomendaciones',
                    Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: tecnicoSeleccionado,
                    dropdownColor: AppColors.fondo,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.engineering,
                        color: Colors.tealAccent,
                      ),
                      labelText: 'Técnico responsable',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: tecnicos
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t['id'],
                            child: Text(
                              t['nombre'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => tecnicoSeleccionado = v),
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
                label: const Text('Guardar informe'),
                onPressed: () async {
                  if (descripcionCtrl.text.isEmpty ||
                      tecnicoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Completa los campos requeridos'),
                      ),
                    );
                    return;
                  }

                  final informe = Informe(
                    idDiagnostico: idDiagnostico,
                    idTecnico: tecnicoSeleccionado,
                    descripcionGeneral: descripcionCtrl.text,
                    conclusiones: conclusionesCtrl.text,
                    recomendaciones: recomendacionesCtrl.text,
                    fechaCreacion: DateTime.now().toIso8601String(),
                  );

                  await dao.insertar(informe);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Informe técnico guardado correctamente',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _campo(TextEditingController ctrl, String label, IconData icono) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
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
