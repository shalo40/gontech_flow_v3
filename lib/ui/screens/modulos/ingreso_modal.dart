import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante para inyectar el provider
import 'package:image_picker/image_picker.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/models/equipo.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import 'equipo_modal.dart';

Future<void> mostrarIngresoModal(BuildContext context, int idCliente) async {
  final equipoDao = EquipoDao();
  final picker = ImagePicker();

  List<Equipo> equiposCliente = await equipoDao.listarPorCliente(idCliente);
  Equipo? equipoSeleccionado;
  File? fotoEquipo;
  final accesoriosCtrl = TextEditingController();
  final obsCtrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          
          Future<void> crearEquipo() async {
            await mostrarEquipoModal(
              context,
              idCliente: idCliente,
              onGuardado: () async {
                final nuevos = await equipoDao.listarPorCliente(idCliente);
                setState(() => equiposCliente = nuevos);
              },
            );
          }

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.assignment_add, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text('Nuevo ingreso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selección de equipo
                    DropdownButtonFormField<Equipo>(
                      value: equipoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Seleccionar equipo',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      dropdownColor: AppColors.fondo,
                      items: equiposCliente.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text('${e.tipo_equipo} • ${e.marca} ${e.modelo}', style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (nuevo) => setState(() => equipoSeleccionado = nuevo),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: crearEquipo,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent),
                        label: const Text('Agregar equipo', style: TextStyle(color: Colors.tealAccent)),
                      ),
                    ),
                    _campo(accesoriosCtrl, 'Accesorios entregados', Icons.cable_rounded),
                    _campo(obsCtrl, 'Observaciones', Icons.notes),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
                onPressed: () async {
                  if (equipoSeleccionado == null) return;

                  // Preparamos el mapa para el Provider (compatible con API y Local)
                  final ingresoData = {
                    'equipo_id': equipoSeleccionado!.id_equipo,
                    'fecha_ingreso': DateTime.now().toIso8601String(),
                    'accesorios': accesoriosCtrl.text.trim(),
                    'observaciones': obsCtrl.text.trim(),
                    'estado_ingreso': 'pendiente',
                  };

                  try {
                    // Usamos el provider en lugar de llamar al DAO directamente
                    final provider = context.read<HelpdeskProvider>();
                    await provider.agregarIngreso(ingresoData);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingreso registrado correctamente ✅')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

Widget _campo(TextEditingController ctrl, String label, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.tealAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
  );
}