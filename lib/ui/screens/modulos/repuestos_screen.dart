import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class RepuestosScreen extends StatefulWidget {
  final int? idDiagnosticoFiltro;
  
  const RepuestosScreen({super.key, this.idDiagnosticoFiltro});

  @override
  State<RepuestosScreen> createState() => _RepuestosScreenState();
}

class _RepuestosScreenState extends State<RepuestosScreen> {
  final dao = RepuestoDao();
  List<Map<String, dynamic>> repuestos = [];
  String filtroEstado = 'todos';
  String filtroProveedor = 'todos';
  String busqueda = '';
  String orden = 'reciente';
  final formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await dao.listarDetallado();
    
    if (widget.idDiagnosticoFiltro != null) {
      final filtrados = data.where((r) => r['id_diagnostico'] == widget.idDiagnosticoFiltro).toList();
      setState(() => repuestos = filtrados);
    } else {
      setState(() => repuestos = data);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amberAccent;
      case 'instalado':
        return Colors.greenAccent;
      case 'rechazado':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.timelapse;
      case 'instalado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      default:
        return Icons.inventory_2;
    }
  }

  List<Map<String, dynamic>> _filtrarYOrdenar() {
    var lista = repuestos.where((r) {
      final estado = r['estado'] ?? '';
      final proveedor = (r['proveedor'] ?? '').toString().toLowerCase();
      final nombre = (r['nombre'] ?? '').toString().toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda =
          nombre.contains(query) || proveedor.contains(query);
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;
      final coincideProveedor =
          filtroProveedor == 'todos' || proveedor == filtroProveedor;

      return coincideBusqueda && coincideEstado && coincideProveedor;
    }).toList();

    if (orden == 'nombre') {
      lista.sort(
        (a, b) => (a['nombre'] ?? '').toString().compareTo(
          (b['nombre'] ?? '').toString(),
        ),
      );
    } else {
      lista.sort(
        (a, b) => (b['id_repuesto'] as int).compareTo(a['id_repuesto'] as int),
      );
    }

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrarYOrdenar();

    return LayoutPrincipal(
      titulo: 'Repuestos',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Búsqueda + orden
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => busqueda = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar repuesto o proveedor...',
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
                  onSelected: (v) => setState(() => orden = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'reciente',
                      child: Text('Más recientes'),
                    ),
                    PopupMenuItem(value: 'nombre', child: Text('Por nombre')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.idDiagnosticoFiltro != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primario.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primario),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, color: AppColors.primario),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mostrando repuestos vinculados a la reparación (Diag: #${widget.idDiagnosticoFiltro})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RepuestosScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // 🟩 Filtros de estado
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('todos', 'Todos', Icons.list_alt),
                  const SizedBox(width: 6),
                  _chipFiltro('pendiente', 'Pendientes', Icons.timelapse),
                  const SizedBox(width: 6),
                  _chipFiltro('instalado', 'Instalados', Icons.check_circle),
                  const SizedBox(width: 6),
                  _chipFiltro('rechazado', 'Rechazados', Icons.cancel),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 📦 Lista de repuestos
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay repuestos registrados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargar,
                      child: ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final r = lista[index];
                          return _cardRepuesto(r);
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

  Widget _cardRepuesto(Map<String, dynamic> r) {
    final estado = r['estado'] ?? 'pendiente';
    final fecha = r['fecha_registro'] != null
        ? formatoFecha.format(DateTime.parse(r['fecha_registro']))
        : '-';
    final costo = r['costo_unitario']?.toStringAsFixed(0) ?? '0';

    return Card(
      color: AppColors.fondo.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(_iconoEstado(estado), color: _colorEstado(estado)),
        title: Text(
          '${r['nombre'] ?? 'Repuesto'} (${r['cantidad'] ?? 0}x)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Proveedor: ${r['proveedor'] ?? 'N/D'}\n'
          'Costo unitario: \$$costo CLP\n'
          'Estado: ${estado.toUpperCase()}\n'
          'Fecha: $fecha',
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.fondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (opcion) async {
            if (opcion == 'instalar' || opcion == 'rechazar') {
              final nuevoEstado = opcion == 'instalar'
                  ? 'instalado'
                  : 'rechazado';
              await dao.actualizarEstado(r['id_repuesto'], nuevoEstado);
              await cargar();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      nuevoEstado == 'instalado'
                          ? '🔧 Repuesto instalado'
                          : '❌ Repuesto rechazado',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else if (opcion == 'eliminar') {
              await dao.eliminar(r['id_repuesto']);
              await cargar();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'instalar',
              child: Row(
                children: [
                  Icon(Icons.build, color: Colors.tealAccent),
                  SizedBox(width: 8),
                  Text('Marcar instalado'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rechazar',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Marcar rechazado'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
