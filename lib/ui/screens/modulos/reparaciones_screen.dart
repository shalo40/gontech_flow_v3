import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'reparacion_detalle_screen.dart'; // <--- ✅ INTEGRACIÓN HABILITADA

class ReparacionesScreen extends StatefulWidget {
  const ReparacionesScreen({super.key});

  @override
  State<ReparacionesScreen> createState() => _ReparacionesScreenState();
}

class _ReparacionesScreenState extends State<ReparacionesScreen> {
  String filtroEstado = 'todos';
  String busqueda = '';
  bool _procesando = false; // 🚀 NUEVO: Escudo de protección contra dobles clicks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarReparaciones();
  }

  // --- Helpers de Extracción Segura para Árbol Laravel ---
  String _getCliente(Map<String, dynamic> r) {
    if (r['diagnostico'] != null && r['diagnostico']['ingreso'] != null && r['diagnostico']['ingreso']['equipo'] != null && r['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return r['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente Desconocido';
    }
    return 'Cliente Desconocido';
  }

  String _getEquipoStr(Map<String, dynamic> r) {
    if (r['diagnostico'] != null && r['diagnostico']['ingreso'] != null && r['diagnostico']['ingreso']['equipo'] != null) {
      final eq = r['diagnostico']['ingreso']['equipo'];
      return '${eq['tipo_equipo'] ?? ''} ${eq['marca'] ?? ''} ${eq['modelo'] ?? ''}'.trim();
    }
    return 'Equipo Desconocido';
  }

  String _getFalla(Map<String, dynamic> r) {
    if (r['diagnostico'] != null) {
      return r['diagnostico']['descripcion_falla'] ?? 'Sin detalle de falla';
    }
    return 'Sin detalle';
  }

  int _getId(Map<String, dynamic> r) => int.tryParse((r['id_reparacion'] ?? r['id'] ?? '0').toString()) ?? 0;

  // --- Helpers Visuales ---
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'por_iniciar': return Colors.redAccent;
      case 'en_proceso': return Colors.amberAccent;
      case 'finalizada': return Colors.greenAccent;
      case 'entregada': return Colors.blueAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'por_iniciar': return Icons.power_settings_new;
      case 'en_proceso': return Icons.engineering;
      case 'finalizada': return Icons.verified;
      case 'entregada': return Icons.rocket_launch;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final reparaciones = provider.reparaciones;
    final isLoading = provider.loading || _procesando; // 🚀 Sumamos el estado local

    // Acumuladores para el Tablero
    int porIniciar = 0;
    int enProceso = 0;
    int finalizadas = 0;

    final filtrados = reparaciones.where((r) {
      final estado = (r['estado'] ?? 'por_iniciar').toString().toLowerCase();
      
      // Contadores del Dashboard
      if (estado == 'por_iniciar') porIniciar++;
      if (estado == 'en_proceso') enProceso++;
      if (estado == 'finalizada') finalizadas++;

      final cliente = _getCliente(r).toLowerCase();
      final equipo = _getEquipoStr(r).toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda = cliente.contains(query) || equipo.contains(query);
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();

    return LayoutPrincipal(
      titulo: 'Laboratorio Técnico',
      child: Stack( // 🚀 STACK PARA EL LOADER
        children: [
          Column(
            children: [
              // 📊 1. TABLERO KANBAN SUPERIOR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: _CardMetricaLab(titulo: 'En Cola', valor: porIniciar.toString(), color: Colors.redAccent, icono: Icons.inbox)),
                    const SizedBox(width: 8),
                    Expanded(child: _CardMetricaLab(titulo: 'En Mesa', valor: enProceso.toString(), color: Colors.amberAccent, icono: Icons.engineering)),
                    const SizedBox(width: 8),
                    Expanded(child: _CardMetricaLab(titulo: 'Listos', valor: finalizadas.toString(), color: Colors.greenAccent, icono: Icons.verified)),
                  ],
                ),
              ),

              // 🔍 2. BUSCADOR Y FILTROS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => busqueda = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente o equipo...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                    filled: true,
                    fillColor: AppColors.fondo.withOpacity(0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _chipFiltro('todos', 'Todas', Icons.list),
                    _chipFiltro('por_iniciar', 'Por Iniciar', Icons.power_settings_new),
                    _chipFiltro('en_proceso', 'En Proceso', Icons.engineering),
                    _chipFiltro('finalizada', 'Finalizadas', Icons.check_circle),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 📋 3. LISTADO DE ÓRDENES DE TRABAJO
              Expanded(
                child: provider.loading && filtrados.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                    : filtrados.isEmpty
                        ? const Center(child: Text('No hay equipos en esta bandeja.', style: TextStyle(color: Colors.white54)))
                        : RefreshIndicator(
                            color: Colors.tealAccent,
                            backgroundColor: AppColors.fondo,
                            onRefresh: _cargar,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filtrados.length,
                              itemBuilder: (context, index) {
                                final r = filtrados[index];
                                final id = _getId(r);
                                final estado = (r['estado'] ?? 'por_iniciar').toString().toLowerCase();
                                final cliente = _getCliente(r);
                                final equipo = _getEquipoStr(r);
                                final falla = _getFalla(r);

                                final fechaRaw = r['created_at'] ?? '';
                                final fecha = fechaRaw.isNotEmpty ? DateFormat('dd/MM HH:mm').format(DateTime.parse(fechaRaw.toString())) : '-';

                                return Card(
                                  color: AppColors.fondo.withOpacity(0.85),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: _colorEstado(estado).withOpacity(0.3), width: 1),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      // 🚀 NAVEGACIÓN TÁCTIL (Tocar la tarjeta)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ReparacionDetalleScreen(reparacion: r)),
                                      ).then((_) => _cargar()); // 🔄 Recarga al volver
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Fila 1: Estado y Fecha
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(color: _colorEstado(estado).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                                child: Row(
                                                  children: [
                                                    Icon(_iconoEstado(estado), color: _colorEstado(estado), size: 14),
                                                    const SizedBox(width: 6),
                                                    Text(estado.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: _colorEstado(estado), fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                              Text('Ingreso: $fecha', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Fila 2: Cliente y Equipo
                                          Text(equipo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 2),
                                          Text(cliente, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                          const SizedBox(height: 12),

                                          // Fila 3: Falla a reparar
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.bug_report, color: Colors.white38, size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(falla, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Fila 4: Botonera de Acción Directa
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (estado == 'por_iniciar')
                                                ElevatedButton.icon(
                                                  onPressed: () => _cambiarEstado(id, 'en_proceso'),
                                                  icon: const Icon(Icons.play_arrow, size: 16, color: Colors.black),
                                                  label: const Text('Comenzar Reparación', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, minimumSize: const Size(0, 36)),
                                                )
                                              else if (estado == 'en_proceso') ...[
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    // 🚀 NAVEGACIÓN DESDE EL BOTÓN
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => ReparacionDetalleScreen(reparacion: r)),
                                                    ).then((_) => _cargar()); // 🔄 Recarga al volver
                                                  },
                                                  icon: const Icon(Icons.build, size: 16, color: Colors.tealAccent),
                                                  label: const Text('Quirófano', style: TextStyle(color: Colors.tealAccent)),
                                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.tealAccent), minimumSize: const Size(0, 36)),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  onPressed: () => _cambiarEstado(id, 'finalizada'),
                                                  icon: const Icon(Icons.check, size: 16, color: Colors.black),
                                                  label: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(0, 36)),
                                                ),
                                              ] else if (estado == 'finalizada')
                                                ElevatedButton.icon(
                                                  onPressed: () => _cambiarEstado(id, 'entregada'),
                                                  icon: const Icon(Icons.rocket_launch, size: 16, color: Colors.white),
                                                  label: const Text('Mandar a Entregas', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, minimumSize: const Size(0, 36)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          
          // 🚀 LOADER FLOTANTE (Bloquea la pantalla mientras procesa)
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
            ),
        ],
      ),
    );
  }

  // --- Lógica del Flujo hacia Laravel ---
  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    setState(() => _procesando = true); // Bloquea la UI
    try {
      final provider = context.read<HelpdeskProvider>();
      final exito = await provider.actualizarReparacion(id, {'estado': nuevoEstado});
      
      if (exito && mounted) {
        await _cargar(); // Refresca Kanban
        
        String msj = '';
        if (nuevoEstado == 'en_proceso') msj = '🛠️ Equipo en mesa de trabajo.';
        if (nuevoEstado == 'finalizada') msj = '✅ ¡Excelente! Reparación terminada.';
        if (nuevoEstado == 'entregada') msj = '🚀 Enviado a la bandeja de Entregas.';

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _procesando = false); // Desbloquea la UI
    }
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
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.white70, fontSize: 12, fontWeight: activo ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        selected: activo,
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }
}

class _CardMetricaLab extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaLab({required this.titulo, required this.valor, required this.color, required this.icono});

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