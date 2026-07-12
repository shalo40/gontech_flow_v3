import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:image_picker/image_picker.dart';
import '../../../core/models/equipo.dart';
import '../../../core/providers/helpdesk_provider.dart'; 
import '../../theme/app_colors.dart';

Future<bool?> mostrarEquipoModal(
  BuildContext context, {
  required int idCliente,
  Equipo? equipoExistente,
  VoidCallback? onGuardado, // Lo hacemos opcional para usarlo desde IngresoModal sin problemas
}) async {
  final picker = ImagePicker();

  final marcaCtrl = TextEditingController(text: equipoExistente?.marca ?? '');
  final modeloCtrl = TextEditingController(text: equipoExistente?.modelo ?? '');
  final serieCtrl = TextEditingController(
    text: equipoExistente?.numero_serie ?? '',
  );
  final descripcionCtrl = TextEditingController(
    text: equipoExistente?.descripcion ?? '',
  );

  // 📝 Configuración del selector de Tipo de Equipo
  final tiposEquipos = [
    'Notebook',
    'PC de Escritorio',
    'All-in-One',
    'Tablet',
    'Smartphone',
    'Impresora',
    'Consola',
    'Otro'
  ];
  
  // Validamos si el equipo existente tiene un tipo válido o asignamos un default
  String tipoSeleccionado = 'Notebook';
  if (equipoExistente != null && tiposEquipos.contains(equipoExistente.tipo_equipo)) {
    tipoSeleccionado = equipoExistente.tipo_equipo;
  } else if (equipoExistente != null && (equipoExistente.tipo_equipo.isNotEmpty)) {
    // Si viene un tipo raro desde BD que no está en la lista, lo agregamos temporalmente para evitar crash visual
    tiposEquipos.add(equipoExistente.tipo_equipo);
    tipoSeleccionado = equipoExistente.tipo_equipo;
  }

  File? fotoSeleccionada;
  final esEdicion = equipoExistente != null;
  bool isSubmitting = false;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> seleccionarFoto() async {
            final fuente = await showDialog<ImageSource>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.fondo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Seleccionar imagen del equipo', style: TextStyle(color: Colors.white)),
                content: const Text('¿Desde dónde deseas obtener la imagen?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.tealAccent),
                    label: const Text('Cámara', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.photo, color: Colors.tealAccent),
                    label: const Text('Galería', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(context, ImageSource.gallery),
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
                Expanded(
                  child: Text(
                    esEdicion ? 'Editar equipo' : 'Registrar nuevo equipo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      onTap: seleccionarFoto,
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

                    // 🔽 Selector de Tipo de Equipo
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      dropdownColor: AppColors.fondo,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category, color: Colors.tealAccent),
                        labelText: 'Tipo de equipo',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: tiposEquipos.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => tipoSeleccionado = val);
                      },
                    ),
                    const SizedBox(height: 6), // Espaciador para alinear con los campos de texto

                    _campo(marcaCtrl, 'Marca', Icons.precision_manufacturing),
                    _campo(modeloCtrl, 'Modelo', Icons.memory),
                    _campo(serieCtrl, 'N° de serie (Opcional)', Icons.confirmation_number),
                    _campo(descripcionCtrl, 'Descripción general', Icons.notes, maxLines: 2),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false), // ❌ Retorna false al cancelar
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                label: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent.withOpacity(0.2),
                  foregroundColor: Colors.tealAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                label: Text(isSubmitting ? 'Guardando...' : (esEdicion ? 'Guardar cambios' : 'Registrar equipo')),
                onPressed: isSubmitting ? null : () async {
                  if (marcaCtrl.text.trim().isEmpty || modeloCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, la Marca y Modelo son obligatorios.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Preparamos el mapa exacto que Laravel espera
                  final equipoParaLaravel = {
                    'cliente_id': idCliente,
                    'id_cliente': idCliente, // Fallback por si SQLite lo requiere localmente
                    'tipo_equipo': tipoSeleccionado,
                    'marca': marcaCtrl.text.trim(),
                    'modelo': modeloCtrl.text.trim(),
                    'numero_serie': serieCtrl.text.trim(),
                    'descripcion': descripcionCtrl.text.trim(),
                    'foto_path': fotoSeleccionada?.path ?? equipoExistente?.foto_path ?? '',
                  };

                  try {
                    setState(() => isSubmitting = true);
                    final provider = context.read<HelpdeskProvider>();

                    if (esEdicion) {
                      await provider.actualizarEquipo(equipoExistente.id_equipo!, equipoParaLaravel);
                    } else {
                      await provider.agregarEquipo(equipoParaLaravel);
                    }

                    if (context.mounted) {
                      Navigator.pop(context, true); // ✅ Retorna true indicando éxito
                      if (onGuardado != null) onGuardado(); // Llama al callback si existe
                      
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
                  } catch (e) {
                    setState(() => isSubmitting = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.redAccent,
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