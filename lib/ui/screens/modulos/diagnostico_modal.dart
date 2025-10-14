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
  final conclusionesCtrl = TextEditingController();
  String? tecnicoSeleccionado;
  List<String> pruebasSeleccionadas = [];

  // 🔬 Opciones de pruebas comunes
  final List<String> pruebasDisponibles = [
    'Prueba de encendido',
    'Prueba de voltaje',
    'Prueba de temperatura',
    'Prueba de disco / SSD',
    'Prueba de RAM',
    'Prueba de red / WiFi',
    'Limpieza interna y visual',
    'Revisión BIOS / UEFI',
    'Chequeo periféricos',
  ];

  // 👨‍🔧 Técnicos disponibles (luego vendrá desde usuarios)
  final List<String> tecnicos = [
    'Gonzalo Castillo',
    'Michelle Rivera',
    'Técnico General',
    'Asistente Taller',
  ];

  List<Repuesto> repuestos = [];

  Future<void> cargarRepuestos(int idDiagnosticoTemp) async {
    final data = await repuestoDao.listarPorDiagnostico(idDiagnosticoTemp);
    repuestos = data;
  }

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
              'Registrar diagnóstico',
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
                    fallaCtrl,
                    'Descripción de la falla',
                    Icons.warning_amber_rounded,
                  ),

                  // 🔬 Chips de pruebas seleccionables
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pruebas realizadas:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -8,
                    children: pruebasDisponibles.map((prueba) {
                      final activo = pruebasSeleccionadas.contains(prueba);
                      return FilterChip(
                        label: Text(
                          prueba,
                          style: TextStyle(
                            color: activo ? Colors.black : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        selected: activo,
                        backgroundColor: AppColors.fondo.withOpacity(0.6),
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

                  const SizedBox(height: 12),
                  _campo(
                    conclusionesCtrl,
                    'Conclusiones / resultado',
                    Icons.fact_check_outlined,
                  ),

                  // 👨‍🔧 Selector de técnico
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tecnicoSeleccionado,
                    dropdownColor: AppColors.fondo,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Técnico responsable',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.engineering,
                        color: Colors.tealAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    items: tecnicos.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => tecnicoSeleccionado = val);
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 8),

                  // 🧩 Repuestos sugeridos
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
                          await cargarRepuestos(idIngreso);
                          setState(() {});
                        },
                      ),
                    ],
                  ),

                  // 📋 Lista de repuestos
                  FutureBuilder<List<Repuesto>>(
                    future: repuestoDao.listarPorDiagnostico(idIngreso),
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
                          return Card(
                            color: AppColors.fondo.withOpacity(0.7),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(
                                r.nombre,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Cantidad: ${r.cantidad} | Estado: ${r.estado}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: PopupMenuButton<String>(
                                color: AppColors.fondo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (opcion) async {
                                  if (opcion == 'instalado') {
                                    await repuestoDao.actualizarEstado(
                                      r.id_repuesto!,
                                      'instalado',
                                    );
                                  } else if (opcion == 'eliminar') {
                                    await repuestoDao.eliminar(r.id_repuesto!);
                                  }
                                  await cargarRepuestos(idIngreso);
                                  setState(() {});
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'instalado',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.build,
                                          color: Colors.tealAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Marcar instalado'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_forever,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
                label: const Text('Guardar diagnóstico'),
                onPressed: () async {
                  if (fallaCtrl.text.isEmpty || tecnicoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor completa los campos requeridos',
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
                    id_tecnico: 1, // luego: usuario logueado
                    estado: 'en_revision',
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
                            '✅ Diagnóstico registrado correctamente',
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
