import 'package:flutter/material.dart';
import '../../../core/dao/diagnostico_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'presupuesto_modal.dart';

class DiagnosticosScreen extends StatefulWidget {
  const DiagnosticosScreen({super.key});

  @override
  State<DiagnosticosScreen> createState() => _DiagnosticosScreenState();
}

class _DiagnosticosScreenState extends State<DiagnosticosScreen> {
  final dao = DiagnosticoDao();
  final ingresoDao = IngresoDAO();
  List<Map<String, dynamic>> diagnosticos = [];
  List<Map<String, dynamic>> filtrados = [];

  String filtroEstado = 'todos';
  String query = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await dao.listarDetallado();
    setState(() {
      diagnosticos = data;
      filtrados = data;
    });
  }

  void filtrar() {
    setState(() {
      filtrados = diagnosticos.where((d) {
        final estado = (d['estado'] ?? '').toString().toLowerCase();
        final texto =
            '${d['marca'] ?? ''} ${d['tipo_equipo'] ?? ''} ${d['descripcion_falla'] ?? ''}'
                .toLowerCase();

        final coincideEstado =
            filtroEstado == 'todos' || estado == filtroEstado;
        final coincideTexto = texto.contains(query.toLowerCase());

        return coincideEstado && coincideTexto;
      }).toList();
    });
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amberAccent;
      case 'en_revision':
        return Colors.blueAccent;
      case 'finalizado':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'en_revision':
        return Icons.search;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Fecha desconocida';
    return fecha.split('T').first; // simplifica ISO a yyyy-MM-dd
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Diagnósticos',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, equipo o falla...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                query = val;
                filtrar();
              },
            ),
            const SizedBox(height: 10),

            // 🧭 Filtros por estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('todos', 'Todos'),
                  _chipFiltro('pendiente', 'Pendiente'),
                  _chipFiltro('en_revision', 'En revisión'),
                  _chipFiltro('finalizado', 'Finalizado'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 📋 Lista de diagnósticos
            Expanded(
              child: filtrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay diagnósticos para mostrar.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargar,
                      color: Colors.tealAccent,
                      backgroundColor: AppColors.fondo,
                      child: ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final d = filtrados[index];
                          final estado = d['estado'] ?? 'pendiente';

                          return Card(
                            color: AppColors.fondo.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: Icon(
                                _iconoEstado(estado),
                                color: _colorEstado(estado),
                                size: 36,
                              ),
                              title: Text(
                                '${d['marca'] ?? 'Equipo'} (${d['tipo_equipo'] ?? 'N/D'})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Falla: ${d['descripcion_falla'] ?? 'No especificada'}\n'
                                  'Conclusiones: ${d['conclusiones'] ?? 'Sin concluir'}\n'
                                  'Fecha: ${_formatearFecha(d['creado_en'])}\n'
                                  'Estado: ${estado.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                color: AppColors.fondo,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (opcion) async {
                                  switch (opcion) {
                                    case 'presupuesto':
                                      await mostrarPresupuestoModal(
                                        context,
                                        d['id_diagnostico'],
                                      );
                                      await ingresoDao.actualizarEstado(
                                        d['id_ingreso'],
                                        'en_presupuesto',
                                      );
                                      break;

                                    case 'finalizar':
                                      await dao.actualizarEstado(
                                        d['id_diagnostico'],
                                        'finalizado',
                                      );
                                      break;

                                    case 'eliminar':
                                      await dao.eliminar(d['id_diagnostico']);
                                      break;
                                  }
                                  await cargar();
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'presupuesto',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          color: Colors.greenAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Crear presupuesto'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'finalizar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.tealAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Marcar finalizado'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_forever,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Eliminar diagnóstico'),
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
          ],
        ),
      ),
    );
  }

  // 🎚️ Botones de filtro estilo chip
  Widget _chipFiltro(String valor, String texto) {
    final activo = filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          texto,
          style: TextStyle(
            color: activo ? Colors.black : Colors.white70,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: activo,
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.5),
        onSelected: (_) {
          setState(() {
            filtroEstado = valor;
          });
          filtrar();
        },
      ),
    );
  }
}
