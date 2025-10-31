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
  final dao = RepuestoDao();
  List<Map<String, dynamic>> repuestos = [];
  final formato = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await dao.listarPorDiagnostico(
      widget.reparacion['id_diagnostico'],
    );
    setState(() => repuestos = data);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'instalado':
        return Colors.greenAccent;
      case 'rechazado':
        return Colors.redAccent;
      default:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reparacion;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        title: const Text('Detalle de reparación'),
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
            idReferencia: r['id_reparacion'],
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
                      r['cliente'] ?? 'Sin cliente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${r['marca'] ?? ''} ${r['modelo'] ?? ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Divider(height: 20, color: Colors.white24),
                    Text(
                      'Diagnóstico: ${r['descripcion_falla'] ?? '-'}',
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
                      'Estado: ${(r['estado'] ?? '').toUpperCase()}',
                      style: TextStyle(color: _colorEstado(r['estado'] ?? '')),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inicio: ${r['fecha_inicio'] ?? '-'}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    Text(
                      'Fin: ${r['fecha_fin'] ?? '-'}',
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
              Column(children: repuestos.map((r) => _cardRepuesto(r)).toList()),
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
                  Text('Marcar instalado'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rechazado',
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
