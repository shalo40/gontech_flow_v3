import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/models/equipo.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarEquipoModal(
  BuildContext context, {
  required int idCliente,
  Equipo? equipoExistente,
  required VoidCallback onGuardado,
}) async {
  final dao = EquipoDao();
  final picker = ImagePicker();

  final tipoCtrl = TextEditingController(
    text: equipoExistente?.tipo_equipo ?? '',
  );
  final marcaCtrl = TextEditingController(text: equipoExistente?.marca ?? '');
  final modeloCtrl = TextEditingController(text: equipoExistente?.modelo ?? '');
  final serieCtrl = TextEditingController(
    text: equipoExistente?.numero_serie ?? '',
  );
  final descripcionCtrl = TextEditingController(
    text: equipoExistente?.descripcion ?? '',
  );

  File? fotoSeleccionada;
  final esEdicion = equipoExistente != null;

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
                content: const Text('¿Desde dónde deseas obtener la imagen?'),
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
              imageQuality: 75,
            );
            if (imagen != null)
              setState(() => fotoSeleccionada = File(imagen.path));
          }

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  esEdicion ? Icons.edit : Icons.computer,
                  color: Colors.tealAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  esEdicion ? 'Editar equipo' : 'Registrar nuevo equipo',
                  style: const TextStyle(
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
                    // 🖼️ Imagen del equipo
                    GestureDetector(
                      onTap: _seleccionarFoto,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.tealAccent.withOpacity(0.2),
                        backgroundImage: fotoSeleccionada != null
                            ? FileImage(fotoSeleccionada!)
                            : (equipoExistente?.foto_path.isNotEmpty ?? false)
                            ? FileImage(File(equipoExistente!.foto_path))
                            : null,
                        child:
                            (fotoSeleccionada == null &&
                                (equipoExistente?.foto_path.isEmpty ?? true))
                            ? const Icon(
                                Icons.add_a_photo,
                                color: Colors.tealAccent,
                                size: 36,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _campo(
                      tipoCtrl,
                      'Tipo de equipo (Notebook, PC, Tablet...)',
                      Icons.category,
                    ),
                    _campo(marcaCtrl, 'Marca', Icons.precision_manufacturing),
                    _campo(modeloCtrl, 'Modelo', Icons.memory),
                    _campo(serieCtrl, 'N° de serie', Icons.confirmation_number),
                    _campo(descripcionCtrl, 'Descripción general', Icons.notes),
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
                label: Text(esEdicion ? 'Guardar cambios' : 'Registrar equipo'),
                onPressed: () async {
                  if (tipoCtrl.text.trim().isEmpty ||
                      marcaCtrl.text.trim().isEmpty ||
                      modeloCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, completa los campos obligatorios.',
                        ),
                      ),
                    );
                    return;
                  }

                  final nuevo = Equipo(
                    id_equipo: equipoExistente?.id_equipo,
                    id_cliente: idCliente,
                    tipo_equipo: tipoCtrl.text.trim(),
                    marca: marcaCtrl.text.trim(),
                    modelo: modeloCtrl.text.trim(),
                    numero_serie: serieCtrl.text.trim(),
                    descripcion: descripcionCtrl.text.trim(),
                    foto_path:
                        fotoSeleccionada?.path ??
                        equipoExistente?.foto_path ??
                        '',
                  );

                  if (esEdicion) {
                    await dao.actualizar(nuevo);
                  } else {
                    await dao.insertar(nuevo);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    onGuardado();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          esEdicion
                              ? 'Equipo actualizado ✅'
                              : 'Equipo registrado ✅',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
