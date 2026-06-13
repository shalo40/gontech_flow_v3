import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import '../../layout/layout_principal.dart';
import 'firma_modal.dart';
// import '../../reports/pdf_entrega.dart';
// import '../../reports/pdf_utils.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  String filtroEstado = 'todos';
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    // Si tienes un método específico para entregas en tu Provider, úsalo aquí.
    // Por ahora, asumimos que tienes un recargarEntregas() o lo crearás pronto.
    try {
      await (context.read<HelpdeskProvider>() as dynamic).recargarEntregas();
    } catch (_) {
      // Fallback silencioso por si aún no has creado el método en el Provider
    }
  }

  // --- Helpers de Extracción Segura ---
  String _getNested(Map<String, dynamic> e, String localKey, List<String> apiPath, [String fallback = '-']) {
    if (e.containsKey(localKey) && e[localKey] != null && e[localKey].toString().isNotEmpty) {
      return e[localKey].toString();
    }
    dynamic current = e;
    for (final key in apiPath) {
      if (current == null || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString().isNotEmpty ? current.toString() : fallback;
  }

  String _formatearFecha(String? fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().trim().isEmpty) return 'No registrada';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fechaRaw.toString()));
    } catch (_) {
      return fechaRaw.toString();
    }
  }

  int _getId(Map<String, dynamic> e) => int.tryParse((e['id_entrega'] ?? e['id'] ?? '0').toString()) ?? 0;

  // --- Estilos Visuales ---
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado': return Colors.greenAccent;
      case 'pendiente': return Colors.amberAccent;
      case 'anulado': return Colors.redAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado': return Icons.verified;
      case 'pendiente': return Icons.inventory_2;
      case 'anulado': return Icons.cancel;
      default: return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ MOCK TEMPORAL: Como tu Provider aún no tiene 'entregas',
    // estoy mockeando una lista vacía para que no se caiga la app.
    // Cámbialo a `provider.entregas` cuando lo implementes en HelpdeskProvider.
    final provider = context.watch<HelpdeskProvider>();
    final List<dynamic> entregasRaw = provider.entregas;
    
    final isLoading = provider.loading;

    // Acumuladores para el Tablero
    int pendientes = 0;
    int completadas = 0;

    final filtradas = entregasRaw.where((e) {
      final estado = (e['estado'] ?? 'pendiente').toString().toLowerCase();
      
      if (estado == 'pendiente') pendientes++;
      if (estado == 'entregado') completadas++;

      final cliente = (e['nombre_receptor'] ?? '').toString().toLowerCase();
      final rut = (e['rut_receptor'] ?? '').toString().toLowerCase();
      final query = busqueda.toLowerCase();

      final coincideBusqueda = cliente.contains(query) || rut.contains(query);
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();

    return LayoutPrincipal(
      titulo: 'Mostrador de Salida',
      child: Column(
        children: [
          // 📊 1. TABLERO KANBAN SUPERIOR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CardMetricaMostrador(
                    titulo: 'Por Entregar', 
                    valor: pendientes.toString(), 
                    color: Colors.amberAccent, 
                    icono: Icons.inventory_2
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardMetricaMostrador(
                    titulo: 'Entregados', 
                    valor: completadas.toString(), 
                    color: Colors.greenAccent, 
                    icono: Icons.verified
                  )
                ),
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
                hintText: 'Buscar cliente o RUT...',
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
                _chipFiltro('pendiente', 'Pendientes', Icons.inventory_2),
                _chipFiltro('entregado', 'Entregados', Icons.verified),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 📋 3. LISTADO DE ENTREGAS
          Expanded(
            child: isLoading && filtradas.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : filtradas.isEmpty
                    ? const Center(child: Text('No hay equipos en el mostrador.', style: TextStyle(color: Colors.white54)))
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        backgroundColor: AppColors.fondo,
                        onRefresh: _cargarDatos,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtradas.length,
                          itemBuilder: (context, index) {
                            final e = filtradas[index];
                            final estado = (e['estado'] ?? 'pendiente').toString().toLowerCase();
                            final colorEst = _colorEstado(estado);
                            
                            // Extracción de info (adaptado para soportar estructura anidada si viene de la relación)
                            final cliente = e['nombre_receptor'] ?? _getNested(e, 'cliente', ['reparacion', 'diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'], 'Cliente Desconocido');
                            final rut = e['rut_receptor'] ?? _getNested(e, 'rut', ['reparacion', 'diagnostico', 'ingreso', 'equipo', 'cliente', 'rut'], 'Sin RUT');
                            final equipoDetalle = _getNested(e, 'equipo_str', ['reparacion', 'diagnostico', 'ingreso', 'equipo', 'marca'], 'Equipo de reparación');
                            
                            final fecha = _formatearFecha(e['created_at']);

                            return Card(
                              color: AppColors.fondo.withOpacity(0.85),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: colorEst.withOpacity(0.3), width: 1),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _mostrarDetalleEntrega(context, e),
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
                                            decoration: BoxDecoration(color: colorEst.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              children: [
                                                Icon(_iconoEstado(estado), color: colorEst, size: 14),
                                                const SizedBox(width: 6),
                                                Text(estado.toUpperCase(), style: TextStyle(color: colorEst, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Text('Ingreso: $fecha', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Fila 2: Cliente y Equipo
                                      Text(cliente, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('RUT: $rut', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text(equipoDetalle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      
                                      // Fila 3: Botón de Acción Directa (Firma)
                                      if (estado == 'pendiente') ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                // 🚀 ABRIR EL PAD DE FIRMA
                                                mostrarFirmaModal(
                                                  context,
                                                  _getId(e), // ID de la entrega
                                                  e,         // Todos los datos de la entrega
                                                  _cargarDatos // Para que recargue al éxito
                                                );
                                              },
                                              icon: const Icon(Icons.draw, size: 16, color: Colors.black),
                                              label: const Text('Entregar y Firmar', style: TextStyle(fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.tealAccent, 
                                                foregroundColor: Colors.black, 
                                                minimumSize: const Size(0, 36)
                                              ),
                                            ),
                                          ],
                                        ),
                                      ]
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
    );
  }

  // --- Modal de Detalle (Rediseñado) ---
  void _mostrarDetalleEntrega(BuildContext context, Map<String, dynamic> e) {
    final estado = (e['estado'] ?? 'pendiente').toString().toLowerCase();
    final colorEst = _colorEstado(estado);
    final tieneFirma = e['firma_path'] != null && e['firma_path'].toString().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondo.withOpacity(0.98),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del Modal
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colorEst.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(_iconoEstado(estado), color: colorEst, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Comprobante de Salida', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(estado.toUpperCase(), style: TextStyle(color: colorEst, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info Contenedor
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRowModal(label: 'Titular Retira:', valor: e['nombre_receptor'] ?? 'Desconocido'),
                      const Divider(color: Colors.white12, height: 20),
                      _InfoRowModal(label: 'RUT:', valor: e['rut_receptor'] ?? 'Sin RUT'),
                      const Divider(color: Colors.white12, height: 20),
                      _InfoRowModal(label: 'Equipo / Trabajo:', valor: e['descripcion_reparacion'] ?? 'Detalle no disponible'),
                      const Divider(color: Colors.white12, height: 20),
                      _InfoRowModal(label: 'Fecha de Entrega:', valor: _formatearFecha(e['fecha_entrega'])),
                      if ((e['observaciones'] ?? '').isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 20),
                        _InfoRowModal(label: 'Observaciones:', valor: e['observaciones'], colorValor: Colors.orangeAccent),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),

              // Sección de Firma
                const Text('Firma del Titular', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (tieneFirma)
                  Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Image.network(
                      // 🌐 ASUMIENDO QUE TU API LOCAL ESTÁ EN ESTA RUTA (Cámbiala si es diferente)
                      'http://10.0.2.2:8000/storage/${e['firma_path']}', 
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('❌ Error al cargar la firma del servidor', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Text('Pendiente de firma en mostrador', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                    ),
                  ),

                const SizedBox(height: 24),

                // Botones Finales
                if (!tieneFirma && estado == 'pendiente')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.draw, color: Colors.black),
                      label: const Text('Registrar Firma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        // TODO: Abrir Modal de Firma
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrir pad de firma... ✍️')));
                      },
                    ),
                  )
                else if (tieneFirma || estado == 'entregado')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF de Salida', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent, side: const BorderSide(color: Colors.tealAccent), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        // TODO: Lógica PDF
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando PDF... 📄')));
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
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

// --- Componentes Visuales ---
class _CardMetricaMostrador extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaMostrador({required this.titulo, required this.valor, required this.color, required this.icono});

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

class _InfoRowModal extends StatelessWidget {
  final String label;
  final String valor;
  final Color? colorValor;

  const _InfoRowModal({required this.label, required this.valor, this.colorValor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13))),
        Expanded(flex: 3, child: Text(valor, style: TextStyle(color: colorValor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ],
    );
  }
}