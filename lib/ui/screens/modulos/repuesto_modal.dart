import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

Future<void> mostrarRepuestoModal({
  required BuildContext context,
  required int idReferencia, // Generalmente el id_diagnostico o id_reparacion
  required String origen,
}) async {
  final nombreCtrl = TextEditingController();
  final proveedorCtrl = TextEditingController();
  final costoCtrl = TextEditingController();
  final cantidadCtrl = TextEditingController(text: '1');

  // Controladores de estado del Modal
  bool esDeBodega = true;
  String? itemBodegaSeleccionado;

  // 📦 MOCK DE BODEGA: Hasta que hagamos el módulo real de almacenamiento,
  // usaremos esta lista precargada. Luego esto vendrá del HelpdeskProvider.
  final List<String> inventarioBodega = [
    'Pasta Térmica Arctic MX-4',
    'Flex de carga genérico Tipo-C',
    'Alcohol Isopropílico (Insumo)',
    'Disco SSD Kingston 500GB',
    'Memoria RAM DDR4 8GB genérica',
    'Cinta Kapton / Térmica',
  ];

  await showDialog(
    context: context,
    barrierDismissible: false, // Obliga a usar los botones para salir
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.fondo.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.tealAccent.withOpacity(0.2)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            // ✅ SOLUCIÓN AL OVERFLOW: Fila estructurada
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.build_circle, color: Colors.tealAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Añadir Insumo',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView( // ✅ SOLUCIÓN AL OVERFLOW VERTICAL
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎚️ SWITCH INTELIGENTE: Bodega vs Compra Específica
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => esDeBodega = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: esDeBodega ? Colors.tealAccent.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('De Bodega', style: TextStyle(color: esDeBodega ? Colors.tealAccent : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => esDeBodega = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !esDeBodega ? Colors.purpleAccent.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('Compra Cliente', style: TextStyle(color: !esDeBodega ? Colors.purpleAccent : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 📦 FORMULARIO DINÁMICO
                  if (esDeBodega) ...[
                    const Text('Seleccionar de inventario', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: AppColors.fondo,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
                          value: itemBodegaSeleccionado,
                          hint: const Text('Ej: Pasta Térmica', style: TextStyle(color: Colors.white38)),
                          style: const TextStyle(color: Colors.white),
                          items: inventarioBodega.map((item) {
                            return DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) => setModalState(() => itemBodegaSeleccionado = val),
                        ),
                      ),
                    ),
                  ] else ...[
                    _campo(nombreCtrl, 'Nombre exacto del repuesto', Icons.edit_outlined),
                    const SizedBox(height: 12),
                    _campo(proveedorCtrl, 'Tienda o Proveedor', Icons.storefront_outlined),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _campo(cantidadCtrl, 'Cant.', Icons.format_list_numbered, tipo: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: _campo(costoCtrl, 'Costo (CLP)', Icons.attach_money, tipo: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esDeBodega ? Colors.tealAccent : Colors.purpleAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  // --- VALIDACIONES ---
                  final nombreFinal = esDeBodega ? itemBodegaSeleccionado : nombreCtrl.text.trim();
                  
                  if (nombreFinal == null || nombreFinal.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Debes seleccionar o escribir un nombre.')));
                    return;
                  }

                  final costo = double.tryParse(costoCtrl.text) ?? 0.0;
                  if (!esDeBodega && costo <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Las compras para clientes deben tener un costo.')));
                    return;
                  }

                  // --- PREPARAR CARGA ÚTIL PARA LARAVEL ---
                  final repuestoData = {
                    'diagnostico_id': idReferencia, // <--- ¡CAMBIAR AQUÍ! (Antes decía 'id_diagnostico')
                    'nombre': nombreFinal,
                    'proveedor': esDeBodega ? 'Bodega Interna' : proveedorCtrl.text.trim(),
                    'cantidad': int.tryParse(cantidadCtrl.text) ?? 1,
                    'costo_unitario': costo,
                    'origen': esDeBodega ? 'bodega' : 'compra_externa',
                    'estado': 'pendiente',
                  };

                  try {
                    final provider = context.read<HelpdeskProvider>();
                    // Usamos el método estandarizado que armamos en el mensaje anterior
                    final exito = await provider.agregarRepuesto(repuestoData);

                    if (exito && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(esDeBodega ? '✅ Insumo de bodega asignado' : '✅ Repuesto de cliente registrado'),
                          backgroundColor: esDeBodega ? Colors.green.shade800 : Colors.purple.shade800,
                        ),
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

// Widget auxiliar para campos de texto limpios
Widget _campo(TextEditingController ctrl, String label, IconData icono, {TextInputType tipo = TextInputType.text}) {
  return TextField(
    controller: ctrl,
    keyboardType: tipo,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      prefixIcon: Icon(icono, color: Colors.white38, size: 18),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
    ),
  );
}