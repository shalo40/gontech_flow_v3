import 'package:flutter/material.dart';
import '../../../core/dao/informe_dao.dart';
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
  final dao = InformeDao();
  List<Map<String, dynamic>> informes = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await dao.listarDetallado();
    setState(() => informes = data);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Informes técnicos',
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        foregroundColor: AppColors.fondo,
        onPressed: () async {
          // temporal: crear informe para el primer diagnóstico
          await mostrarInformeModal(context, 1);
          await cargar();
        },
        child: const Icon(Icons.add),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: informes.isEmpty
            ? const Center(
                child: Text(
                  'No hay informes registrados.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : RefreshIndicator(
                onRefresh: cargar,
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
