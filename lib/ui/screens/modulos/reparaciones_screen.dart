import 'package:flutter/material.dart';
import '../../../core/dao/reparacion_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class ReparacionesScreen extends StatefulWidget {
  const ReparacionesScreen({super.key});

  @override
  State<ReparacionesScreen> createState() => _ReparacionesScreenState();
}

class _ReparacionesScreenState extends State<ReparacionesScreen> {
  final dao = ReparacionDao();
  List<Map<String, dynamic>> reparaciones = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await dao.listarDetallado();
    setState(() => reparaciones = data);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'en_proceso':
        return Colors.amberAccent;
      case 'finalizada':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Reparaciones',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: reparaciones.isEmpty
            ? const Center(
                child: Text(
                  'No hay reparaciones registradas.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : RefreshIndicator(
                onRefresh: cargar,
                child: ListView.builder(
                  itemCount: reparaciones.length,
                  itemBuilder: (context, index) {
                    final r = reparaciones[index];
                    return Card(
                      color: AppColors.fondo.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.build,
                          color: _colorEstado(r['estado'] ?? ''),
                        ),
                        title: Text(
                          '${r['marca'] ?? 'Equipo'} - ${r['cliente'] ?? 'Sin cliente'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Diagnóstico: ${r['descripcion_falla'] ?? ''}\nEstado: ${r['estado'] ?? ''}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: AppColors.fondo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (opcion) async {
                            if (opcion == 'finalizar') {
                              await dao.actualizarEstado(
                                r['id_reparacion'],
                                'finalizada',
                              );
                              await cargar();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Reparación finalizada'),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'finalizar',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Finalizar'),
                                ],
                              ),
                            ),
                          ],
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
