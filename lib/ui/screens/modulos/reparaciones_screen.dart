import 'package:flutter/material.dart';
import '../../../core/dao/reparacion_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'entrega_modal.dart';

class ReparacionesScreen extends StatefulWidget {
  const ReparacionesScreen({super.key});

  @override
  State<ReparacionesScreen> createState() => _ReparacionesScreenState();
}

class _ReparacionesScreenState extends State<ReparacionesScreen> {
  final reparacionDao = ReparacionDao();
  final ingresoDao = IngresoDao();
  List<Map<String, dynamic>> reparaciones = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await reparacionDao.listarDetallado();
    setState(() => reparaciones = data);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'finalizada':
        return Colors.greenAccent;
      case 'en_proceso':
        return Colors.amberAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'finalizada':
        return Icons.check_circle;
      case 'en_proceso':
        return Icons.build_circle;
      default:
        return Icons.handyman;
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
                  'No hay reparaciones registradas',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: reparaciones.length,
                itemBuilder: (context, index) {
                  final r = reparaciones[index];
                  final estado = r['estado'] ?? 'en_proceso';

                  return Card(
                    color: AppColors.fondo.withOpacity(0.9),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _iconoEstado(estado),
                        color: _colorEstado(estado),
                        size: 36,
                      ),
                      title: Text(
                        'Equipo: ${r['marca'] ?? 'N/D'} (${r['tipo_equipo'] ?? ''})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Trabajo: ${r['descripcion_trabajo'] ?? 'Sin detalle'}\n'
                        'Falla: ${r['descripcion_falla'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: AppColors.fondo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (opcion) async {
                          if (opcion == 'finalizar') {
                            await reparacionDao.actualizarEstado(
                              r['id_reparacion'],
                              'finalizada',
                            );
                            await ingresoDao.actualizarEstadoDesdeReparacion(
                              r['id_reparacion'],
                              'finalizado',
                            );
                            await cargar();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Reparación finalizada'),
                                ),
                              );
                            }
                          } else if (opcion == 'entrega') {
                            await mostrarEntregaModal(
                              context,
                              r['id_reparacion'],
                            );
                            await cargar();
                          }
                        },
                        itemBuilder: (context) {
                          final opciones = <PopupMenuEntry<String>>[];

                          // Opciones según estado
                          if (estado == 'en_proceso') {
                            opciones.addAll([
                              const PopupMenuItem(
                                value: 'finalizar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.greenAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Marcar como finalizada'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'entrega',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.done_all,
                                      color: Colors.tealAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Registrar entrega'),
                                  ],
                                ),
                              ),
                            ]);
                          } else {
                            opciones.add(
                              const PopupMenuItem(
                                value: 'entrega',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in,
                                      color: Colors.blueAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Ver entrega'),
                                  ],
                                ),
                              ),
                            );
                          }

                          return opciones;
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
