import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/models/ingreso.dart';
import '../../../core/models/equipo.dart';
import '../../theme/app_colors.dart';
import 'equipo_modal.dart';

Future<void> mostrarIngresoModal(BuildContext context, int idCliente) async {
  final ingresoDao = IngresoDAO();
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
          Future<void> _seleccionarFoto() async {
            final fuente = await showDialog<ImageSource>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Seleccionar imagen del equipo'),
                content: const Text('¿Desde dónde deseas obtener la foto?'),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Galería'),
                    onPressed: () =>
                        Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            );

            if (fuente == null) return;
            final imagen = await picker.pickImage(
              source: fuente,
              imageQuality: 70,
            );
            if (imagen != null) setState(() => fotoEquipo = File(imagen.path));
          }

          Future<void> _crearEquipo() async {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.assignment_add, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Nuevo ingreso',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🖼️ Foto del equipo
                    GestureDetector(
                      onTap: _seleccionarFoto,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.tealAccent.withOpacity(0.2),
                        backgroundImage: fotoEquipo != null
                            ? FileImage(fotoEquipo!)
                            : null,
                        child: fotoEquipo == null
                            ? const Icon(
                                Icons.add_a_photo,
                                color: Colors.tealAccent,
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🔽 Selección de equipo
                    DropdownButtonFormField<Equipo>(
                      value: equipoSeleccionado,
                      decoration: InputDecoration(
                        labelText: 'Seleccionar equipo del cliente',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: AppColors.fondo,
                      items: equiposCliente.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // 👈 evita overflow
                            children: [
                              if (e.foto_path.isNotEmpty)
                                CircleAvatar(
                                  backgroundImage: FileImage(File(e.foto_path)),
                                  radius: 14,
                                )
                              else
                                const Icon(
                                  Icons.devices,
                                  color: Colors.tealAccent,
                                  size: 18,
                                ),
                              const SizedBox(width: 10),
                              // ✅ sin Flexible
                              Text(
                                '${e.tipo_equipo} • ${e.marca} ${e.modelo}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (nuevo) =>
                          setState(() => equipoSeleccionado = nuevo),
                    ),

                    const SizedBox(height: 8),

                    // ➕ Nuevo equipo
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _crearEquipo,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.tealAccent,
                        ),
                        label: const Text(
                          'Agregar nuevo equipo',
                          style: TextStyle(color: Colors.tealAccent),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    _campo(
                      accesoriosCtrl,
                      'Accesorios entregados',
                      Icons.cable_rounded,
                    ),
                    _campo(obsCtrl, 'Observaciones generales', Icons.notes),
                  ],
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Registrar ingreso'),
                onPressed: () async {
                  if (equipoSeleccionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona o crea un equipo primero'),
                      ),
                    );
                    return;
                  }

                  final nuevo = Ingreso(
                    id_ingreso: null,
                    id_equipo: equipoSeleccionado!.id_equipo!,
                    fecha_ingreso: DateTime.now().toIso8601String(),
                    accesorios: accesoriosCtrl.text.trim(),
                    observaciones: obsCtrl.text.trim(),
                    estado_ingreso: 'pendiente',
                    qr_code: 'mostrarIngresoModal',
                  );

                  try {
                    await ingresoDao.insertar(nuevo);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingreso registrado ✅'),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
    ),
  );
}
