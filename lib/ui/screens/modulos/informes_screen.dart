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
          // Nota: Asegúrate de pasar el ID de diagnóstico correcto aquí
          await mostrarInformeModal(context, 1); 
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
                    child: ListView.builder(
                      itemCount: informes.length,
                      itemBuilder: (context, index) {
                        final i = informes[index];
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
                              '${i['marca'] ?? 'Equipo'} - ${i['cliente'] ?? 'Sin cliente'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Conclusiones: ${i['conclusiones'] ?? 'N/A'}\n'
                              'Recomendaciones: ${i['recomendaciones'] ?? ''}',
                              style: const TextStyle(color: Colors.white70),
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
                                      SnackBar(content: Text('Error al generar PDF: $e')),
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