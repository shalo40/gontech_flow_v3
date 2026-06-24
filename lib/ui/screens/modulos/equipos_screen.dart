import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'equipo_detalle_screen.dart'; // Asegúrate de importar el detalle

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  String filtroTexto = '';
  String filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    final provider = context.read<HelpdeskProvider>();
    await provider.recargarEquipos();
  }

  // --- Helpers de compatibilidad API / Local ---
  String _getNombreCliente(Map<String, dynamic> e) {
    if (e.containsKey('nombre_cliente') && e['nombre_cliente'] != null) {
      return e['nombre_cliente'];
    }
    if (e.containsKey('cliente') && e['cliente'] != null) {
      return e['cliente']['nombre'] ?? 'Sin cliente';
    }
    return 'Sin cliente';
  }

  String _getFecha(Map<String, dynamic> e) {
    final f = e['fecha_ingreso'] ?? e['created_at'] ?? 'Sin fecha';
    return f.toString().split('T').first;
  }
  // ---------------------------------------------

  Color _colorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente': return Colors.orangeAccent;
      case 'diagnosticado': return Colors.tealAccent;
      case 'en_reparacion': return Colors.blueAccent;
      case 'entregado': return Colors.greenAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'diagnosticado': return Icons.analytics_outlined;
      case 'en_reparacion': return Icons.build_circle_outlined;
      case 'entregado': return Icons.check_circle_outline;
      default: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final equipos = provider.equipos;
    final isLoading = provider.loading;

    // Contadores para el mini-dashboard
    int cantPendientes = 0;
    int cantEnReparacion = 0;

    final equiposFiltrados = equipos.where((e) {
      final estadoActual = (e['estado'] ?? 'pendiente').toString().toLowerCase();
      
      // Conteo dinámico para el resumen
      if (estadoActual == 'pendiente') cantPendientes++;
      if (estadoActual == 'en_reparacion') cantEnReparacion++;

      final texto = filtroTexto.toLowerCase();
      final nombreCliente = _getNombreCliente(e).toLowerCase();
      
      final coincideTexto =
          nombreCliente.contains(texto) ||
          (e['marca']?.toString().toLowerCase().contains(texto) ?? false) ||
          (e['tipo_equipo']?.toString().toLowerCase().contains(texto) ?? false);
          
      final coincideEstado = filtroEstado == 'todos' || estadoActual == filtroEstado;
      
      return coincideTexto && coincideEstado;
    }).toList();

    final agrupados = <String, List<Map<String, dynamic>>>{};
    for (final e in equiposFiltrados) {
      final fecha = _getFecha(e);
      agrupados.putIfAbsent(fecha, () => []).add(e);
    }

    return LayoutPrincipal(
      titulo: 'Parque de Equipos',
      child: Column(
        children: [
          // 📊 1. TABLERO DE MÉTRICAS SUPERIOR (Copia exacta del dashboard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CardMetricaEquipos(
                    titulo: 'Total Activos', 
                    valor: equipos.length.toString(), 
                    color: Colors.white, 
                    icono: Icons.computer
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardMetricaEquipos(
                    titulo: 'Por Diagnosticar', 
                    valor: cantPendientes.toString(), 
                    color: Colors.orangeAccent, 
                    icono: Icons.hourglass_top
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardMetricaEquipos(
                    titulo: 'En Mesa', 
                    valor: cantEnReparacion.toString(), 
                    color: Colors.blueAccent, 
                    icono: Icons.engineering
                  )
                ),
              ],
            ),
          ),

          // 🔍 2. BUSCADOR MODERNIZADO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (valor) => setState(() => filtroTexto = valor),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, tipo o marca...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 🏷️ 3. FILTROS POR ESTADO (ChoiceChips rediseñados)
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
          const SizedBox(height: 12),

          // 📋 4. LISTA AGRUPADA (Rediseño total de la tarjeta)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: isLoading && equiposFiltrados.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : equiposFiltrados.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.devices_other, color: Colors.white10, size: 60),
                              SizedBox(height: 16),
                              Text('No hay equipos registrados.', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: agrupados.entries.map((grupo) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Separador de Fecha Estilizado
                                Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.tealAccent, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        grupo.key.toUpperCase(),
                                        style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                                ...grupo.value.map((e) => _cardEquipoRedesigned(context, e)),
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
            Icon(icono, size: 14, color: activo ? Colors.black : Colors.white60),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          color: activo ? Colors.black : Colors.white70,
          fontSize: 12,
          fontWeight: activo ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        selected: activo,
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }

  // ===========================================
  // 🆕 TARJETA DE EQUIPO REDISEÑADA (UI Premium)
  // ===========================================
  Widget _cardEquipoRedesigned(BuildContext context, Map<String, dynamic> e) {
    final estado = (e['estado'] ?? 'pendiente').toString().toLowerCase();
    final nombreCliente = _getNombreCliente(e);
    final colorEst = _colorEstado(estado);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fondo.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        // Borde neón basado en el estado
        border: Border.all(color: colorEst.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorEst.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          // ¡AQUÍ ESTÁ LA INTEGRACIÓN CLAVE! Navegamos al detalle en pantalla completa
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipoDetalleScreen(equipo: e),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen / Icono
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: (e['foto_path'] != null &&
                            (e['foto_path'] as String).isNotEmpty &&
                            File(e['foto_path']).existsSync())
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(File(e['foto_path']), fit: BoxFit.cover, width: 60, height: 60),
                          )
                        : Icon(_iconoEstado(estado), color: colorEst, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info Central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e['tipo_equipo'] ?? 'Equipo'} ${e['marca'] ?? ''}'.trim(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nombreCliente,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'S/N: ${e['numero_serie'] ?? '-'}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                
                // Badge de Estado y Flecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorEst.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: TextStyle(color: colorEst, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Componente auxiliar para las métricas superior ---
class _CardMetricaEquipos extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaEquipos({required this.titulo, required this.valor, required this.color, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: color, size: 18),
              Text(valor, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}