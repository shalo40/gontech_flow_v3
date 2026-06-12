import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../theme/app_colors.dart';

Future<void> mostrarPresupuestoModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final descripcionCtrl = TextEditingController();
  final totalCtrl = TextEditingController();

  // 🧩 Ítems del presupuesto (simples por ahora)
  final List<Map<String, dynamic>> items = [];

  void agregarItem(String nombre, double costo) {
    items.add({'nombre': nombre, 'costo': costo});
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          double total = items.fold(
            0,
            (sum, item) => sum + (item['costo'] as double? ?? 0.0),
          );

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: const [
                Icon(Icons.request_quote, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Nuevo presupuesto técnico',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Este presupuesto se basa en el diagnóstico técnico realizado.\n'
                    'Asegúrate de detallar correctamente los trabajos y costos estimados.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // 🧠 Descripción general
                  _campo(
                    descripcionCtrl,
                    'Descripción general del trabajo',
                    Icons.description_outlined,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),

                  // 🧩 Ítems individuales
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Detalles de presupuesto:',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lista de ítems agregados
                  items.isEmpty
                      ? const Text(
                          'Sin ítems agregados',
                          style: TextStyle(color: Colors.white54),
                        )
                      : Column(
                          children: items.map((item) {
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                item['nombre'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                '\$${item['costo'].toStringAsFixed(0)} CLP',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: const Icon(
                                Icons.build_circle_outlined,
                                color: Colors.tealAccent,
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final nombreCtrl = TextEditingController();
                        final costoCtrl = TextEditingController();

                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.fondo.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: const Text(
                              'Agregar ítem',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _campo(
                                  nombreCtrl,
                                  'Nombre del ítem',
                                  Icons.edit_outlined,
                                ),
                                _campo(
                                  costoCtrl,
                                  'Costo estimado (CLP)',
                                  Icons.attach_money,
                                  tipo: TextInputType.number,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (nombreCtrl.text.isNotEmpty &&
                                      costoCtrl.text.isNotEmpty) {
                                    agregarItem(
                                      nombreCtrl.text,
                                      double.tryParse(costoCtrl.text) ?? 0.0,
                                    );
                                    setState(() {});
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent
                                      .withOpacity(0.2),
                                  foregroundColor: Colors.tealAccent,
                                ),
                                child: const Text('Agregar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.tealAccent,
                      ),
                      label: const Text(
                        'Agregar ítem',
                        style: TextStyle(color: Colors.tealAccent),
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white24),

                  // 💰 Total calculado automáticamente
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total estimado:  \$${total.toStringAsFixed(0)} CLP',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Campo de total manual opcional
                  _campo(
                    totalCtrl,
                    'Ajuste manual del total (opcional)',
                    Icons.calculate,
                    tipo: TextInputType.number,
                  ),
                ],
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Guardar presupuesto'),
                onPressed: () async {
                  if (descripcionCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa la descripción antes de guardar',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  final totalFinal = (totalCtrl.text.isNotEmpty)
                      ? double.tryParse(totalCtrl.text) ?? total
                      : total;

                  // Empaquetamos para Laravel
                  final presupuestoParaLaravel = {
                    'diagnostico_id': idDiagnostico,
                    'descripcion': descripcionCtrl.text.trim(),
                    'total': totalFinal,
                    'estado': 'pendiente',
                    'fecha_creacion': DateTime.now().toIso8601String(),
                  };

                  try {
                    final provider = context.read<HelpdeskProvider>();
                    final exito = await provider.agregarPresupuesto(presupuestoParaLaravel);

                    if (exito && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Presupuesto creado correctamente'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error al guardar: $e'),
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

Widget _campo(
  TextEditingController ctrl,
  String label,
  IconData icono, {
  TextInputType tipo = TextInputType.text,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      keyboardType: tipo,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icono, color: Colors.tealAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
    ),
  );
}