import 'package:flutter/material.dart';
import 'package:gontech_flow_v2/ui/screens/modulos/repuesto_modal.dart';
import 'package:intl/intl.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../theme/app_colors.dart';

class ReparacionDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> reparacion;

  const ReparacionDetalleScreen({super.key, required this.reparacion});

  @override
  State<ReparacionDetalleScreen> createState() =>
      _ReparacionDetalleScreenState();
}

class _ReparacionDetalleScreenState extends State<ReparacionDetalleScreen> {
  final dao = RepuestoDao(); // Mantenemos el DAO para Repuestos hasta su respectiva migración
  List<Map<String, dynamic>> repuestos = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  // --- Helpers de compatibilidad API / Local ---
  String _getNested(String localKey, List<String> apiPath, [String fallback = '-']) {
    final r = widget.reparacion;
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

  int _getDiagnosticoId() {
    return int.tryParse((widget.reparacion['id_diagnostico'] ?? widget.reparacion['diagnostico_id'] ?? '0').toString()) ?? 0;
  }

  int _getReparacionId() {
    return int.tryParse((widget.reparacion['id_reparacion'] ?? widget.reparacion['id'] ?? '0').toString()) ?? 0;
  }

  String _formatearFecha(String? fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().trim().isEmpty) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fechaRaw.toString()));
    } catch (_) {
      return fechaRaw.toString();
    }
  }
  // ---------------------------------------------

  Future<void> cargar() async {
    final data = await dao.listarPorDiagnostico(_getDiagnosticoId());
    if (mounted) {
      setState(() => repuestos = data);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'instalado':
      case 'finalizada':
        return Colors.greenAccent;
      case 'rechazado':
        return Colors.redAccent;
      case 'en_proceso':
        return Colors.blueAccent;
      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reparacion;
    
    // Extracción segura de datos
    final cliente = _getNested('cliente', ['diagnostico', 'ingreso', 'equipo', 'cliente', 'nombre'], 'Sin cliente');
    final marca = _getNested('marca', ['diagnostico', 'ingreso', 'equipo', 'marca'], '');
    final modelo = _getNested('modelo', ['diagnostico', 'ingreso', 'equipo', 'modelo'], '');
    final falla = _getNested('descripcion_falla', ['diagnostico', 'descripcion_falla']);
    final estado = (r['estado'] ?? 'pendiente').toString();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        title: const Text('Detalle de reparación', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: cargar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Agregar repuesto'),
        onPressed: () async {
          await mostrarRepuestoModal(
            context: context,
            idReferencia: _getReparacionId(),
            origen: 'reparacion',
          );
          await cargar();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🔧 Datos de la reparación
            Card(
              color: AppColors.fondo.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$marca $modelo',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Divider(height: 20, color: Colors.white24),
                    Text(
                      'Diagnóstico: $falla',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Descripción: ${r['descripcion'] ?? '-'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notas: ${r['notas'] ?? '-'}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${estado.toUpperCase()}',
                      style: TextStyle(color: _colorEstado(estado), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inicio: ${_formatearFecha(r['fecha_inicio'])}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    Text(
                      'Fin: ${_formatearFecha(r['fecha_fin'])}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🧩 Lista de repuestos asociados
            Text(
              'Repuestos instalados (${repuestos.length})',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (repuestos.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No hay repuestos asociados a esta reparación.',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(children: repuestos.map((rep) => _cardRepuesto(rep)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _cardRepuesto(Map<String, dynamic> rep) {
    final estado = rep['estado'] ?? 'pendiente';
    return Card(
      color: AppColors.fondo.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.build, color: _colorEstado(estado)),
        title: Text(
          '${rep['nombre'] ?? 'Repuesto'} (${rep['cantidad'] ?? 1}x)',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Proveedor: ${rep['proveedor'] ?? 'N/D'}\n'
          'Costo: \$${rep['costo_unitario']?.toStringAsFixed(0) ?? '0'} CLP\n'
          'Estado: ${estado.toUpperCase()}',
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.fondo,
          onSelected: (opcion) async {
            if (opcion == 'instalado' || opcion == 'rechazado') {
              await dao.actualizarEstado(rep['id_repuesto'], opcion);
              await cargar();
            } else if (opcion == 'eliminar') {
              await dao.eliminar(rep['id_repuesto']);
              await cargar();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'instalado',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('Marcar instalado', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rechazado',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Marcar rechazado', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}