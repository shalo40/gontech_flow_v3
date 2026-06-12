import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/dao/presupuesto_dao.dart';
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  final presupuestoDao = PresupuestoDao(); // Lo mantenemos temporalmente para las actualizaciones de estado locales
  String filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarPresupuestos();
  }

  // --- Helpers de compatibilidad API / Local ---
  String _getCliente(Map<String, dynamic> p) {
    if (p.containsKey('cliente') && p['cliente'] != null && p['cliente'] is String) return p['cliente'];
    if (p['diagnostico'] != null && p['diagnostico']['ingreso'] != null && p['diagnostico']['ingreso']['equipo'] != null && p['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return p['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente desconocido';
    }
    return 'Cliente desconocido';
  }

  String _getMarca(Map<String, dynamic> p) {
    if (p.containsKey('marca') && p['marca'] != null) return p['marca'];
    if (p['diagnostico'] != null && p['diagnostico']['ingreso'] != null && p['diagnostico']['ingreso']['equipo'] != null) {
      return p['diagnostico']['ingreso']['equipo']['marca'] ?? 'Sin marca';
    }
    return 'Sin marca';
  }

  String _getTipo(Map<String, dynamic> p) {
    if (p.containsKey('tipo_equipo') && p['tipo_equipo'] != null) return p['tipo_equipo'];
    if (p['diagnostico'] != null && p['diagnostico']['ingreso'] != null && p['diagnostico']['ingreso']['equipo'] != null) {
      return p['diagnostico']['ingreso']['equipo']['tipo_equipo'] ?? '';
    }
    return '';
  }

  int _getId(Map<String, dynamic> p) {
    return int.tryParse((p['id_presupuesto'] ?? p['id'] ?? '0').toString()) ?? 0;
  }
  // ---------------------------------------------

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
    final provider = context.watch<HelpdeskProvider>();
    final presupuestos = provider.presupuestos;
    final isLoading = provider.loading;

    // Aplicar filtro en tiempo real
    final filtrados = presupuestos.where((p) {
      if (filtroEstado == 'todos') return true;
      return (p['estado'] ?? 'pendiente') == filtroEstado;
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
                  _chipFiltro('pendiente', 'Pendientes', Icons.hourglass_bottom),
                  _chipFiltro('autorizado', 'Autorizados', Icons.check_circle),
                  _chipFiltro('rechazado', 'Rechazados', Icons.cancel),
                ],
              ),
            ),
          ),

          // 📋 Listado de presupuestos
          Expanded(
            child: isLoading && filtrados.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : filtrados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay presupuestos registrados',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final p = filtrados[index];
                            final estado = p['estado'] ?? 'pendiente';
                            final fechaRaw = p['fecha_creacion'] ?? p['created_at'];
                            final fecha = fechaRaw != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fechaRaw.toString()))
                                : 'Sin fecha';

                            final cliente = _getCliente(p);
                            final marca = _getMarca(p);
                            final tipo = _getTipo(p);
                            final idPresupuesto = _getId(p);

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
                                  cliente,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$marca ($tipo)\n${_textoEstado(estado)}',
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
                                  _detalleCampo('Trabajo solicitado', p['descripcion']),
                                  _detalleCampo('Total estimado', '\$${p['total']?.toString() ?? '0'} CLP'),
                                  _detalleCampo('Fecha de creación', fecha),
                                  _detalleCampo('Equipo asociado', '$tipo - $marca'),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _mostrarDetalles(context, p, cliente, marca, tipo, estado),
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
                                          if (opcion == 'autorizar' || opcion == 'rechazar') {
                                            final nuevoEstado = opcion == 'autorizar' ? 'autorizado' : 'rechazado';
                                            
                                            // Actualización local temporal hasta integrar el endpoint de update
                                            await presupuestoDao.actualizarEstado(idPresupuesto, nuevoEstado);
                                            await _cargar();

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
                                                Icon(Icons.check_circle, color: Colors.greenAccent),
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
    Map<String, dynamic> p,
    String cliente,
    String marca,
    String tipo,
    String estado,
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
            _detalleCampo('Cliente', cliente),
            _detalleCampo('Equipo', '$tipo $marca'),
            _detalleCampo('Descripción', p['descripcion'] ?? ''),
            _detalleCampo('Total estimado', '\$${p['total']?.toString() ?? '0'} CLP'),
            const SizedBox(height: 10),
            Chip(
              backgroundColor: _colorEstado(estado),
              label: Text(
                _textoEstado(estado),
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