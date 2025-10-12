import 'package:flutter/material.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/models/ingreso.dart';
import '../../../core/models/equipo.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarIngresoModal(BuildContext context, int i) async {
  final ingresoDao = IngresoDao();
  final equipoDao = EquipoDao();

  final accesoriosCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  List<Equipo> equipos = [];
  Equipo? equipoSeleccionado;

  // Cargar equipos existentes desde la BD
  equipos = await equipoDao.listar();

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
              'Registrar nuevo ingreso',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selección del equipo
                  DropdownButtonFormField<Equipo>(
                    dropdownColor: AppColors.fondo,
                    value: equipoSeleccionado,
                    items: equipos.map((e) {
                      return DropdownMenuItem<Equipo>(
                        value: e,
                        child: Text(
                          '${e.tipo_equipo} - ${e.marca} (${e.modelo})',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (nuevo) {
                      setState(() => equipoSeleccionado = nuevo);
                    },
                    decoration: InputDecoration(
                      labelText: 'Equipo',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.devices,
                        color: Colors.tealAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 12),

                  // Accesorios con chips sugeridos
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      children:
                          [
                            'Cargador',
                            'Mochila',
                            'Mouse',
                            'Cable USB',
                            'Adaptador',
                          ].map((item) {
                            return FilterChip(
                              label: Text(item),
                              labelStyle: const TextStyle(color: Colors.white),
                              selectedColor: Colors.tealAccent.withOpacity(0.3),
                              backgroundColor: Colors.white10,
                              selected: accesoriosCtrl.text.contains(item),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    accesoriosCtrl.text +=
                                        (accesoriosCtrl.text.isEmpty
                                            ? ''
                                            : ', ') +
                                        item;
                                  } else {
                                    accesoriosCtrl.text = accesoriosCtrl.text
                                        .replaceAll(item, '')
                                        .replaceAll(',,', ',')
                                        .trim()
                                        .replaceAll(RegExp(r'(^, |, $)'), '');
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Observaciones
                  TextField(
                    controller: observacionesCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.note_alt,
                        color: Colors.tealAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
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
                label: const Text('Guardar ingreso'),
                onPressed: () async {
                  if (equipoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor selecciona un equipo'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final nuevo = Ingreso(
                    id_equipo: equipoSeleccionado!.id_equipo!,
                    fecha_ingreso: DateTime.now().toIso8601String(),
                    accesorios: accesoriosCtrl.text.trim(),
                    observaciones: observacionesCtrl.text.trim(),
                    estado_ingreso: 'pendiente',
                  );

                  try {
                    await ingresoDao.insertar(nuevo);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Ingreso registrado correctamente'),
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
