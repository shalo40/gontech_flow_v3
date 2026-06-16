import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarDiagnosticoModal(BuildContext context, int idIngreso) async {
  final fallaCtrl = TextEditingController();
  final causasCtrl = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  final horasCtrl = TextEditingController(text: '1.0');
  final picker = ImagePicker();
  
  File? fotoFalla; 
  String? tecnicoSeleccionado = 'Gonzalo Castillo';
  String complejidadSeleccionada = 'medio'; // bajo, medio, alto, critico

  // 🔬 Estructura avanzada de pruebas (Mapa para guardar si Pasa o Falla)
  final List<String> pruebasDisponibles = [
    'Prueba de encendido / booteo',
    'Prueba de voltaje y energía (Tester)',
    'Prueba de temperatura y ventilación',
    'Prueba de almacenamiento (Disco/SSD)',
    'Prueba de memoria RAM',
    'Prueba de conectividad (WiFi/Red)',
    'Limpieza interna e inspección visual',
    'Revisión de BIOS / UEFI',
  ];
  
  // Guardará el estado de cada prueba: null = No realizada, true = Pasa (OK), false = Falla (A reparar)
  Map<String, bool?> estadosPruebas = {
    for (var prueba in pruebasDisponibles) prueba: null
  };

  final List<String> tecnicos = [
    'Gonzalo Castillo',
    'Michelle Rivera',
    'Técnico General',
  ];

  int pasoActual = 0;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final provider = context.watch<HelpdeskProvider>();

          Future<void> capturarFotoFalla() async {
            final XFile? imagen = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70,
            );
            if (imagen != null) {
              setModalState(() => fotoFalla = File(imagen.path));
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.biotech, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Asistente de diagnóstico',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(primary: Colors.tealAccent.shade400),
                ),
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: pasoActual,
                  onStepTapped: (n) => setModalState(() => pasoActual = n),
                  onStepContinue: () {
                    if (pasoActual < 2) {
                      setModalState(() => pasoActual++);
                    }
                  },
                  onStepCancel: () {
                    if (pasoActual > 0) {
                      setModalState(() => pasoActual--);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (pasoActual > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Volver', style: TextStyle(color: Colors.white60)),
                            )
                          else
                            const SizedBox.shrink(),
                          ElevatedButton.icon(
                            onPressed: details.onStepContinue,
                            icon: Icon(pasoActual < 2 ? Icons.navigate_next : Icons.check_circle_outline),
                            label: Text(pasoActual < 2 ? 'Siguiente' : 'Validar Pasos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.withOpacity(0.2),
                              foregroundColor: Colors.tealAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    // --- PASO 1: EVALUACIÓN Y CAUSAS ---
                    Step(
                      title: const Text('Hallazgos de Laboratorio'),
                      content: Column(
                        children: [
                          _campo(fallaCtrl, 'Falla técnica verificada', Icons.bug_report, maxLines: 2),
                          const SizedBox(height: 8),
                          _campo(causasCtrl, 'Origen / Causas del daño (ej: humedad, alza voltaje)', Icons.bolt, maxLines: 2),
                        ],
                      ),
                      isActive: pasoActual >= 0,
                      state: pasoActual > 0 ? StepState.complete : StepState.editing,
                    ),

                    // --- PASO 2: PRUEBAS Y EVIDENCIA VISUAL ---
                    Step(
                      title: const Text('Inspección y Banco de Pruebas'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resultado de Testeos:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...pruebasDisponibles.map((prueba) {
                            final estado = estadosPruebas[prueba];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(prueba, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check_circle, color: estado == true ? Colors.green : Colors.white24, size: 20),
                                        onPressed: () => setModalState(() => estadosPruebas[prueba] = true),
                                        tooltip: 'Pasa el test',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.cancel, color: estado == false ? Colors.redAccent : Colors.white24, size: 20),
                                        onPressed: () => setModalState(() => estadosPruebas[prueba] = false),
                                        tooltip: 'Falla detectada',
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }),
                          const Divider(color: Colors.white24, height: 20),
                          // Captura de evidencia interna
                          const Text('Evidencia del daño (Foto interna)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: capturarFotoFalla,
                            child: Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: fotoFalla != null ? Colors.tealAccent : Colors.white24),
                              ),
                              child: fotoFalla != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(fotoFalla!, fit: BoxFit.cover))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, color: Colors.tealAccent, size: 22),
                                        SizedBox(width: 8),
                                        Text('Capturar componente dañado', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      isActive: pasoActual >= 1,
                      state: pasoActual > 1 ? StepState.complete : StepState.editing,
                    ),

                    // --- PASO 3: PARÁMETROS COMERCIALES Y CIERRE ---
                    Step(
                      title: const Text('Estimación y Complejidad'),
                      content: Column(
                        children: [
                          _campo(conclusionesCtrl, 'Dictamen final / Solución recomendada', Icons.gavel_rounded, maxLines: 2),
                          const SizedBox(height: 10),
                          // SOLUCIÓN AL OVERFLOW: Columna en lugar de Fila
                          Column(
                            children: [
                              _campo(horasCtrl, 'Horas de Mano de Obra (Ej: 1.5)', Icons.hourglass_top, keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: complejidadSeleccionada,
                                dropdownColor: AppColors.fondo,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Riesgo / Complejidad',
                                  labelStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.equalizer, color: Colors.tealAccent, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: ['bajo', 'medio', 'alto', 'critico'].map((c) {
                                  return DropdownMenuItem(value: c, child: Text(c.toUpperCase()));
                                }).toList(),
                                onChanged: (val) => setModalState(() => complejidadSeleccionada = val!),
                              ),
                            ],
                          ),  
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: tecnicoSeleccionado,
                            dropdownColor: AppColors.fondo,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Técnico asignado',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.engineering, color: Colors.tealAccent, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: tecnicos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) => setModalState(() => tecnicoSeleccionado = val),
                          ),
                        ],
                      ),
                      isActive: pasoActual >= 2,
                    ),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_as_outlined),
                label: const Text('Guardar informe'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                onPressed: () async {
                  if (fallaCtrl.text.trim().isEmpty || conclusionesCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ Rellena la Falla y el Dictamen Final antes de guardar.')),
                    );
                    return;
                  }

                  // Formateamos las pruebas realizadas
                  List<String> resumenPruebas = [];
                  estadosPruebas.forEach((prueba, estado) {
                    if (estado != null) {
                      resumenPruebas.add('$prueba: ${estado ? "[PASÓ]" : "[FALLÓ]"}');
                    }
                  });

                  final diagnosticoData = {
                    'ingreso_id': idIngreso,
                    'tecnico_id': 1, 
                    'descripcion_falla': fallaCtrl.text.trim(),
                    'posibles_causas': causasCtrl.text.trim().isEmpty ? 'No determinadas' : causasCtrl.text.trim(),
                    'pruebas_realizadas': resumenPruebas.isEmpty ? 'Inspección visual estándar' : resumenPruebas.join(' | '),
                    'conclusiones': conclusionesCtrl.text.trim(),
                    'tiempo_estimado_hrs': double.tryParse(horasCtrl.text) ?? 1.0,
                    'complejidad': complejidadSeleccionada,
                    'estado': 'diagnosticado',
                  };

                  try {
                    final provider = context.read<HelpdeskProvider>();
                    final exito = await provider.agregarDiagnostico(diagnosticoData);

                    if (exito && context.mounted) {
                      // 1. Cerramos el modal inmediatamente
                      Navigator.pop(context);

                      // 2. Notificamos éxito del diagnóstico
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚡ Diagnóstico procesado con éxito.')),
                      );

                      // 3. Subimos la evidencia física amarrada al ingreso (Anti Race-Condition)
                      if (fotoFalla != null) {
                        await provider.asociarDocumentoAEntidad(
                          tipo: 'ingreso', // Vinculamos a 'ingreso' que ya sabemos que existe y tenemos su ID
                          id: idIngreso,
                          rutaLocal: fotoFalla!.path,
                          nombrePersonalizado: 'evidencia_laboratorio_ingreso_$idIngreso.jpg',
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Error en el flujo: $e'), backgroundColor: Colors.redAccent),
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

Widget _campo(TextEditingController ctrl, String label, IconData icono, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icono, color: Colors.tealAccent, size: 18),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent, width: 1)),
      ),
    ),
  );
}