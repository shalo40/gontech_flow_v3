import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final equipoDao = EquipoDao();
  List<Map<String, dynamic>> equipos = [];
  String filtroTexto = '';
  String filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await equipoDao.listarDetallado();
    setState(() => equipos = data);
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber;
      case 'diagnosticado':
        return Colors.tealAccent;
      case 'en_reparacion':
        return Colors.blueAccent;
      case 'entregado':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado) {
      case 'diagnosticado':
        return Icons.analytics_outlined;
      case 'en_reparacion':
        return Icons.build_circle_outlined;
      case 'entregado':
        return Icons.check_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🧮 Filtrado combinado
    final equiposFiltrados = equipos.where((e) {
      final texto = filtroTexto.toLowerCase();
      final coincideTexto =
          e['nombre_cliente'].toString().toLowerCase().contains(texto) ||
          e['marca'].toString().toLowerCase().contains(texto) ||
          e['tipo_equipo'].toString().toLowerCase().contains(texto);
      final coincideEstado =
          filtroEstado == 'todos' ||
          (e['estado'] ?? 'pendiente') == filtroEstado;
      return coincideTexto && coincideEstado;
    }).toList();

    // Agrupación por fecha (día-mes)
    final agrupados = <String, List<Map<String, dynamic>>>{};
    for (final e in equiposFiltrados) {
      final fecha = (e['fecha_ingreso'] ?? 'Sin fecha').split('T').first;
      agrupados.putIfAbsent(fecha, () => []).add(e);
    }

    return LayoutPrincipal(
      titulo: 'Equipos',
      child: Column(
        children: [
          // 🔍 Búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, tipo o marca...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (valor) => setState(() => filtroTexto = valor),
            ),
          ),

          // 🏷️ Chips de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chipFiltro('todos', 'Todos', Icons.list_alt),
                _chipFiltro('pendiente', 'Pendiente', Icons.hourglass_empty),
                _chipFiltro('diagnosticado', 'Diagnosticado', Icons.analytics),
                _chipFiltro('en_reparacion', 'Reparación', Icons.build),
                _chipFiltro('entregado', 'Entregado', Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 📋 Listado agrupado
          Expanded(
            child: RefreshIndicator(
              onRefresh: cargar,
              color: Colors.tealAccent,
              child: equiposFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay equipos registrados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView(
                      children: agrupados.entries.map((grupo) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                '📅 ${grupo.key}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...grupo.value.map((e) => _cardEquipo(context, e)),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

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
          fontSize: 12,
        ),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.3),
        selected: activo,
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }

  Widget _cardEquipo(BuildContext context, Map<String, dynamic> e) {
    final estado = e['estado'] ?? 'pendiente';

    return Card(
      color: AppColors.fondo.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _mostrarDetalles(context, e),
        leading: CircleAvatar(
          backgroundColor: Colors.tealAccent.withOpacity(0.15),
          backgroundImage:
              (e['foto_path'] != null &&
                  (e['foto_path'] as String).isNotEmpty &&
                  File(e['foto_path']).existsSync())
              ? FileImage(File(e['foto_path']))
              : null,
          child: (e['foto_path'] == null || (e['foto_path'] as String).isEmpty)
              ? Icon(_iconoEstado(estado), color: Colors.tealAccent)
              : null,
        ),
        title: Text(
          '${e['tipo_equipo'] ?? 'Equipo'} ${e['marca'] ?? ''}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Cliente: ${e['nombre_cliente'] ?? 'N/D'}\n'
          'Serie: ${e['numero_serie'] ?? '-'}',
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
        trailing: Chip(
          label: Text(
            estado.toUpperCase(),
            style: const TextStyle(color: Colors.black, fontSize: 11),
          ),
          backgroundColor: _colorEstado(estado),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalles(
    BuildContext context,
    Map<String, dynamic> equipo,
  ) async {
    final estado = equipo['estado'] ?? 'pendiente';
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400, // ✅ límite horizontal del diálogo
            maxHeight: 600, // ✅ evita scroll infinito
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔷 Imagen o ícono del equipo
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.tealAccent.withOpacity(0.15),
                    backgroundImage:
                        (equipo['foto_path'] != null &&
                            (equipo['foto_path'] as String).isNotEmpty &&
                            File(equipo['foto_path']).existsSync())
                        ? FileImage(File(equipo['foto_path']))
                        : null,
                    child:
                        (equipo['foto_path'] == null ||
                            (equipo['foto_path'] as String).isEmpty)
                        ? const Icon(
                            Icons.computer,
                            color: Colors.tealAccent,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // 👤 Nombre del cliente
                  Text(
                    equipo['nombre_cliente'] ?? 'Sin cliente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 💻 Info básica del equipo
                  Text(
                    '${equipo['tipo_equipo']} ${equipo['marca']} - ${equipo['modelo']}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 🏷 Estado
                  Chip(
                    label: Text(
                      estado.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    backgroundColor: _colorEstado(estado),
                  ),
                  const SizedBox(height: 16),

                  // 🧾 QR del equipo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: QrImageView(
                      data:
                          'EQUIPO-${equipo['id_equipo']}-${equipo['numero_serie'] ?? ''}',
                      size: 160, // ✅ tamaño fijo, evita cálculo intrínseco
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 📖 Texto explicativo
                  const Text(
                    'Código QR único del equipo',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // 🔘 Botón cerrar
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                      label: const Text('Cerrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
