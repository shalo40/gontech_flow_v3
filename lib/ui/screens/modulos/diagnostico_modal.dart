import 'package:flutter/material.dart';
import '../../../core/models/diagnostico.dart';
import '../../../core/dao/diagnostico_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../../core/models/repuesto.dart';
import '../../theme/app_colors.dart';
import 'repuesto_modal.dart';

Future<void> mostrarDiagnosticoModal(
  BuildContext context,
  int idIngreso,
) async {
  final dao = DiagnosticoDao();
  final ingresoDao = IngresoDAO();
  final repuestoDao = RepuestoDao();

  final fallaCtrl = TextEditingController();
  final causasCtrl = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  String? tecnicoSeleccionado;
  List<String> pruebasSeleccionadas = [];

  // 🔬 Opciones de pruebas
  final List<String> pruebasDisponibles = [
    'Prueba de encendido',
    'Prueba de voltaje y energía',
    'Prueba de temperatura / ventilación',
    'Prueba de disco / SSD',
    'Prueba de memoria RAM',
    'Prueba de red / WiFi',
    'Limpieza interna y revisión visual',
    'Revisión BIOS / UEFI',
    'Chequeo periféricos y conectores',
  ];

  // 👨‍🔧 Técnicos (más adelante viene de usuarios)
  final List<String> tecnicos = [
    'Gonzalo Castillo',
    'Michelle Rivera',
    'Técnico General',
    'Asistente Taller',
  ];

  int pasoActual = 0;
  List<Repuesto> repuestos = [];

  Future<void> cargarRepuestos() async {
    final data = await repuestoDao.listarPorDiagnostico(idIngreso);
    repuestos = data.cast<Repuesto>();
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: const [
                Icon(Icons.biotech, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Asistente de diagnóstico',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.tealAccent.shade400,
                  ),
                ),
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: pasoActual,
                  onStepTapped: (n) => setState(() => pasoActual = n),
                  onStepContinue: () {
                    if (pasoActual < 2) {
                      setState(() => pasoActual++);
                    }
                  },
                  onStepCancel: () {
                    if (pasoActual > 0) {
                      setState(() => pasoActual--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (pasoActual > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Volver'),
                          ),
                        ElevatedButton.icon(
                          onPressed: details.onStepContinue,
                          icon: const Icon(Icons.navigate_next),
                          label: Text(
                            pasoActual < 2 ? 'Siguiente' : 'Finalizar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent.withOpacity(0.2),
                            foregroundColor: Colors.tealAccent,
                          ),
                        ),
                      ],
                    );
                  },
                  steps: [
                    // Paso 1 — Descripción de falla
                    Step(
                      title: const Text('Identificación de la falla'),
                      content: Column(
                        children: [
                          _campo(
                            fallaCtrl,
                            'Descripción del problema',
                            Icons.warning,
                          ),
                          const SizedBox(height: 10),
                          _campo(
                            causasCtrl,
                            'Posibles causas',
                            Icons.lightbulb_outline,
                          ),
                        ],
                      ),
                      isActive: pasoActual >= 0,
                      state: pasoActual > 0
                          ? StepState.complete
                          : StepState.editing,
                    ),

                    // Paso 2 — Pruebas
                    Step(
                      title: const Text('Pruebas realizadas'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: -8,
                            children: pruebasDisponibles.map((prueba) {
                              final activo = pruebasSeleccionadas.contains(
                                prueba,
                              );
                              return FilterChip(
                                label: Text(
                                  prueba,
                                  style: TextStyle(
                                    color: activo
                                        ? Colors.black
                                        : Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: activo,
                                backgroundColor: AppColors.fondo.withOpacity(
                                  0.6,
                                ),
                                selectedColor: Colors.tealAccent,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      pruebasSeleccionadas.add(prueba);
                                    } else {
                                      pruebasSeleccionadas.remove(prueba);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Repuestos sugeridos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.tealAccent,
                                ),
                                onPressed: () async {
                                  await mostrarRepuestoModal(
                                    context: context,
                                    idReferencia: idIngreso,
                                    origen: 'diagnostico',
                                  );
                                  await cargarRepuestos();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          FutureBuilder<List<Repuesto>>(
                            future: repuestoDao
                                .listarPorDiagnostico(idIngreso)
                                .then(
                                  (data) => data
                                      .map((m) => Repuesto.fromMap(m))
                                      .toList(),
                                ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text(
                                  'Sin repuestos sugeridos',
                                  style: TextStyle(color: Colors.white54),
                                );
                              }

                              final repuestos = snapshot.data!;
                              return Column(
                                children: repuestos.map((r) {
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.memory,
                                      color: Colors.tealAccent,
                                    ),
                                    title: Text(
                                      r.nombre ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Cantidad: ${r.cantidad} | Estado: ${r.estado}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                      isActive: pasoActual >= 1,
                      state: pasoActual > 1
                          ? StepState.complete
                          : StepState.editing,
                    ),

                    // Paso 3 — Conclusiones
                    Step(
                      title: const Text('Conclusiones y técnico responsable'),
                      content: Column(
                        children: [
                          _campo(
                            conclusionesCtrl,
                            'Conclusión técnica / resultado',
                            Icons.fact_check_outlined,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: tecnicoSeleccionado,
                            dropdownColor: AppColors.fondo,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Técnico responsable',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              prefixIcon: const Icon(
                                Icons.engineering,
                                color: Colors.tealAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            ),
                            items: tecnicos.map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (val) {
                              setState(() => tecnicoSeleccionado = val);
                            },
                          ),
                        ],
                      ),
                      isActive: pasoActual >= 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar diagnóstico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.2),
                  foregroundColor: Colors.tealAccent,
                ),
                onPressed: () async {
                  if (fallaCtrl.text.isEmpty ||
                      tecnicoSeleccionado == null ||
                      pruebasSeleccionadas.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa los campos requeridos antes de guardar',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final diagnostico = Diagnostico(
                    id_ingreso: idIngreso,
                    descripcion_falla: fallaCtrl.text,
                    pruebas_realizadas: pruebasSeleccionadas.join(', '),
                    conclusiones: conclusionesCtrl.text,
                    id_tecnico: 1,
                    estado: 'diagnosticado',
                  );

                  try {
                    await dao.insertar(diagnostico);
                    await ingresoDao.actualizarEstadoDesdeDiagnostico(
                      idIngreso,
                      'diagnosticado',
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Diagnóstico registrado exitosamente',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar diagnóstico: $e'),
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
