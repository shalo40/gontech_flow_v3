import 'package:flutter/material.dart';
import '../../../core/dao/reparacion_dao.dart';
import '../../../core/dao/entrega_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/entrega.dart';

Future<void> mostrarEntregaModal(BuildContext context) async {
  final observacionesCtrl = TextEditingController();
  final entregaDao = EntregaDao();
  final ingresoDao = IngresoDAO();
  final reparacionDao = ReparacionDao();

  // 🔍 Reparaciones listas para entrega (estado: en_proceso o listo)
  final reparaciones = await reparacionDao.listarDetallado();
  final reparacionesListas = reparaciones
      .where((r) => r['estado'] == 'en_proceso' || r['estado'] == 'listo')
      .toList();

  int? idSeleccionado;

  // ⚠️ Si no hay reparaciones disponibles
  if (reparacionesListas.isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sin reparaciones listas',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'No hay reparaciones con estado "en proceso" o "listo" para entregar.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
    return;
  }

  // 🧩 Modal de registro de entrega
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Registrar Entrega',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccione una reparación lista para entregar:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  // 🔽 Lista de reparaciones disponibles
                  DropdownButtonFormField<int>(
                    dropdownColor: const Color(0xFF2A2A3D),
                    value: idSeleccionado,
                    items: reparacionesListas.map<DropdownMenuItem<int>>((r) {
                      return DropdownMenuItem(
                        value: r['id_reparacion'] as int,
                        child: Text(
                          '${r['descripcion'] ?? 'Reparación sin descripción'} — Estado: ${r['estado']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => idSeleccionado = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2A2A3D),
                      hintText: 'Seleccione reparación',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: observacionesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones finales',
                      labelStyle: TextStyle(color: Colors.white70),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.done_all, color: Colors.black),
                label: const Text('Confirmar entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: idSeleccionado == null
                    ? null
                    : () async {
                        try {
                          final entrega = Entrega(
                            id_reparacion: idSeleccionado!,
                            observaciones: observacionesCtrl.text,
                            firma_path: '',
                            nombre_receptor: '',
                            rut_receptor: '',
                            fecha_entrega: DateTime.now().toIso8601String(),
                            estado: 'pendiente', // estado inicial
                          );

                          await entregaDao.insertar(entrega);

                          // Cambiar el estado del ingreso vinculado
                          await ingresoDao.actualizarEstadoDesdeReparacion(
                            idSeleccionado!,
                            'finalizado',
                          );

                          if (context.mounted) Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📦 Entrega registrada correctamente',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al registrar entrega: $e'),
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
