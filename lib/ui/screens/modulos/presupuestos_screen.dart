import 'package:flutter/material.dart';
import '../../../core/dao/presupuesto_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  final presupuestoDao = PresupuestoDao();
  List<Map<String, dynamic>> presupuestos = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await presupuestoDao.listarDetallado();
    setState(() => presupuestos = data);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'autorizado':
        return Colors.greenAccent;
      case 'rechazado':
        return Colors.redAccent;
      default:
        return Colors.amberAccent;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'autorizado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      default:
        return Icons.hourglass_bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Presupuestos',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: presupuestos.isEmpty
            ? const Center(
                child: Text(
                  'No hay presupuestos registrados',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: presupuestos.length,
                itemBuilder: (context, index) {
                  final p = presupuestos[index];
                  final estado = p['estado'] ?? 'pendiente';

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
                        'Cliente: ${p['cliente'] ?? 'N/D'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${p['marca'] ?? ''} (${p['tipo_equipo'] ?? ''})\n'
                        'Trabajo: ${p['descripcion'] ?? 'Sin descripción'}\n'
                        'Total: \$${p['total']?.toStringAsFixed(0) ?? '0'} CLP\n'
                        'Estado: ${p['estado'] ?? 'pendiente'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: AppColors.fondo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (opcion) async {
                          if (opcion == 'autorizar' || opcion == 'rechazar') {
                            final nuevoEstado = opcion == 'autorizar'
                                ? 'autorizado'
                                : 'rechazado';
                            await presupuestoDao.actualizarEstado(
                              p['id_presupuesto'],
                              nuevoEstado,
                            );
                            await cargar();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    nuevoEstado == 'autorizado'
                                        ? '✅ Presupuesto autorizado'
                                        : '❌ Presupuesto rechazado',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'autorizar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent,
                                ),
                                SizedBox(width: 8),
                                Text('Autorizar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rechazar',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Rechazar'),
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
    );
  }
}
