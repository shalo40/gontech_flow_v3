import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/dao/reparacion_dao.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import '../../reports/pdf_reparacion.dart';
import '../../reports/pdf_utils.dart';
import 'repuestos_screen.dart';
import '../../../core/dao/entrega_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/entrega.dart';

class ReparacionesScreen extends StatefulWidget {
  const ReparacionesScreen({super.key});

  @override
  State<ReparacionesScreen> createState() => _ReparacionesScreenState();
}

class _ReparacionesScreenState extends State<ReparacionesScreen> {
  final dao = ReparacionDao();
  List<Map<String, dynamic>> _repuestosGlobal = [];
  String filtroEstado = 'todos';
  String criterioOrden = 'reciente';
  String busqueda = '';
  final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    // Recargamos las reparaciones desde el provider
    await context.read<HelpdeskProvider>().recargarReparaciones();
    // Mantenemos repuestos local hasta migrar su módulo
    final repDao = RepuestoDao();
    final repData = await repDao.listarDetallado();
    if (mounted) {
      setState(() {
        _repuestosGlobal = repData;
      });
    }
  }

  // --- Helpers de compatibilidad API / Local ---
  String _getNested(Map<String, dynamic> r, String localKey, List<String> apiPath, [String fallback = '']) {
    if (r.containsKey(localKey) && r[localKey] != null && r[localKey].toString().isNotEmpty) {
      return r[localKey].toString();
    }
    dynamic current = r;
    for (final key in apiPath) {
      if (current == null || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString().isNotEmpty ? current.toString() : fallback;
  }

  int _getId(Map<String, dynamic> r) {
    return int.tryParse((r['id_reparacion'] ?? r['id'] ?? '0').toString()) ?? 0;
  }

  int _getDiagnosticoId(Map<String, dynamic> r) {
    return int.tryParse((r['id_diagnostico'] ?? r['diagnostico_id'] ?? '0').toString()) ?? 0;
  }
  
  int _getIngresoId(Map<String, dynamic> r) {
    if (r['id_ingreso'] != null) return int.tryParse(r['id_ingreso'].toString()) ?? 0;
    if (r['diagnostico'] != null && r['diagnostico']['ingreso_id'] != null) {
      return int.tryParse(r['diagnostico']['ingreso_id'].toString()) ?? 0;
    }
    return 0;
  }
  // ---------------------------------------------

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

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'en_proceso':
        return Icons.timelapse;
      case 'finalizada':
        return Icons.check_circle;
      default:
        return Icons.build;
    }
  }

  List<Map<String, dynamic>> _filtrarYOrdenar(List<Map<String, dynamic>> reparaciones) {
    var lista = reparaciones.where((r) {
      final estado = r['estado'] ?? '';
      final cliente = _getNested(r, 'cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre']).toLowerCase();
      final marca = _getNested(r, 'marca', ['diagnostico', 'ingreso', 'equipo', 'marca']).toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda =
          cliente.contains(query) || marca.contains(query) || query.isEmpty;
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();

    if (criterioOrden == 'nombre') {
      lista.sort(
        (a, b) => _getNested(a, 'cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'])
            .compareTo(_getNested(b, 'cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'])),
      );
    } else {
      lista.sort(
        (a, b) => _getId(b).compareTo(_getId(a)),
      );
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final isLoading = provider.loading;
    final lista = _filtrarYOrdenar(provider.reparaciones);

    return LayoutPrincipal(
      titulo: 'Reparaciones',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Barra de búsqueda y filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => busqueda = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar cliente o equipo...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: AppColors.fondo.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.white70),
                  color: AppColors.fondo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) => setState(() => criterioOrden = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'reciente',
                      child: Text('Ordenar por más recientes'),
                    ),
                    PopupMenuItem(
                      value: 'nombre',
                      child: Text('Ordenar por nombre'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🟩 Chips de estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('todos', 'Todos', Icons.list_alt),
                  const SizedBox(width: 6),
                  _chipFiltro('en_proceso', 'En proceso', Icons.timelapse),
                  const SizedBox(width: 6),
                  _chipFiltro('finalizada', 'Finalizadas', Icons.check_circle),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 📋 Lista de reparaciones
            Expanded(
              child: isLoading && lista.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : lista.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay reparaciones registradas.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          color: Colors.tealAccent,
                          backgroundColor: AppColors.fondo,
                          child: ListView.builder(
                            itemCount: lista.length,
                            itemBuilder: (context, index) {
                              final r = lista[index];
                              return _cardReparacion(r);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipFiltro(String valor, String label, IconData icono) {
    final activo = filtroEstado == valor;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: activo ? Colors.black : Colors.white70, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: activo ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: activo,
      onSelected: (_) => setState(() => filtroEstado = valor),
      selectedColor: Colors.tealAccent,
      backgroundColor: AppColors.fondo.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _cardReparacion(Map<String, dynamic> r) {
    final estado = r['estado'] ?? 'pendiente';
    final fechaInicioRaw = r['fecha_inicio'];
    final fechaFinRaw = r['fecha_fin'];

    final fechaInicio = fechaInicioRaw != null
        ? formatoFecha.format(DateTime.parse(fechaInicioRaw.toString()))
        : '-';
    final fechaFin = fechaFinRaw != null
        ? formatoFecha.format(DateTime.parse(fechaFinRaw.toString()))
        : '-';

    final cliente = _getNested(r, 'cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'], 'Cliente Desconocido');
    final marca = _getNested(r, 'marca', ['diagnostico', 'ingreso', 'equipo', 'marca']);
    final falla = _getNested(r, 'descripcion_falla', ['diagnostico', 'descripcion_falla']);
    final idDiagnostico = _getDiagnosticoId(r);

    final repuestosRelacionados = _repuestosGlobal.where((rep) => rep['id_diagnostico'] == idDiagnostico).toList();
    final int countRepuestos = repuestosRelacionados.length;
    final double costoRepuestos = repuestosRelacionados.fold(0.0, (sum, rep) => sum + (rep['costo'] as num? ?? 0).toDouble());

    return ExpansionTile(
      collapsedBackgroundColor: AppColors.fondo.withOpacity(0.9),
      backgroundColor: AppColors.fondo.withOpacity(0.95),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '$cliente - $marca',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'Estado: ${estado.toUpperCase()}',
        style: TextStyle(color: _colorEstado(estado)),
      ),
      leading: Icon(_iconoEstado(estado), color: _colorEstado(estado)),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        onPressed: () => _mostrarOpciones(r),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnóstico: $falla',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Descripción: ${r['descripcion'] ?? ''}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Notas: ${r['notas'] ?? '-'}',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicio: $fechaInicio',
                style: const TextStyle(color: Colors.white54),
              ),
              Text(
                'Fin: $fechaFin',
                style: const TextStyle(color: Colors.white54),
              ),
              if (countRepuestos > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle, color: Colors.cyanAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$countRepuestos Repuesto(s) usados - \$${costoRepuestos.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _mostrarOpciones(Map<String, dynamic> r) async {
    final estado = r['estado'] ?? 'pendiente';
    final idReparacion = _getId(r);
    final idDiagnostico = _getDiagnosticoId(r);
    final idIngreso = _getIngresoId(r);
    final provider = context.read<HelpdeskProvider>();

    showModalBottomSheet(
      backgroundColor: AppColors.fondo.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.description,
                    color: Colors.tealAccent,
                  ),
                  title: const Text(
                    'Ver detalle técnico',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Abrir hoja con repuestos instalados',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/reparacion_detalle',
                      arguments: r,
                    );
                  },
                ),
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(
                    Icons.inventory,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    'Ver repuestos usados',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Ir al inventario filtrando por esta reparación',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepuestosScreen(idDiagnosticoFiltro: idDiagnostico),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(
                    Icons.timelapse,
                    color: Colors.amberAccent,
                  ),
                  title: const Text(
                    'Marcar en proceso',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.actualizarReparacion(idReparacion, {'estado': 'en_proceso'});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🟡 Reparación marcada como en proceso',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                  ),
                  title: const Text(
                    'Marcar como finalizada',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await provider.actualizarReparacion(idReparacion, {'estado': 'finalizada'});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '✅ Reparación finalizada correctamente',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),

                if (estado == 'finalizada') ...[
                  ListTile(
                    leading: const Icon(
                      Icons.rocket_launch,
                      color: Colors.purpleAccent,
                    ),
                    title: const Text(
                      'Liberar para Entrega (Alta manual)',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Mueve el equipo a la lista de Entregas pendientes',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      
                      final entregaDao = EntregaDao();
                      final ingresoDao = IngresoDAO();
                      
                      final cliente = _getNested(r, 'cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre']);
                      final nuevaEntrega = Entrega(
                        id_reparacion: idReparacion,
                        nombre_receptor: cliente,
                        estado: 'pendiente',
                      );
                      
                      await entregaDao.insertar(nuevaEntrega);
                      await provider.actualizarReparacion(idReparacion, {'estado': 'entregada'});
                      await ingresoDao.actualizarEstadoDesdeReparacion(idIngreso, 'finalizado');
                      
                      await provider.recargarTodo();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚀 Equipo liberado y enviado a Entregas'),
                            backgroundColor: Colors.purple,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.white12, indent: 16, endIndent: 16),
                ],

                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.cyanAccent,
                  ),
                  title: const Text(
                    'Generar reporte PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final repuestoDao = RepuestoDao();
                      final repuestos = await repuestoDao.listarDetallado();
                      final repuestosRep = repuestos.where(
                        (rep) => rep['id_diagnostico'] == idDiagnostico,
                      ).toList();

                      final file = await PdfReparacion.generar(
                        reparacion: r,
                        repuestos: repuestosRep,
                      );
                      await PdfUtils.abrir(file);
                    } catch (e) {
                      if (mounted) {
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
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Eliminar reparación',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await dao.eliminar(idReparacion); // Usando DAO local para borrado hasta migrar la ruta
                    await provider.recargarReparaciones();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ Reparación eliminada'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}