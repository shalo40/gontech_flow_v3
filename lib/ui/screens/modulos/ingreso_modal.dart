import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:image_picker/image_picker.dart'; 
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import 'equipo_modal.dart';

Future<void> mostrarIngresoModal(BuildContext context, int idCliente) async {
  // 1. Forzamos la recarga ANTES de abrir el modal para garantizar que el desplegable tenga datos
  final providerInicial = context.read<HelpdeskProvider>();
  await providerInicial.recargarEquipos();

  final motivoCtrl = TextEditingController(); // <-- ¡NUEVO! Para la falla principal
  final obsCtrl = TextEditingController();    // Para el estado físico (rayones, etc)
  final accesoriosExtraCtrl = TextEditingController();
  final picker = ImagePicker();
  
  int? idEquipoSeleccionado;
  File? fotoEvidencia; 
  bool isSubmitting = false;

  final opcionesAccesorios = [
    'Cargador', 'Cable USB', 'Funda / Estuche', 'Mouse', 'Teclado', 'Bolso'
  ];
  List<String> accesoriosSeleccionados = [];

  int getId(Map<String, dynamic> e) {
    return int.tryParse((e['id_equipo'] ?? e['id'] ?? '0').toString()) ?? 0;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final provider = context.watch<HelpdeskProvider>();
          
          final equiposCliente = provider.equipos.where((e) {
            final eIdCliente = int.tryParse((e['id_cliente'] ?? e['cliente_id'] ?? '0').toString()) ?? 0;
            return eIdCliente == idCliente;
          }).toList();

          Future<void> capturarEvidencia() async {
            final XFile? imagen = await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 70, 
            );
            if (imagen != null) {
              setModalState(() => fotoEvidencia = File(imagen.path));
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.assignment_add, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Nuevo ingreso técnico', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- FOTO DE RECEPCIÓN ---
                    const Text('Estado de recepción (Foto)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: capturarEvidencia,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: fotoEvidencia != null ? Colors.tealAccent : Colors.white24,
                            ),
                          ),
                          child: fotoEvidencia != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Image.file(fotoEvidencia!, fit: BoxFit.cover),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.tealAccent, size: 32),
                                    SizedBox(height: 6),
                                    Text('Capturar estado del equipo', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- SELECCIÓN DE EQUIPO CON PROTECCIÓN CONTRA LISTAS VACÍAS ---
                    if (equiposCliente.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'El cliente no tiene equipos registrados. Haz clic en "Agregar equipo" para comenzar.',
                                style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        value: idEquipoSeleccionado,
                        dropdownColor: AppColors.fondo,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.devices, color: Colors.tealAccent),
                          labelText: 'Seleccionar equipo',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        items: equiposCliente.map((e) {
                          final id = getId(e);
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${e['tipo_equipo'] ?? 'Equipo'} • ${e['marca'] ?? ''} ${e['modelo'] ?? ''}', 
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (nuevoId) => setModalState(() => idEquipoSeleccionado = nuevoId),
                      ),
                    const SizedBox(height: 4),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final equipoCreado = await mostrarEquipoModal(context, idCliente: idCliente);
                          if (equipoCreado == true) {
                            await provider.recargarEquipos();
                            final actualizados = provider.equipos.where((e) {
                              final eIdCliente = int.tryParse((e['id_cliente'] ?? e['cliente_id'] ?? '0').toString()) ?? 0;
                              return eIdCliente == idCliente;
                            }).toList();

                            if (actualizados.isNotEmpty) {
                              setModalState(() {
                                // Selecciona el primero de la lista (el más reciente devuelto por Laravel)
                                idEquipoSeleccionado = getId(actualizados.first);
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 18),
                        label: const Text('Agregar equipo', style: TextStyle(color: Colors.tealAccent)),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 10),

                    // --- EL PROBLEMA / MOTIVO DEL INGRESO ---
                    _campo(motivoCtrl, 'Falla reportada / Motivo del ingreso', Icons.report_problem, maxLines: 2),
                    const SizedBox(height: 8),

                    // --- CHIPS DE ACCESORIOS ---
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('Accesorios entregados', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: opcionesAccesorios.map((accesorio) {
                        final isSelected = accesoriosSeleccionados.contains(accesorio);
                        return FilterChip(
                          label: Text(accesorio),
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
                          selected: isSelected,
                          selectedColor: Colors.tealAccent,
                          backgroundColor: Colors.black26,
                          checkmarkColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: isSelected ? Colors.tealAccent : Colors.white24),
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                accesoriosSeleccionados.add(accesorio);
                              } else {
                                accesoriosSeleccionados.remove(accesorio);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _campo(accesoriosExtraCtrl, 'Otros accesorios (Opcional)', Icons.cable_rounded),
                    
                    // --- OBSERVACIONES FÍSICAS ---
                    _campo(obsCtrl, 'Estado físico (Rayones, golpes, etc.)', Icons.search, maxLines: 2),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                label: const Text('Cancelar', style: TextStyle(color: Colors.white70))
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.2),
                  foregroundColor: Colors.tealAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.tealAccent,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isSubmitting ? 'Guardando...' : 'Registrar'),
                onPressed: isSubmitting ? null : () async {
                  if (idEquipoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ Selecciona un equipo para el ingreso.')),
                    );
                    return;
                  }
                  
                  if (motivoCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ Debes ingresar la falla o motivo reportado.')),
                    );
                    return;
                  }

                  List<String> totalAccesorios = List.from(accesoriosSeleccionados);
                  if (accesoriosExtraCtrl.text.trim().isNotEmpty) {
                    totalAccesorios.add(accesoriosExtraCtrl.text.trim());
                  }

                  // Fusionamos el motivo y el estado físico para mandarlo en la columna "observaciones"
                  final motivoFalla = motivoCtrl.text.trim();
                  final estadoFisico = obsCtrl.text.trim().isEmpty ? 'Sin detalles físicos' : obsCtrl.text.trim();
                  final observacionesCombinadas = 'FALLA REPORTADA:\n$motivoFalla\n\nESTADO FÍSICO:\n$estadoFisico';

                  // Bug 1: fecha en formato MySQL estricto (yyyy-MM-dd HH:mm:ss)
                  // toIso8601String() produce '2026-07-12T...' que MySQL DATETIME rechaza.
                  final now = DateTime.now();
                  final fechaMysql =
                      '${now.year.toString().padLeft(4, '0')}-'
                      '${now.month.toString().padLeft(2, '0')}-'
                      '${now.day.toString().padLeft(2, '0')} '
                      '${now.hour.toString().padLeft(2, '0')}:'
                      '${now.minute.toString().padLeft(2, '0')}:'
                      '${now.second.toString().padLeft(2, '0')}';

                  final ingresoData = {
                    'equipo_id'            : idEquipoSeleccionado,
                    'id_equipo'            : idEquipoSeleccionado,
                    'fecha_ingreso'        : fechaMysql,   // ← 'yyyy-MM-dd HH:mm:ss'
                    'accesorios_entregados': totalAccesorios.join(', '),
                    'accesorios'           : totalAccesorios.join(', '),
                    'observaciones'        : observacionesCombinadas,
                    'estado_ingreso'       : 'pendiente',
                    'estado'               : 'pendiente',
                  };

                  try {
                    setModalState(() => isSubmitting = true);
                    final exito = await provider.agregarIngreso(ingresoData);

                    if (exito && context.mounted) {
                      final idNuevoIngreso = getId(provider.ingresos.first);

                      if (fotoEvidencia != null) {
                        await provider.asociarDocumentoAEntidad(
                          tipo: 'ingreso',
                          id: idNuevoIngreso,
                          rutaLocal: fotoEvidencia!.path,
                          nombrePersonalizado: 'evidencia_ingreso_$idNuevoIngreso.jpg',
                        );
                      }

                      Navigator.pop(context);

                      // if (context.mounted) {
                      //   await mostrarFirmaModal(context, idNuevoIngreso, 'ingreso' as Map<String, dynamic>, () {});
                      // }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('📥 ¡Ingreso registrado!'),
                            action: SnackBarAction(
                              label: 'VER COMPROBANTE',
                              textColor: Colors.tealAccent,
                              onPressed: () {},
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
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

Widget _campo(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.tealAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
      ),
    ),
  );
}