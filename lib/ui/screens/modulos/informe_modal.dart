import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../../core/providers/helpdesk_provider.dart'; 
import '../../theme/app_colors.dart';

Future<void> mostrarInformeModal(
  BuildContext context,
  int idDiagnosticoInicial,
) async {
  final descripcionCtrl = TextEditingController();
  final conclusionesCtrl = TextEditingController();
  final recomendacionesCtrl = TextEditingController();
  int? tecnicoSeleccionado;
  int? diagnosticoSeleccionado = idDiagnosticoInicial == 0 ? null : idDiagnosticoInicial;

  final provider = context.read<HelpdeskProvider>();
  final diagnosticos = provider.diagnosticos; 

  // --- Helpers de Extracción Segura ---
  String getInfoDiagnostico(Map<String, dynamic> d) {
    String marca = 'Equipo';
    String cliente = 'Cliente';
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      marca = d['ingreso']['equipo']['marca'] ?? marca;
      if (d['ingreso']['equipo']['cliente'] != null) {
        cliente = d['ingreso']['equipo']['cliente']['nombre'] ?? cliente;
      }
    }
    return '$marca - $cliente';
  }
  
  int getIdDiag(Map<String, dynamic> d) {
    return int.tryParse((d['id_diagnostico'] ?? d['id'] ?? '0').toString()) ?? 0;
  }
  // -----------------------------------

  final List<Map<String, dynamic>> tecnicos = [
    {'id': 1, 'nombre': 'Gonzalo Castillo'},
    {'id': 2, 'nombre': 'Técnico Avanzado 2'},
    {'id': 3, 'nombre': 'Técnico Especialista 3'},
  ];

  bool procesando = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final size = MediaQuery.of(context).size;

      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: AppColors.fondo.withOpacity(0.98),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.tealAccent.withOpacity(0.2), width: 1),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: size.height * 0.85, // Evita desbordamientos por teclado
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷️ HEADER DEL MODAL
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, color: Colors.tealAccent, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Certificación e Informe',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 📋 CUERPO DEL FORMULARIO CON SCROLL INTEGRADO
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vinculación de Orden:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            // 🔽 Dropdown Diagnóstico Base
                            DropdownButtonFormField<int>(
                              value: diagnosticoSeleccionado,
                              dropdownColor: AppColors.fondo,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.tealAccent, size: 20),
                                labelText: 'Seleccione Diagnóstico Base',
                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                filled: true, fillColor: Colors.black38,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                              items: diagnosticos.map((d) {
                                final id = getIdDiag(d);
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text('#$id - ${getInfoDiagnostico(d)}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (v) => setStateModal(() => diagnosticoSeleccionado = v),
                            ),
                            const SizedBox(height: 16),

                            const Text('Análisis y Procedimiento Técnico:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            // ✏️ Campos de texto profundos estilo consola
                            _campoModern(descripcionCtrl, 'Descripción general del trabajo efectuado', Icons.text_snippet_outlined, 3),
                            _campoModern(conclusionesCtrl, 'Conclusiones del estado del hardware', Icons.fact_check_outlined, 2),
                            _campoModern(recomendacionesCtrl, 'Recomendaciones futuras para el cliente', Icons.lightbulb_outline, 2),
                            const SizedBox(height: 16),

                            const Text('Responsable Operativo:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            // 🔽 Dropdown Técnico Responsable
                            DropdownButtonFormField<int>(
                              value: tecnicoSeleccionado,
                              dropdownColor: AppColors.fondo,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.engineering_outlined, color: Colors.tealAccent, size: 20),
                                labelText: 'Especialista a Cargo',
                                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                filled: true, fillColor: Colors.black38,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              ),
                              items: tecnicos.map((t) => DropdownMenuItem<int>(
                                value: t['id'],
                                child: Text(t['nombre']),
                              )).toList(),
                              onChanged: (v) => setStateModal(() => tecnicoSeleccionado = v),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🚀 BOTONES DE ACCIÓN FIJOS ABAJO
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: procesando ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: procesando
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(procesando ? 'Guardando...' : 'Emitir Informe', style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: procesando ? null : () async {
                            if (descripcionCtrl.text.isEmpty || tecnicoSeleccionado == null || diagnosticoSeleccionado == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⚠️ Complete los campos obligatorios: Diagnóstico, Técnico y Trabajo Realizado.'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            setStateModal(() => procesando = true);

                            final informeParaLaravel = {
                              'id_diagnostico': diagnosticoSeleccionado,
                              'id_tecnico': tecnicoSeleccionado,
                              'descripcion_general': descripcionCtrl.text.trim(),
                              'conclusiones': conclusionesCtrl.text.trim(),
                              'recomendaciones': recomendacionesCtrl.text.trim(),
                              'creado_en': DateTime.now().toIso8601String(),
                            };

                            try {
                              final exito = await provider.agregarInforme(informeParaLaravel);
                              if (exito && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ Informe técnico guardado y certificado con éxito'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('❌ Error al guardar en servidor: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                                );
                              }
                            } finally {
                              if (context.mounted) setStateModal(() => procesando = false);
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
}

// 🆕 COMPONENTE DE ENTRADA DE TEXTO PREMIUM
Widget _campoModern(TextEditingController ctrl, String label, IconData icono, int lines) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      maxLines: lines,
      minLines: lines,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
      decoration: InputDecoration(
        prefixIcon: Icon(icono, color: Colors.tealAccent, size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        alignLabelWithHint: true, // Alinea el texto de ayuda arriba en campos multilinea
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.tealAccent, width: 1)),
      ),
    ),
  );
}