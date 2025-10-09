import 'package:flutter/material.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/ingreso.dart';
import '../../theme/app_colors.dart';
import 'equipo_modal.dart'; // 👈 Importa aquí

Future<void> mostrarIngresoModal(BuildContext context, [int? idCliente]) async {
  final equipoDao = EquipoDao();
  final ingresoDao = IngresoDao();

  final equipos = await equipoDao.listarPorCliente(idCliente!);
  int? equipoSeleccionado;
  final accesoriosCtrl = TextEditingController();
  final obsCtrl = TextEditingController();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Registrar ingreso',
        style: TextStyle(color: Colors.white),
      ),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: equipoSeleccionado,
                items: [
                  ...equipos.map(
                    (e) => DropdownMenuItem(
                      value: e.id_equipo,
                      child: Text(
                        '${e.tipo_equipo} ${e.marca} (${e.modelo})',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('➕ Crear nuevo equipo'),
                  ),
                ],
                dropdownColor: AppColors.fondo,
                decoration: const InputDecoration(
                  labelText: 'Equipo',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) async {
                  if (val == -1) {
                    // Abrir modal de equipo
                    final nuevoId = await mostrarEquipoModal(
                      context,
                      idCliente,
                    );
                    if (nuevoId != null) {
                      final listaActualizada = await equipoDao.listarPorCliente(
                        idCliente,
                      );
                      setState(() {
                        equipoSeleccionado = nuevoId;
                        equipos.clear();
                        equipos.addAll(listaActualizada);
                      });
                    }
                  } else {
                    setState(() => equipoSeleccionado = val);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accesoriosCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Accesorios',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: obsCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (equipoSeleccionado == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debe seleccionar o crear un equipo.'),
                ),
              );
              return;
            }

            final ingreso = Ingreso(
              id_equipo: equipoSeleccionado!,
              fecha_ingreso: DateTime.now().toIso8601String(),
              accesorios: accesoriosCtrl.text,
              observaciones: obsCtrl.text,
              estado_ingreso: 'pendiente',
            );

            await ingresoDao.insertar(ingreso);
            if (context.mounted) Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ingreso registrado correctamente')),
            );
          },
          child: const Text('Guardar ingreso'),
        ),
      ],
    ),
  );
}
