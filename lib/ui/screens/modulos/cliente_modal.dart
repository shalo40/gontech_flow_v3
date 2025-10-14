import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import '../../../core/dao/cliente_dao.dart';
import '../../../core/models/cliente.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarClienteModal(
  BuildContext context, {
  Cliente? clienteExistente,
  required VoidCallback onGuardado,
}) async {
  final dao = ClienteDao();
  final picker = img_picker.ImagePicker();

  final nombreCtrl = TextEditingController(
    text: clienteExistente?.nombre ?? '',
  );
  final telefonoCtrl = TextEditingController(
    text: clienteExistente?.telefono ?? '',
  );
  final correoCtrl = TextEditingController(
    text: clienteExistente?.correo ?? '',
  );
  final direccionCtrl = TextEditingController(
    text: clienteExistente?.direccion ?? '',
  );
  final notasCtrl = TextEditingController(text: clienteExistente?.notas ?? '');

  File? fotoSeleccionada = clienteExistente?.foto_path.isNotEmpty == true
      ? File(clienteExistente!.foto_path)
      : null;

  final esEdicion = clienteExistente != null;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> seleccionarFoto() async {
            final fuente = await showDialog<img_picker.ImageSource>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.fondo.withOpacity(0.95),
                title: const Text(
                  'Seleccionar foto',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '¿Desde dónde deseas obtener la imagen?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, img_picker.ImageSource.camera),
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.tealAccent,
                    ),
                    label: const Text('Cámara'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, img_picker.ImageSource.gallery),
                    icon: const Icon(Icons.photo, color: Colors.tealAccent),
                    label: const Text('Galería'),
                  ),
                ],
              ),
            );

            if (fuente == null) return;

            final imagen = await picker.pickImage(
              source: fuente,
              imageQuality: 75,
            );
            if (imagen != null) {
              setState(() => fotoSeleccionada = File(imagen.path));
            }
          }

          Future<void> guardarCliente() async {
            if (nombreCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ El nombre del cliente es obligatorio'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            final nuevo = Cliente(
              id_cliente: clienteExistente?.id_cliente,
              nombre: nombreCtrl.text.trim(),
              telefono: telefonoCtrl.text.trim(),
              correo: correoCtrl.text.trim(),
              direccion: direccionCtrl.text.trim(),
              notas: notasCtrl.text.trim(),
              foto_path:
                  fotoSeleccionada?.path ?? clienteExistente?.foto_path ?? '',
            );

            try {
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
                          ? 'Cliente actualizado correctamente ✅'
                          : 'Cliente creado correctamente ✅',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error al guardar cliente: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.97),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: Row(
              children: [
                Icon(
                  esEdicion ? Icons.edit : Icons.person_add_alt_1,
                  color: Colors.tealAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  esEdicion ? 'Editar cliente' : 'Nuevo cliente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                    const SizedBox(height: 10),
                    // 🖼️ Foto circular interactiva
                    GestureDetector(
                      onTap: seleccionarFoto,
                      child: Hero(
                        tag: clienteExistente?.id_cliente ?? 'nuevo_cliente',
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.tealAccent.withOpacity(0.15),
                          backgroundImage: fotoSeleccionada != null
                              ? FileImage(fotoSeleccionada!)
                              : null,
                          child: fotoSeleccionada == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  color: Colors.tealAccent,
                                  size: 34,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Campos
                    _campo(nombreCtrl, 'Nombre completo', Icons.person),
                    _campo(telefonoCtrl, 'Teléfono', Icons.phone),
                    _campo(
                      correoCtrl,
                      'Correo electrónico',
                      Icons.email_outlined,
                    ),
                    _campo(direccionCtrl, 'Dirección', Icons.home_outlined),
                    _campo(notasCtrl, 'Notas / comentarios', Icons.notes),
                  ],
                ),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: Text(esEdicion ? 'Guardar cambios' : 'Crear cliente'),
                onPressed: guardarCliente,
              ),
            ],
          );
        },
      );
    },
  );
}

/// Campo de texto reutilizable con estilo
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
