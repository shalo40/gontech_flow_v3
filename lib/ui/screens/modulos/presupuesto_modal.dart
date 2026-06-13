import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarPresupuestoModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final descripcionCtrl = TextEditingController();
  final totalCtrl = TextEditingController();
  final provider = context.read<HelpdeskProvider>();

  // 🧩 Ítems del presupuesto
  final List<Map<String, dynamic>> items = [];

  // --- MAGIA AUTOMÁTICA: Auto-fill desde el Diagnóstico ---
  // 1. Buscamos el diagnóstico en la memoria del provider
  final diag = provider.diagnosticos.firstWhere(
    (d) => d['id'] == idDiagnostico || d['id_diagnostico'] == idDiagnostico,
    orElse: () => {},
  );

  // 2. Si existe, extraemos las horas y agregamos la Mano de Obra automáticamente
  if (diag.isNotEmpty) {
    descripcionCtrl.text = 'Reparación según Diagnóstico #${diag['id']}';
    
    // Asumimos un valor base de hora técnica (puedes traer esto de Ajustes después)
    const valorHoraTecnica = 25000.0; // 25.000 CLP por hora
    final horasRaw = diag['tiempo_estimado_hrs']?.toString() ?? '1.0';
    final horasCobrables = double.tryParse(horasRaw) ?? 1.0;
    final costoManoObra = horasCobrables * valorHoraTecnica;

    if (costoManoObra > 0) {
      items.add({
        'nombre': 'Mano de Obra ($horasCobrables hrs)',
        'costo': costoManoObra,
      });
    }

    // Aquí a futuro también puedes auto-agregar los repuestos de este diagnóstico
  }

  void agregarItem(String nombre, double costo) {
    items.add({'nombre': nombre, 'costo': costo});
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // Calculamos el total dinámicamente
          double total = items.fold(0, (sum, item) => sum + (item['costo'] as double? ?? 0.0));

          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.request_quote, color: Colors.tealAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cotización de Laboratorio',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite, // Previene aplastamientos horizontales
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Este presupuesto se basa en el dictamen técnico previo. Ajusta los valores según sea necesario.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // 🧠 Descripción general
                    _campo(descripcionCtrl, 'Resumen para el cliente', Icons.description_outlined, maxLines: 2),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),

                    // 🧩 Ítems individuales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detalle de cobros:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          onPressed: () async {
                            final nombreCtrl = TextEditingController();
                            final costoCtrl = TextEditingController();

                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.fondo.withOpacity(0.95),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: const Text('Agregar cargo', style: TextStyle(color: Colors.white, fontSize: 16)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _campo(nombreCtrl, 'Concepto (Ej: Repuesto)', Icons.edit_outlined),
                                    const SizedBox(height: 8),
                                    _campo(costoCtrl, 'Valor (CLP)', Icons.attach_money, tipo: TextInputType.number),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (nombreCtrl.text.isNotEmpty && costoCtrl.text.isNotEmpty) {
                                        setModalState(() {
                                          agregarItem(nombreCtrl.text, double.tryParse(costoCtrl.text) ?? 0.0);
                                        });
                                        Navigator.pop(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.tealAccent.withOpacity(0.2),
                                      foregroundColor: Colors.tealAccent,
                                      elevation: 0,
                                    ),
                                    child: const Text('Sumar'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 16),
                          label: const Text('Añadir', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                        ),
                      ],
                    ),

                    // Lista de ítems agregados
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150), // Limita altura si hay muchos items
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('Sin ítems a cobrar', style: TextStyle(color: Colors.white54, fontSize: 12))),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(item['nombre'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  trailing: Text(
                                    '\$${item['costo'].toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 18),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),

                    // 💰 Total y Ajuste
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _campo(totalCtrl, 'Cerrar precio manualmente (Opcional)', Icons.calculate, tipo: TextInputType.number),
                  ],
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Emitir Presupuesto', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (descripcionCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Añade un resumen para el cliente.')));
                    return;
                  }

                  final totalFinal = (totalCtrl.text.isNotEmpty) ? double.tryParse(totalCtrl.text) ?? total : total;

                  if (totalFinal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ El presupuesto no puede ser \$0.')));
                    return;
                  }

                  final presupuestoParaLaravel = {
                    'diagnostico_id': idDiagnostico,
                    'descripcion': descripcionCtrl.text.trim(),
                    'total': totalFinal,
                    'estado': 'pendiente', 
                  };

                  try {
                    final exito = await provider.agregarPresupuesto(presupuestoParaLaravel);

                    if (exito && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Presupuesto emitido y listo para revisión del cliente.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.redAccent));
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

Widget _campo(TextEditingController ctrl, String label, IconData icono, {TextInputType tipo = TextInputType.text, int maxLines = 1}) {
  return TextField(
    controller: ctrl,
    keyboardType: tipo,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      prefixIcon: Icon(icono, color: Colors.tealAccent, size: 18),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
    ),
  );
}