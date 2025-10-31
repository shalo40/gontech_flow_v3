import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String filtroEstado = 'todos';
  String criterioOrden = 'reciente';
  String busqueda = '';
  final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

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

  List<Map<String, dynamic>> _filtrarYOrdenar() {
    var lista = reparaciones.where((r) {
      final estado = r['estado'] ?? '';
      final cliente = (r['cliente'] ?? '').toString().toLowerCase();
      final marca = (r['marca'] ?? '').toString().toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda =
          cliente.contains(query) || marca.contains(query) || query.isEmpty;
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();

    if (criterioOrden == 'nombre') {
      lista.sort(
        (a, b) => (a['cliente'] ?? '').toString().compareTo(
          (b['cliente'] ?? '').toString(),
        ),
      );
    } else {
      lista.sort(
        (a, b) =>
            (b['id_reparacion'] as int).compareTo(a['id_reparacion'] as int),
      );
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrarYOrdenar();

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
              child: lista.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay reparaciones registradas.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargar,
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
    final fechaInicio = r['fecha_inicio'] != null
        ? formatoFecha.format(DateTime.parse(r['fecha_inicio']))
        : '-';
    final fechaFin = r['fecha_fin'] != null
        ? formatoFecha.format(DateTime.parse(r['fecha_fin']))
        : '-';

    return ExpansionTile(
      collapsedBackgroundColor: AppColors.fondo.withOpacity(0.9),
      backgroundColor: AppColors.fondo.withOpacity(0.95),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '${r['cliente'] ?? 'Cliente'} - ${r['marca'] ?? ''}',
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
                'Diagnóstico: ${r['descripcion_falla'] ?? ''}',
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
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _mostrarOpciones(Map<String, dynamic> r) async {
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
                    Icons.timelapse,
                    color: Colors.amberAccent,
                  ),
                  title: const Text(
                    'Marcar en proceso',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await dao.actualizarEstado(
                      r['id_reparacion'],
                      'en_proceso',
                    );
                    Navigator.pop(context);
                    await cargar();
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
                    await dao.actualizarEstado(
                      r['id_reparacion'],
                      'finalizada',
                    );
                    Navigator.pop(context);
                    await cargar();
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

                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.cyanAccent,
                  ),
                  title: const Text(
                    'Generar informe técnico (PDF)',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // 🔹 Lo implementaremos en el siguiente paso:
                    // await generarInformeTecnico(r['id_reparacion']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📄 Generación de PDF próximamente...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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
                    await dao.eliminar(r['id_reparacion']);
                    Navigator.pop(context);
                    await cargar();
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
