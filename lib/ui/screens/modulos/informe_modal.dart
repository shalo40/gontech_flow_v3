import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/providers/helpdesk_provider.dart'; // <-- El Cerebro
import '../../theme/app_colors.dart';

Future<void> mostrarInformeModal(
  BuildContext context,
  int idDiagnosticoInicial,
) async {
  final descripcionCtrl = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  final recomendacionesCtrl = TextEditingController();
  int? tecnicoSeleccionado;
  int? diagnosticoSeleccionado = idDiagnosticoInicial == 0 ? null : idDiagnosticoInicial;

  final provider = context.read<HelpdeskProvider>();
  final diagnosticos = provider.diagnosticos; // Lista global de diagnósticos

  // --- Helper para mostrar el nombre del equipo y cliente en el Dropdown ---
  String getInfoDiagnostico(Map<String, dynamic> d) {
    String marca = 'Equipo';
    String cliente = 'Cliente';
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      marca = d['ingreso']['equipo']['marca'] ?? marca;
      if (d['ingreso']['equipo']['cliente'] != null) {
        cliente = d['ingreso']['equipo']['cliente']['nombre'] ?? cliente;
      }
    }
    return '$marca - $cliente';
  }
  
  int getIdDiag(Map<String, dynamic> d) {
    return int.tryParse((d['id_diagnostico'] ?? d['id'] ?? '0').toString()) ?? 0;
  }
  // -----------------------------------------------------------------------

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
                  // 🔽 Dropdown para vincular el Diagnóstico Base
                  DropdownButtonFormField<int>(
                    value: diagnosticoSeleccionado,
                    dropdownColor: AppColors.fondo,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.tealAccent,
                      ),
                      labelText: 'Diagnóstico base',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: diagnosticos.map((d) {
                      final id = getIdDiag(d);
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '#$id - ${getInfoDiagnostico(d)}',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => diagnosticoSeleccionado = v),
                  ),
                  const SizedBox(height: 12),

                  _campo(
                    descripcionCtrl,
                    'Descripción general del trabajo',
                    Icons.description,
                  ),
                  _campo(
                    conclusionesCtrl,
                    'Conclusiones',
                    Icons.fact_check_outlined,
                  ),
                  _campo(
                    recomendacionesCtrl,
                    'Recomendaciones futuras',
                    Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 12),
                  
                  // 🔽 Dropdown para asignar al Técnico Responsable
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
                label: const Text('Guardar informe'),
                onPressed: () async {
                  if (descripcionCtrl.text.isEmpty ||
                      tecnicoSeleccionado == null ||
                      diagnosticoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona el diagnóstico, el técnico y añade una descripción.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Empaquetamos la data para la API de Laravel
                  final informeParaLaravel = {
                    'diagnostico_id': diagnosticoSeleccionado,
                    'tecnico_id': tecnicoSeleccionado,
                    'descripcion_general': descripcionCtrl.text.trim(),
                    'conclusiones': conclusionesCtrl.text.trim(),
                    'recomendaciones': recomendacionesCtrl.text.trim(),
                    'creado_en': DateTime.now().toIso8601String(),
                  };

                  try {
                    final exito = await provider.agregarInforme(informeParaLaravel);

                    if (exito && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Informe técnico guardado correctamente',
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
    },
  );
}

Widget _campo(TextEditingController ctrl, String label, IconData icono) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      maxLines: null, // Permite múltiples líneas para reportes extensos
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