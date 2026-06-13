import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

class PresupuestoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> presupuesto;

  const PresupuestoDetalleScreen({super.key, required this.presupuesto});

  @override
  State<PresupuestoDetalleScreen> createState() => _PresupuestoDetalleScreenState();
}

class _PresupuestoDetalleScreenState extends State<PresupuestoDetalleScreen> {
  bool _procesando = false;

  // --- Helpers de Extracción Segura ---
  String _getNested(Map<String, dynamic> data, List<String> path, [String fallback = '']) {
    dynamic current = data;
    for (final key in path) {
      if (current == null || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString().isNotEmpty ? current.toString() : fallback;
  }

  int _getId() => int.tryParse((widget.presupuesto['id_presupuesto'] ?? widget.presupuesto['id'] ?? '0').toString()) ?? 0;

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
      case 'autorizado': return Icons.check_circle;
      case 'rechazado': return Icons.cancel;
      default: return Icons.hourglass_bottom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.presupuesto;
    final estado = (p['estado'] ?? 'pendiente').toString().toLowerCase();
    final colorEst = _colorEstado(estado);
    final idPresupuesto = _getId();

    // Extracción de datos del árbol
    final cliente = _getNested(p, ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'], 'Cliente Desconocido');
    final telefono = _getNested(p, ['diagnostico', 'ingreso', 'equipo', 'cliente', 'telefono'], 'Sin teléfono');
    final marca = _getNested(p, ['diagnostico', 'ingreso', 'equipo', 'marca'], 'Equipo');
    final modelo = _getNested(p, ['diagnostico', 'ingreso', 'equipo', 'modelo'], '');
    final diagnosticoInfo = _getNested(p, ['diagnostico', 'descripcion_falla'], 'Sin detalles técnicos previos');
    
    final fechaRaw = p['fecha_creacion'] ?? p['created_at'] ?? '';
    final fechaStr = fechaRaw.isNotEmpty ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fechaRaw.toString())) : 'Fecha desconocida';

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Cotización #$idPresupuesto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.tealAccent),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generador de PDF en construcción 🚧')));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ CABECERA FINANCIERA (EL TICKET)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorEst.withOpacity(0.2), AppColors.fondo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorEst.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(_iconoEstado(estado), color: colorEst, size: 48),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: colorEst.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(estado.toUpperCase(), style: TextStyle(color: colorEst, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      const Text('TOTAL ESTIMADO', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                      Text(
                        _formatearMoneda(p['total']),
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text('Emitido: $fechaStr', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 👤 SECCIÓN 1: CLIENTE Y EQUIPO
                const _SeccionTitulo(titulo: 'Datos del Servicio', icono: Icons.assignment_ind_outlined),
                _TarjetaInfo(
                  hijos: [
                    _DatoFila(label: 'Cliente', valor: cliente, icono: Icons.person_outline),
                    const Divider(color: Colors.white12, height: 24),
                    _DatoFila(label: 'Contacto', valor: telefono, icono: Icons.phone_outlined),
                    const Divider(color: Colors.white12, height: 24),
                    _DatoFila(label: 'Equipo a reparar', valor: '$marca $modelo'.trim(), icono: Icons.devices),
                  ],
                ),
                const SizedBox(height: 20),

                // 🛠️ SECCIÓN 2: DESGLOSE DEL TRABAJO
                const _SeccionTitulo(titulo: 'Detalle de la Obra', icono: Icons.build_circle_outlined),
                _TarjetaInfo(
                  hijos: [
                    const Text('TRABAJO A REALIZAR:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      p['descripcion'] ?? 'Sin descripción.',
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white12, height: 1),
                    ),
                    const Text('BASADO EN DIAGNÓSTICO:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.biotech, color: Colors.white38, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(diagnosticoInfo, style: const TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Espacio para botones
              ],
            ),
          ),

          // 🚀 CAPA DE CARGA (Para cuando se aprieta un botón)
          if (_procesando)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
            ),
        ],
      ),
      
      // 🎛️ BOTONERA TÁCTICA FLOTANTE (Solo si está pendiente)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: estado == 'pendiente' && !_procesando
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      label: const Text('Rechazar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                        elevation: 0,
                      ),
                      onPressed: () => _procesarRespuesta('rechazado'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.black, size: 20),
                      label: const Text('Aprobar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                      ),
                      onPressed: () => _procesarRespuesta('autorizado'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // --- Lógica del Flujo a Laravel ---
  Future<void> _procesarRespuesta(String decision) async {
    setState(() => _procesando = true);
    try {
      final provider = context.read<HelpdeskProvider>();
      final idPresupuesto = _getId();
      
      final exito = await provider.actualizarPresupuesto(idPresupuesto, {'estado': decision});
      
      if (exito && mounted) {
        // Refrescamos datos globales
        await provider.recargarPresupuestos();
        await provider.recargarIngresos();
        
        Navigator.pop(context); // Volvemos a la lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'autorizado' ? '✅ Cotización Aprobada. A reparar!' : '❌ Cotización Rechazada.'),
            backgroundColor: decision == 'autorizado' ? Colors.green.shade800 : Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }
}

// --- Componentes UI Auxiliares ---
class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icono, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(titulo.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final List<Widget> hijos;
  const _TarjetaInfo({required this.hijos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: hijos),
    );
  }
}

class _DatoFila extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  const _DatoFila({required this.label, required this.valor, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: Colors.tealAccent.withOpacity(0.7), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}