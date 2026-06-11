import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/dao/diagnostico_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
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
  
  String filtroEstado = 'todos';
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarDiagnosticos();
  }

  // --- Helpers de compatibilidad API / Local ---
  String _getMarca(Map<String, dynamic> d) {
    if (d.containsKey('marca') && d['marca'] != null) return d['marca'];
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      return d['ingreso']['equipo']['marca'] ?? 'Equipo';
    }
    return 'Equipo';
  }

  String _getTipo(Map<String, dynamic> d) {
    if (d.containsKey('tipo_equipo') && d['tipo_equipo'] != null) return d['tipo_equipo'];
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      return d['ingreso']['equipo']['tipo_equipo'] ?? 'N/D';
    }
    return 'N/D';
  }

  int _getId(Map<String, dynamic> d, String keyLocal, String keyApi) {
    return int.tryParse((d[keyLocal] ?? d[keyApi] ?? '0').toString()) ?? 0;
  }
  // ---------------------------------------------

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
    return fecha.split('T').first; 
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los datos directamente del Provider
    final provider = context.watch<HelpdeskProvider>();
    final diagnosticos = provider.diagnosticos;
    final isLoading = provider.loading;

    // Filtrado en tiempo real sobre la lista del Provider
    final filtrados = diagnosticos.where((d) {
      final estado = (d['estado'] ?? '').toString().toLowerCase();
      final marca = _getMarca(d).toLowerCase();
      final tipo = _getTipo(d).toLowerCase();
      final falla = (d['descripcion_falla'] ?? '').toString().toLowerCase();

      final texto = '$marca $tipo $falla';

      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;
      final coincideTexto = texto.contains(query.toLowerCase());

      return coincideEstado && coincideTexto;
    }).toList();

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
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() => query = val);
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
              child: isLoading && filtrados.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : filtrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay diagnósticos para mostrar.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          color: Colors.tealAccent,
                          backgroundColor: AppColors.fondo,
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final d = filtrados[index];
                              final estado = d['estado'] ?? 'pendiente';
                              
                              final idDiagnostico = _getId(d, 'id_diagnostico', 'id');
                              final idIngreso = _getId(d, 'id_ingreso', 'ingreso_id');
                              final marca = _getMarca(d);
                              final tipo = _getTipo(d);

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
                                    '$marca ($tipo)',
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
                                      'Fecha: ${_formatearFecha(d['creado_en'] ?? d['created_at'])}\n'
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
                                      // Acciones: Temporales usando el DAO hasta que migres la actualización a Laravel
                                      switch (opcion) {
                                        case 'presupuesto':
                                          await mostrarPresupuestoModal(
                                            context,
                                            idDiagnostico,
                                          );
                                          await ingresoDao.actualizarEstado(
                                            idIngreso,
                                            'en_presupuesto',
                                          );
                                          break;

                                        case 'finalizar':
                                          await dao.actualizarEstado(
                                            idDiagnostico,
                                            'finalizado',
                                          );
                                          break;

                                        case 'eliminar':
                                          await dao.eliminar(idDiagnostico);
                                          break;
                                      }
                                      // Tras cualquier acción, le pedimos al cerebro que recargue los datos
                                      await _cargar();
                                      if (context.mounted) {
                                        await context.read<HelpdeskProvider>().recargarIngresos();
                                      }
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
        },
      ),
    );
  }
}