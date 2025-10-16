import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String filtroEstado = 'todos';

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
        return Icons.check_circle_outline;
      case 'rechazado':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_bottom;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'autorizado':
        return 'Autorizado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar filtro
    final filtrados = presupuestos.where((p) {
      if (filtroEstado == 'todos') return true;
      return p['estado'] == filtroEstado;
    }).toList();

    return LayoutPrincipal(
      titulo: 'Presupuestos',
      child: Column(
        children: [
          // 🔍 Barra de filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('todos', 'Todos', Icons.list),
                  _chipFiltro(
                    'pendiente',
                    'Pendientes',
                    Icons.hourglass_bottom,
                  ),
                  _chipFiltro('autorizado', 'Autorizados', Icons.check_circle),
                  _chipFiltro('rechazado', 'Rechazados', Icons.cancel),
                ],
              ),
            ),
          ),

          // 📋 Listado de presupuestos
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay presupuestos registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : RefreshIndicator(
                    color: Colors.tealAccent,
                    onRefresh: cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final p = filtrados[index];
                        final estado = p['estado'] ?? 'pendiente';
                        final fecha = p['fecha_creacion'] != null
                            ? DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(DateTime.parse(p['fecha_creacion']))
                            : 'Sin fecha';

                        return Card(
                          color: AppColors.fondo.withOpacity(0.95),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                              _iconoEstado(estado),
                              color: _colorEstado(estado),
                              size: 34,
                            ),
                            title: Text(
                              p['cliente'] ?? 'Cliente desconocido',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${p['marca'] ?? 'Sin marca'} (${p['tipo_equipo'] ?? ''})\n${_textoEstado(estado)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            iconColor: Colors.tealAccent,
                            collapsedIconColor: Colors.white70,
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: [
                              _detalleCampo(
                                'Trabajo solicitado',
                                p['descripcion'],
                              ),
                              _detalleCampo(
                                'Total estimado',
                                '\$${p['total']?.toStringAsFixed(0) ?? '0'} CLP',
                              ),
                              _detalleCampo('Fecha de creación', fecha),
                              _detalleCampo(
                                'Equipo asociado',
                                '${p['tipo_equipo']} - ${p['marca']}',
                              ),
                              const SizedBox(height: 8),

                              // Estado visual
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  backgroundColor: _colorEstado(estado),
                                  label: Text(
                                    _textoEstado(estado),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 🧩 Acciones
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _mostrarDetalles(context, p),
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      color: Colors.tealAccent,
                                    ),
                                    label: const Text(
                                      'Ver detalle',
                                      style: TextStyle(
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    color: AppColors.fondo,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (opcion) async {
                                      if (opcion == 'autorizar' ||
                                          opcion == 'rechazar') {
                                        final nuevoEstado =
                                            opcion == 'autorizar'
                                            ? 'autorizado'
                                            : 'rechazado';
                                        await presupuestoDao.actualizarEstado(
                                          p['id_presupuesto'],
                                          nuevoEstado,
                                        );
                                        await cargar();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                nuevoEstado == 'autorizado'
                                                    ? '✅ Presupuesto autorizado'
                                                    : '❌ Presupuesto rechazado',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                                            Icon(
                                              Icons.cancel,
                                              color: Colors.redAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Rechazar'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------- COMPONENTES ----------

  Widget _chipFiltro(String estado, String label, IconData icono) {
    final activo = filtroEstado == estado;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          color: activo ? Colors.black : Colors.white70,
          fontSize: 13,
        ),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.3),
        selected: activo,
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }

  Widget _detalleCampo(String titulo, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$titulo:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDetalles(
    BuildContext context,
    Map<String, dynamic> presupuesto,
  ) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.receipt_long, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              'Detalle del presupuesto',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detalleCampo('Cliente', presupuesto['cliente'] ?? 'N/D'),
            _detalleCampo(
              'Equipo',
              '${presupuesto['tipo_equipo']} ${presupuesto['marca']}',
            ),
            _detalleCampo('Descripción', presupuesto['descripcion'] ?? ''),
            _detalleCampo(
              'Total estimado',
              '\$${presupuesto['total']?.toStringAsFixed(0) ?? '0'} CLP',
            ),
            const SizedBox(height: 10),
            Chip(
              backgroundColor: _colorEstado(
                presupuesto['estado'] ?? 'pendiente',
              ),
              label: Text(
                _textoEstado(presupuesto['estado'] ?? 'pendiente'),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
