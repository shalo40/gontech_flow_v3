import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/usuario.dart';            // ← para dropdown tipado
import '../../theme/app_colors.dart';

Future<void> mostrarDiagnosticoModal(BuildContext context, int idIngreso) async {
  final fallaCtrl        = TextEditingController();
  final causasCtrl       = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  final horasCtrl        = TextEditingController(text: '1.0');
  final picker           = ImagePicker();

  File? fotoFalla;
  // Bug 1: tipado con Usuario en lugar de String
  Usuario? tecnicoSeleccionado;
  String complejidadSeleccionada = 'medio';

  // 🔬 Pruebas con resultado: null = sin marcar, true = OK, false = Falla
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

  Map<String, bool?> estadosPruebas = {
    for (final p in pruebasDisponibles) p: null,
  };

  int    pasoActual   = 0;
  bool   isSubmitting = false;
  String? errorMessage;

  // Lee el ID del técnico autenticado ANTES de abrir el diálogo
  final int? tecnicoIdSesion = context.read<AuthProvider>().idUsuario;

  // Carga técnicos dinámicos antes de mostrar el modal
  final helpdeskProvider = context.read<HelpdeskProvider>();
  await helpdeskProvider.recargarTecnicos();

  // Pre-selecciona el técnico logueado si está en la lista
  if (helpdeskProvider.tecnicos.isNotEmpty) {
    tecnicoSeleccionado = helpdeskProvider.tecnicos.firstWhere(
      (t) => t.idUsuario == tecnicoIdSesion,
      orElse: () => helpdeskProvider.tecnicos.first,
    );
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // ── capturar foto ─────────────────────────────────────────────
          Future<void> capturarFotoFalla() async {
            final XFile? img = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70,
            );
            if (img != null) {
              setModalState(() => fotoFalla = File(img.path));
            }
          }

          // ── Bug 2: validar que el paso actual esté completo ──────────
          String? validarPasoActual() {
            if (pasoActual == 0) {
              if (fallaCtrl.text.trim().isEmpty) {
                return 'Ingresa la falla técnica verificada antes de continuar.';
              }
            }
            // Paso 1 (pruebas) no requiere validación obligatoria
            return null;
          }

          // ── acción del botón por paso ─────────────────────────────────
          void avanzarOValidar() {
            if (pasoActual < 2) {
              final error = validarPasoActual();
              if (error != null) {
                setModalState(() => errorMessage = error);
                return;
              }
              setModalState(() {
                errorMessage = null;
                pasoActual++;
              });
            }
            // En paso 2 el botón "Validar Pasos" solo prepara el estado visual;
            // el guardado real lo ejecuta el ElevatedButton del actions row.
          }

          // ─────────────────────────────────────────────────────────────
          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            // Bug 1: sin insets mínimos para aprovechar todo el ancho
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: const Row(
              children: [
                Icon(Icons.biotech, color: Colors.tealAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asistente de diagnóstico',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              // Bug 1: ancho máximo relativo al viewport, no valor fijo
              width: double.maxFinite,
              child: SingleChildScrollView(
                // Bug 2: padding inferior reactivo al teclado virtual
                // Cuando el teclado sube, empuja el contenido en lugar de desbordarlo
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Bug 4: Banner de error inline
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setModalState(() => errorMessage = null),
                            child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                          ),
                        ],
                      ),
                    ),

                  // Stepper sin SizedBox con ancho fijo
                  Flexible(
                    child: Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Colors.tealAccent.shade400,
                        ),
                      ),
                      child: Stepper(
                        type: StepperType.vertical,
                        currentStep: pasoActual,
                        onStepTapped: (n) => setModalState(() {
                          errorMessage = null;
                          pasoActual = n;
                        }),
                        // Bug 2: onStepContinue delega a avanzarOValidar con validación
                        onStepContinue: avanzarOValidar,
                        onStepCancel: () {
                          if (pasoActual > 0) {
                            setModalState(() {
                              errorMessage = null;
                              pasoActual--;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        // Bug 1 & 2: controlsBuilder responsivo, sin ancho fijo
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                if (pasoActual > 0)
                                  TextButton(
                                    onPressed: details.onStepCancel,
                                    child: const Text(
                                      'Volver',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                const Spacer(), // Bug 1: Spacer en vez de MainAxisAlignment fijo
                                ElevatedButton.icon(
                                  // Bug 2: usa avanzarOValidar en lugar de details.onStepContinue directo
                                  onPressed: avanzarOValidar,
                                  icon: Icon(
                                    pasoActual < 2
                                        ? Icons.navigate_next
                                        : Icons.check_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    pasoActual < 2 ? 'Siguiente' : 'Validar Pasos',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent.withOpacity(0.2),
                                    foregroundColor: Colors.tealAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        steps: [
                          // ── Paso 0: Hallazgos ────────────────────────
                          Step(
                            title: const Text('Hallazgos de Laboratorio'),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _campo(fallaCtrl, 'Falla técnica verificada *', Icons.bug_report, maxLines: 2),
                                const SizedBox(height: 8),
                                _campo(causasCtrl, 'Origen / Causas del daño', Icons.bolt, maxLines: 2),
                              ],
                            ),
                            isActive: pasoActual >= 0,
                            state: pasoActual > 0 ? StepState.complete : StepState.editing,
                          ),

                          // ── Paso 1: Inspección y pruebas ─────────────
                          Step(
                            title: const Text('Inspección y Banco de Pruebas'),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resultado de Testeos:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Bug 1: cada fila de prueba usa Expanded correctamente
                                ...pruebasDisponibles.map((prueba) {
                                  final estado = estadosPruebas[prueba];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            prueba,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        // Botones de resultado compactos
                                        SizedBox(
                                          width: 72,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => setModalState(
                                                  () => estadosPruebas[prueba] = true,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: estado == true
                                                      ? Colors.green
                                                      : Colors.white24,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => setModalState(
                                                  () => estadosPruebas[prueba] = false,
                                                ),
                                                child: Icon(
                                                  Icons.cancel,
                                                  color: estado == false
                                                      ? Colors.redAccent
                                                      : Colors.white24,
                                                  size: 22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(color: Colors.white24, height: 20),

                                // Bug 1: zona de foto con width: double.infinity sin Row externo
                                const Text(
                                  'Evidencia del daño (Foto interna)',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: capturarFotoFalla,
                                  child: Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: fotoFalla != null
                                            ? Colors.tealAccent
                                            : Colors.white24,
                                      ),
                                    ),
                                    child: fotoFalla != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.file(fotoFalla!, fit: BoxFit.cover),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo_outlined,
                                                color: Colors.tealAccent,
                                                size: 26,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Capturar componente dañado',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            isActive: pasoActual >= 1,
                            state: pasoActual > 1 ? StepState.complete : StepState.editing,
                          ),

                          // ── Paso 2: Estimación ────────────────────────
                          Step(
                            title: const Text('Estimación y Complejidad'),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _campo(
                                  conclusionesCtrl,
                                  'Dictamen final / Solución recomendada *',
                                  Icons.gavel_rounded,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 10),
                                _campo(
                                  horasCtrl,
                                  'Horas de Mano de Obra (Ej: 1.5)',
                                  Icons.hourglass_top,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                // Bug 1: DropdownButtonFormField ocupa el ancho completo sin Row
                                DropdownButtonFormField<String>(
                                  value: complejidadSeleccionada,
                                  dropdownColor: AppColors.fondo,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Riesgo / Complejidad',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(
                                      Icons.equalizer,
                                      color: Colors.tealAccent,
                                      size: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: ['bajo', 'medio', 'alto', 'critico'].map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(c.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setModalState(() => complejidadSeleccionada = val!),
                                ),
                                const SizedBox(height: 12),
                                // Bug 1: Dropdown dinámico con objetos Usuario reales
                                DropdownButtonFormField<Usuario?>(
                                  value: tecnicoSeleccionado,
                                  dropdownColor: AppColors.fondo,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Técnico asignado',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(
                                      Icons.engineering,
                                      color: Colors.tealAccent,
                                      size: 18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    // Aviso visual si la API no devolvió técnicos
                                    helperText: context.watch<HelpdeskProvider>().tecnicos.isEmpty
                                        ? '⚠️ Sin conexión: no se pudieron cargar los técnicos'
                                        : null,
                                    helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
                                  ),
                                  // value = objeto Usuario; texto visible = nombre
                                  items: context.watch<HelpdeskProvider>().tecnicos.map((t) {
                                    return DropdownMenuItem<Usuario?>(
                                      value: t,
                                      child: Text(t.nombre),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setModalState(() => tecnicoSeleccionado = val),
                                ),
                              ],
                            ),
                            isActive: pasoActual >= 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),   // SingleChildScrollView
            ),

            // ── Barra de acciones ─────────────────────────────────────
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.save_as_outlined),
                label: Text(isSubmitting ? 'Guardando...' : 'Guardar diagnóstico'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        // Validación final antes de enviar
                        if (fallaCtrl.text.trim().isEmpty ||
                            conclusionesCtrl.text.trim().isEmpty) {
                          setModalState(() {
                            errorMessage =
                                '⚠️ Completa la Falla técnica y el Dictamen final antes de guardar.';
                          });
                          return;
                        }

                        // Construir resumen de pruebas
                        final resumenPruebas = estadosPruebas.entries
                            .where((e) => e.value != null)
                            .map((e) =>
                                '${e.key}: ${e.value! ? "[PASÓ]" : "[FALLÓ]"}')
                            .join(' | ');

                        // Bug 2: payload limpio sin fechas en formato ISO8601
                        // 'creado_en' se elimina — MySQL usa DEFAULT CURRENT_TIMESTAMP
                        final diagnosticoData = {
                          'id_ingreso'        : idIngreso,
                          // Bug 1: ID entero real del objeto Usuario seleccionado
                          'tecnico_id'        : tecnicoSeleccionado?.idUsuario,
                          'descripcion_falla' : fallaCtrl.text.trim(),
                          'posibles_causas'   : causasCtrl.text.trim().isEmpty
                              ? 'No determinadas'
                              : causasCtrl.text.trim(),
                          'pruebas_realizadas': resumenPruebas.isEmpty
                              ? 'Inspección visual estándar'
                              : resumenPruebas,
                          'conclusiones'      : conclusionesCtrl.text.trim(),
                          'tiempo_estimado_hrs': double.tryParse(horasCtrl.text) ?? 1.0,
                          'complejidad'       : complejidadSeleccionada,
                          'estado'            : 'diagnosticado',
                        };

                        try {
                          setModalState(() {
                            isSubmitting  = true;
                            errorMessage  = null;
                          });

                          final provider = context.read<HelpdeskProvider>();
                          final exito =
                              await provider.agregarDiagnostico(diagnosticoData);

                          if (exito && context.mounted) {
                            Navigator.pop(context);

                            // SnackBar de éxito es seguro: el modal ya cerró
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚡ Diagnóstico registrado con éxito.'),
                                backgroundColor: Colors.teal,
                              ),
                            );

                            // Subida de evidencia post-cierre (sin race condition)
                            if (fotoFalla != null) {
                              await provider.asociarDocumentoAEntidad(
                                tipo: 'ingreso',
                                id: idIngreso,
                                rutaLocal: fotoFalla!.path,
                                nombrePersonalizado:
                                    'evidencia_laboratorio_ingreso_$idIngreso.jpg',
                              );
                            }
                          }
                        } catch (e) {
                          // Bug 4: error visible dentro del modal, no detrás de él
                          setModalState(() {
                            isSubmitting = false;
                            errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
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

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _campo(
  TextEditingController ctrl,
  String label,
  IconData icono, {
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) {
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent, width: 1),
        ),
      ),
    ),
  );
}