import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../theme/app_colors.dart';

Future<void> mostrarReparacionModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final descripcionCtrl = TextEditingController();
  final notasCtrl = TextEditingController();
  String estado = 'pendiente';
  int? tecnicoSeleccionado; // luego se usará lista real desde usuarios

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
              'Iniciar reparación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _campoTexto(
                    descripcionCtrl,
                    'Descripción del trabajo a realizar',
                    Icons.build_circle_outlined,
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
                      labelText: 'Técnico asignado',
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: estado,
                    dropdownColor: AppColors.fondo,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.flag,
                        color: Colors.tealAccent,
                      ),
                      labelText: 'Estado inicial',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text(
                          'Pendiente',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en_proceso',
                        child: Text(
                          'En proceso',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'finalizada',
                        child: Text(
                          'Finalizada',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => estado = v!),
                  ),
                  const SizedBox(height: 12),
                  _campoTexto(notasCtrl, 'Notas adicionales', Icons.note_alt),
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
                label: const Text('Guardar reparación'),
                onPressed: () async {
                  if (descripcionCtrl.text.isEmpty ||
                      tecnicoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa la descripción y selecciona técnico',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Empaquetamos los datos con los nombres exactos de la BD
                  final reparacionParaLaravel = {
                    'diagnostico_id': idDiagnostico,
                    'tecnico_id': tecnicoSeleccionado,
                    'descripcion': descripcionCtrl.text.trim(),
                    'fecha_inicio': DateTime.now().toIso8601String(),
                    'estado': estado,
                    'notas': notasCtrl.text.trim(),
                  };

                  try {
                    final provider = context.read<HelpdeskProvider>();
                    final exito = await provider.agregarReparacion(reparacionParaLaravel);

                    if (exito && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Reparación registrada correctamente',
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
    },
  );
}

Widget _campoTexto(TextEditingController ctrl, String label, IconData icono) {
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