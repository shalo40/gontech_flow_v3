import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import 'repuesto_modal.dart';
import 'bitacora_tecnica_screen.dart'; // <--- IMPORTAMOS LA NUEVA PANTALLA

class ReparacionDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> reparacion;

  const ReparacionDetalleScreen({super.key, required this.reparacion});

  @override
  State<ReparacionDetalleScreen> createState() => _ReparacionDetalleScreenState();
}

class _ReparacionDetalleScreenState extends State<ReparacionDetalleScreen> {
  bool _procesando = false;
  late Map<String, dynamic> _reparacionActual; // 🚀 ESTADO EN VIVO PARA UI INSTANTÁNEA

  @override
  void initState() {
    super.initState();
    _reparacionActual = Map<String, dynamic>.from(widget.reparacion);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<HelpdeskProvider>();
    await provider.recargarRepuestos(); 
    await provider.recargarReparaciones(); 
    
    // Si Laravel devolvió datos frescos, actualizamos nuestro estado local
    final rActualizada = provider.reparaciones.firstWhere(
      (rep) => (rep['id_reparacion'] ?? rep['id']) == _getReparacionId(), 
      orElse: () => _reparacionActual
    );
    if (mounted) setState(() => _reparacionActual = Map<String, dynamic>.from(rActualizada));
  }

  int _getDiagnosticoId() => int.tryParse((_reparacionActual['id_diagnostico'] ?? _reparacionActual['diagnostico_id'] ?? '0').toString()) ?? 0;
  int _getReparacionId() => int.tryParse((_reparacionActual['id_reparacion'] ?? _reparacionActual['id'] ?? '0').toString()) ?? 0;

  String _getNested(String localKey, List<String> apiPath, [String fallback = '-']) {
    final r = _reparacionActual;
    if (r.containsKey(localKey) && r[localKey] != null && r[localKey].toString().isNotEmpty) return r[localKey].toString();
    dynamic current = r;
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

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'instalado': case 'finalizada': return Colors.greenAccent;
      case 'rechazado': return Colors.redAccent;
      case 'en_proceso': return Colors.amberAccent;
      case 'por_iniciar': return Colors.orangeAccent;
      case 'entregada': return Colors.blueAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'instalado': case 'finalizada': return Icons.verified;
      case 'rechazado': return Icons.cancel;
      case 'en_proceso': return Icons.engineering;
      case 'por_iniciar': return Icons.power_settings_new;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final r = _reparacionActual;
    final idReparacion = _getReparacionId();
    final idDiagnostico = _getDiagnosticoId();
    
    final repuestosAsociados = provider.repuestos.where((rep) => 
      rep['id_diagnostico'] == idDiagnostico || rep['diagnostico_id'] == idDiagnostico
    ).toList();

    final isLoading = provider.loading || _procesando;
    
    final cliente = _getNested('cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'], 'Sin cliente');
    final marca = _getNested('marca', ['diagnostico', 'ingreso', 'equipo', 'marca'], 'Equipo');
    final modelo = _getNested('modelo', ['diagnostico', 'ingreso', 'equipo', 'modelo'], '');
    final falla = _getNested('descripcion_falla', ['diagnostico', 'descripcion_falla'], 'Sin detalle de falla');
    final estado = (r['estado'] ?? 'pendiente').toString().toLowerCase();
    final colorEst = _colorEstado(estado);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: const Text('Quirófano Técnico', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.tealAccent), onPressed: _cargarDatos)],
      ),
      floatingActionButton: estado != 'entregada' && estado != 'finalizada' ? FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, elevation: 4,
        icon: const Icon(Icons.add_shopping_cart, size: 20),
        label: const Text('Añadir Insumo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await mostrarRepuestoModal(context: context, idReferencia: idDiagnostico, origen: 'reparacion');
          _cargarDatos();
        },
      ) : null,
      
      // 🚀 LA BOTONERA INTELIGENTE
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.black45, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
        child: SafeArea(
          child: Row(
            children: [
              if (estado == 'por_iniciar')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cambiarEstadoReparacion(idReparacion, 'en_proceso'),
                    icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                    label: const Text('Comenzar Reparación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                )
              else if (estado == 'en_proceso')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // 🚀 NAVEGAMOS A LA PANTALLA TÉCNICA
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BitacoraTecnicaScreen(idReparacion: idReparacion, notasActuales: r['notas'] ?? '')),
                      );
                      if (resultado == true) _cargarDatos();
                    },
                    icon: const Icon(Icons.hardware, size: 20, color: Colors.black),
                    label: const Text('Mesa de Trabajo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                )
              else if (estado == 'finalizada')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _cambiarEstadoReparacion(idReparacion, 'entregada'),
                    icon: const Icon(Icons.rocket_launch, size: 20, color: Colors.white),
                    label: const Text('Mandar a Entregas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                )
              else
                 Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.lock, size: 16),
                    label: const Text('Equipo cerrado y entregado'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), disabledForegroundColor: Colors.white38),
                  ),
                )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ HEADER
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colorEst.withOpacity(0.2), AppColors.fondo], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20), border: Border.all(color: colorEst.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: colorEst.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(_iconoEstado(estado), color: colorEst, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(estado.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: colorEst, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('$marca $modelo'.trim(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(cliente, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 📋 SECCIÓN 1: HOJA CLÍNICA
                const _SeccionTitulo(titulo: 'Hoja Clínica', icono: Icons.medical_information_outlined),
                _TarjetaContenedor(
                  hijos: [
                    _InfoRow(label: 'Diagnóstico Original:', valor: falla, colorValor: Colors.orangeAccent),
                    const Divider(color: Colors.white12, height: 24),
                    _InfoRow(label: 'Instrucción Comercial:', valor: r['descripcion'] ?? 'Sin instrucciones.', colorValor: Colors.white),
                    const Divider(color: Colors.white12, height: 24),
                    _InfoRow(label: 'Bitácora del Técnico:', valor: r['notas'] ?? 'Aún no se ha registrado trabajo.', colorValor: Colors.white54, esNota: true),
                    const Divider(color: Colors.white12, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FechaBadge(label: 'Ingresó a mesa', fecha: _formatearFecha(r['fecha_inicio'])),
                        _FechaBadge(label: 'Terminado', fecha: _formatearFecha(r['fecha_fin'])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 📦 SECCIÓN 2: INSUMOS Y REPUESTOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SeccionTitulo(titulo: 'Insumos Utilizados', icono: Icons.inventory_2_outlined),
                    if (repuestosAsociados.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text('${repuestosAsociados.length} Registrados', style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
                const SizedBox(height: 8),

                if (repuestosAsociados.isEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                    child: const Column(
                      children: [
                        Icon(Icons.widgets_outlined, color: Colors.white24, size: 40),
                        SizedBox(height: 12),
                        Text('Sin insumos registrados.\nUsa el botón flotante si necesitas agregar pantallas, flex, pastas, etc.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )
                else
                  ...repuestosAsociados.map((rep) => _CardRepuesto(repuesto: rep, onAccion: (accion) => _procesarAccionRepuesto(rep, accion))),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (isLoading) Container(color: Colors.black.withOpacity(0.4), child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent))),
        ],
      ),
    );
  }

  Future<void> _cambiarEstadoReparacion(int id, String nuevoEstado) async {
    setState(() => _procesando = true);
    try {
      final exito = await context.read<HelpdeskProvider>().actualizarReparacion(id, {'estado': nuevoEstado});
      if (exito && mounted) {
        // 🚀 MAGIA: Actualiza la UI de inmediato sin esperar el reload largo
        setState(() => _reparacionActual['estado'] = nuevoEstado);
        await _cargarDatos(); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _procesarAccionRepuesto(Map<String, dynamic> rep, String accion) async {
    setState(() => _procesando = true);
    try {
      final provider = context.read<HelpdeskProvider>();
      final idRepuesto = int.tryParse(rep['id_repuesto']?.toString() ?? rep['id']?.toString() ?? '0') ?? 0;

      if (accion == 'eliminar') {
        await provider.eliminarRepuesto(idRepuesto); 
      } else {
        await provider.actualizarRepuesto(idRepuesto, {'estado': accion});
      }
      await _cargarDatos(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo; final IconData icono;
  const _SeccionTitulo({required this.titulo, required this.icono});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(children: [Icon(icono, color: Colors.white54, size: 18), const SizedBox(width: 8), Text(titulo.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))]),
    );
  }
}

class _TarjetaContenedor extends StatelessWidget {
  final List<Widget> hijos;
  const _TarjetaContenedor({required this.hijos});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: hijos),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label; final String valor; final Color colorValor; final bool esNota;
  const _InfoRow({required this.label, required this.valor, required this.colorValor, this.esNota = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(valor, style: TextStyle(color: colorValor, fontSize: 14, height: 1.4, fontStyle: esNota ? FontStyle.italic : FontStyle.normal)),
      ],
    );
  }
}

class _FechaBadge extends StatelessWidget {
  final String label; final String fecha;
  const _FechaBadge({required this.label, required this.fecha});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule, color: Colors.white38, size: 14), const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(fecha, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
      ],
    );
  }
}

class _CardRepuesto extends StatelessWidget {
  final Map<String, dynamic> repuesto; final Function(String) onAccion;
  const _CardRepuesto({required this.repuesto, required this.onAccion});

  Color _colorRepuesto(String estado) {
    if (estado == 'instalado') return Colors.greenAccent;
    if (estado == 'rechazado') return Colors.redAccent;
    return Colors.purpleAccent; 
  }

  @override
  Widget build(BuildContext context) {
    final estado = (repuesto['estado'] ?? 'pendiente').toString().toLowerCase();
    final color = _colorRepuesto(estado);
    final costo = double.tryParse(repuesto['costo_unitario']?.toString() ?? '0') ?? 0.0;
    final costoFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0).format(costo);

    return Card(
      color: Colors.black26, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.build_circle, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${repuesto['nombre'] ?? 'Repuesto'} (${repuesto['cantidad'] ?? 1}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2), Text('Proveedor: ${repuesto['proveedor'] ?? 'N/D'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4), Text(costoFormat, style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(estado.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
            if (estado == 'pendiente') ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => onAccion('eliminar')), const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: () => onAccion('rechazado'), icon: const Icon(Icons.close, size: 14), label: const Text('Falló', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), minimumSize: const Size(0, 32))), const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: () => onAccion('instalado'), icon: const Icon(Icons.check, size: 14), label: const Text('Instalado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(0, 32))),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}