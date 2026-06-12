import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import '../../reports/pdf_informe.dart';
import '../../reports/pdf_utils.dart';
import 'informe_modal.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarInformes();
  }

  // --- Helpers de Extracción Segura ---
  String _getCliente(Map<String, dynamic> i) {
    if (i.containsKey('cliente') && i['cliente'] != null && i['cliente'].toString().isNotEmpty) {
      return i['cliente'].toString();
    }
    if (i['diagnostico'] != null && i['diagnostico']['ingreso'] != null && i['diagnostico']['ingreso']['equipo'] != null && i['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return i['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente desconocido';
    }
    return 'Cliente desconocido';
  }

  String _getMarca(Map<String, dynamic> i) {
    if (i.containsKey('marca') && i['marca'] != null && i['marca'].toString().isNotEmpty) {
      return i['marca'].toString();
    }
    if (i['diagnostico'] != null && i['diagnostico']['ingreso'] != null && i['diagnostico']['ingreso']['equipo'] != null) {
      return i['diagnostico']['ingreso']['equipo']['marca'] ?? 'Sin marca';
    }
    return 'Equipo';
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    // Escuchamos los informes desde el provider
    final informes = context.watch<HelpdeskProvider>().informes;
    final isLoading = context.watch<HelpdeskProvider>().loading;

    return LayoutPrincipal(
      titulo: 'Informes técnicos',
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        foregroundColor: AppColors.fondo,
        onPressed: () async {
          // El modal de informe debe permitir seleccionar el diagnóstico base
          // Usamos 0 como placeholder; idealmente el modal debería tener un Dropdown
          await mostrarInformeModal(context, 0); 
          await _cargar();
        },
        child: const Icon(Icons.add),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading && informes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
            : informes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay informes registrados.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: Colors.tealAccent,
                    backgroundColor: AppColors.fondo,
                    child: ListView.builder(
                      itemCount: informes.length,
                      itemBuilder: (context, index) {
                        final i = informes[index];
                        final cliente = _getCliente(i);
                        final marca = _getMarca(i);

                        return Card(
                          color: AppColors.fondo.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(
                              Icons.article,
                              color: Colors.tealAccent,
                            ),
                            title: Text(
                              '$marca - $cliente',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Conclusiones: ${i['conclusiones'] ?? 'N/A'}\n'
                                'Recomendaciones: ${i['recomendaciones'] ?? 'Ninguna'}',
                                style: const TextStyle(color: Colors.white70, height: 1.3),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () async {
                                try {
                                  final file = await PdfInforme.generar(i);
                                  await PdfUtils.abrir(file);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al generar PDF: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}