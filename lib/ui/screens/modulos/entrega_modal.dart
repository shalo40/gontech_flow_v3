import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../theme/app_colors.dart';

Future<void> mostrarEntregaModal(BuildContext context) async {
  final observacionesCtrl = TextEditingController();
  final provider = context.read<HelpdeskProvider>();

  // --- Helpers de extracción segura ---
  String getCliente(Map<String, dynamic> r) {
    if (r.containsKey('cliente') && r['cliente'] != null && r['cliente'].toString().isNotEmpty) {
      return r['cliente'].toString();
    }
    if (r['diagnostico'] != null && r['diagnostico']['ingreso'] != null && r['diagnostico']['ingreso']['equipo'] != null && r['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return r['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente desconocido';
    }
    return 'Cliente desconocido';
  }

  int getId(Map<String, dynamic> r) {
    return int.tryParse((r['id_reparacion'] ?? r['id'] ?? '0').toString()) ?? 0;
  }
  // -----------------------------------

  // 🔍 Filtramos directamente desde el Provider las que estén finalizadas
  final reparacionesListas = provider.reparaciones
      .where((r) => r['estado'] == 'finalizada')
      .toList();

  int? idSeleccionado;

  // ⚠️ Si no hay reparaciones disponibles
  if (reparacionesListas.isEmpty) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.fondo.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Sin reparaciones listas',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'No hay reparaciones con estado "finalizada" listas para entregar.',
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
    }
    return;
  }

  // 🧩 Modal de registro de entrega inicial
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
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
                    dropdownColor: AppColors.fondo,
                    value: idSeleccionado,
                    isExpanded: true,
                    items: reparacionesListas.map<DropdownMenuItem<int>>((r) {
                      final cliente = getCliente(r);
                      final idRep = getId(r);
                      return DropdownMenuItem(
                        value: idRep,
                        child: Text(
                          '#$idRep - $cliente',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => idSeleccionado = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.fondo.withOpacity(0.5),
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
                label: const Text('Iniciar entrega'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: idSeleccionado == null
                    ? null
                    : () async {
                        try {
                          final entregaParaLaravel = {
                            'reparacion_id': idSeleccionado,
                            'observaciones': observacionesCtrl.text.trim(),
                            'nombre_receptor': null, // Se llenará en la firma
                            'rut_receptor': null,    // Se llenará en la firma
                            'firma_base64': null,    // Se capturará en el paso de la firma
                            'fecha_entrega': DateTime.now().toIso8601String(),
                            'estado': 'pendiente',
                          };

                          final exito = await provider.procesarEntrega(entregaParaLaravel);
                          
                          if (exito) {
                            // Actualizamos la reparación a entregada para sacarla de la lista
                            await provider.actualizarReparacion(idSeleccionado!, {'estado': 'entregada'});
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📦 Entrega inicializada correctamente'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error al inicializar entrega: $e'),
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