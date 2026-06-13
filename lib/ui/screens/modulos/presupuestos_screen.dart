import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'presupuesto_detalle_screen.dart'; // <--- IMPORTACIÓN DE LA NUEVA PANTALLA DE DETALLE

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
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

  // --- Helpers de Extracción Segura para Árbol Laravel ---
  String _getCliente(Map<String, dynamic> p) {
    if (p['diagnostico'] != null && 
        p['diagnostico']['ingreso'] != null && 
        p['diagnostico']['ingreso']['equipo'] != null && 
        p['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return p['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente Desconocido';
    }
    return p['cliente']?.toString() ?? 'Cliente Desconocido';
  }

  String _getMarca(Map<String, dynamic> p) {
    if (p['diagnostico'] != null && p['diagnostico']['ingreso'] != null && p['diagnostico']['ingreso']['equipo'] != null) {
      return p['diagnostico']['ingreso']['equipo']['marca'] ?? 'Equipo';
    }
    return p['marca']?.toString() ?? 'Equipo';
  }

  String _getTipo(Map<String, dynamic> p) {
    if (p['diagnostico'] != null && p['diagnostico']['ingreso'] != null && p['diagnostico']['ingreso']['equipo'] != null) {
      return p['diagnostico']['ingreso']['equipo']['tipo_equipo'] ?? '';
    }
    return p['tipo_equipo']?.toString() ?? '';
  }

  int _getId(Map<String, dynamic> p) => int.tryParse((p['id_presupuesto'] ?? p['id'] ?? '0').toString()) ?? 0;

  // --- Formateador de Moneda Local (CLP) ---
  String _formatearMoneda(dynamic valor) {
    final monto = double.tryParse(valor.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(monto);
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'autorizado': return Colors.greenAccent;
      case 'rechazado': return Colors.redAccent;
      default: return Colors.amberAccent;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'autorizado': return Icons.check_circle_outline;
      case 'rechazado': return Icons.cancel_outlined;
      default: return Icons.hourglass_bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final presupuestos = provider.presupuestos;
    final isLoading = provider.loading;

    // Inicializamos acumuladores financieros para las métricas
    double totalPorAprobar = 0;
    double totalAprobado = 0;

    final filtrados = presupuestos.where((p) {
      final estado = (p['estado'] ?? 'pendiente').toString().toLowerCase();
      final totalItem = double.tryParse(p['total']?.toString() ?? '0') ?? 0.0;

      // Sumatoria en tiempo real según el estado comercial
      if (estado == 'pendiente') totalPorAprobar += totalItem;
      if (estado == 'autorizado') totalAprobado += totalItem;

      if (filtroEstado == 'todos') return true;
      return estado == filtroEstado;
    }).toList();

    return LayoutPrincipal(
      titulo: 'Presupuestos',
      child: Column(
        children: [
          // 📊 1. DASHBOARD FINANCIERO SUPERIOR (Pipeline en CLP)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CardMetricaFinanciera(
                    titulo: 'Por Aprobar',
                    valor: _formatearMoneda(totalPorAprobar),
                    color: Colors.amberAccent,
                    icono: Icons.lock_clock,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardMetricaFinanciera(
                    titulo: 'Aprobado',
                    valor: _formatearMoneda(totalAprobado),
                    color: Colors.greenAccent,
                    icono: Icons.monetization_on,
                  ),
                ),
              ],
            ),
          ),

          // 🎚️ 2. BOTONES DE FILTRO ESTILO CHIP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

          // 📋 3. LISTADO DE COTIZACIONES CON DISEÑO CRM
          Expanded(
            child: isLoading && filtrados.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : filtrados.isEmpty
                    ? const Center(child: Text('No hay cotizaciones en este estado.', style: TextStyle(color: Colors.white54)))
                    : RefreshIndicator(
                        color: Colors.tealAccent,
                        backgroundColor: AppColors.fondo,
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final p = filtrados[index];
                            final estado = (p['estado'] ?? 'pendiente').toString().toLowerCase();
                            final idPresupuesto = _getId(p);
                            final cliente = _getCliente(p);
                            final marca = _getMarca(p);
                            final tipo = _getTipo(p);

                            final fechaRaw = p['fecha_creacion'] ?? p['created_at'];
                            final fecha = fechaRaw != null
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaRaw.toString()))
                                : 'Reciente';

                            return Card(
                              color: AppColors.fondo.withOpacity(0.85),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: InkWell( // <--- 🚀 INTEGRACIÓN: Envoltura táctil de navegación
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PresupuestoDetalleScreen(presupuesto: p),
                                    ),
                                  ).then((_) => _cargar()); // Recarga al volver por si cambió el estado
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Encabezado: Cliente, Estado y Monto destacado
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(_iconoEstado(estado), color: _colorEstado(estado), size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cliente, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                const SizedBox(height: 2),
                                                Text('$tipo $marca • Cotización #$idPresupuesto', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatearMoneda(p['total']),
                                            style: TextStyle(color: _colorEstado(estado), fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Bloque central: Descripción del trabajo
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                                        child: Text(
                                          p['descripcion'] ?? 'Sin descripción de la obra',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Fila de Cierre y Botones de Acción Directa
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Emitido el $fecha', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                          
                                          // Barra de botones inteligentes (Solo si está pendiente)
                                          if (estado == 'pendiente')
                                            Row(
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () => _procesarRespuestaPresupuesto(idPresupuesto, 'rechazado'),
                                                  icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                                  label: const Text('Rechazar', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: Colors.redAccent),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    minimumSize: const Size(0, 30),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  onPressed: () => _procesarRespuestaPresupuesto(idPresupuesto, 'autorizado'),
                                                  icon: const Icon(Icons.check, size: 14, color: Colors.black),
                                                  label: const Text('Aprobar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.greenAccent,
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    minimumSize: const Size(0, 30),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _colorEstado(estado).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                estado.toUpperCase(),
                                                style: TextStyle(color: _colorEstado(estado), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
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
    );
  }

  // --- Lógica del Flujo de Actualización Comercial a Laravel ---
  Future<void> _procesarRespuestaPresupuesto(int id, String decision) async {
    try {
      final provider = context.read<HelpdeskProvider>();
  
      final exito = await provider.actualizarPresupuesto(id, {'estado': decision});      
      if (exito) {
        await _cargar();
        if (mounted) {
          await provider.recargarIngresos();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decision == 'autorizado' 
                ? '🚀 Cotización aprobada. ¡La orden pasó a reparación!' 
                : '❌ Cotización marcada como rechazada.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la cotización: $e'), backgroundColor: Colors.redAccent),
        );
      }
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
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.white70, fontSize: 13, fontWeight: activo ? FontWeight.bold : Alignment.center == null ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        selected: activo,
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }
}

class _CardMetricaFinanciera extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaFinanciera({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor, 
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}