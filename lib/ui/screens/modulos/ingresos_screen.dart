import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/dao/cliente_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'diagnostico_modal.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  final ingresoDao = IngresoDAO();
  final equipoDao = EquipoDao();
  final clienteDao = ClienteDao();
  List<Map<String, dynamic>> ingresos = [];
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await ingresoDao.listarIngresosDetallados();
    setState(() => ingresos = data);
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber;
      case 'en_reparacion':
        return Colors.blueAccent;
      case 'finalizado':
        return Colors.green;
      case 'archivado':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingresosFiltrados = ingresos.where((i) {
      final texto = filtro.toLowerCase();
      return i['nombre_cliente'].toString().toLowerCase().contains(texto) ||
          i['marca'].toString().toLowerCase().contains(texto) ||
          i['tipo_equipo'].toString().toLowerCase().contains(texto);
    }).toList();

    return LayoutPrincipal(
      titulo: 'Ingresos',
      child: Column(
        children: [
          // 🔍 Búsqueda
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o equipo...',
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
              onChanged: (valor) => setState(() => filtro = valor),
            ),
          ),

          // 📋 Lista de ingresos
          Expanded(
            child: ingresosFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ingresos registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: ingresosFiltrados.length,
                    itemBuilder: (context, index) {
                      final i = ingresosFiltrados[index];
                      final estado = i['estado_ingreso'] ?? 'pendiente';

                      return Card(
                        color: AppColors.fondo.withOpacity(0.9),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () => _mostrarDetalles(context, i),
                          leading: CircleAvatar(
                            backgroundColor: Colors.tealAccent.withOpacity(
                              0.15,
                            ),
                            backgroundImage:
                                (i['foto_path'] != null &&
                                    (i['foto_path'] as String).isNotEmpty &&
                                    File(i['foto_path']).existsSync())
                                ? FileImage(File(i['foto_path']))
                                : null,
                            child:
                                (i['foto_path'] == null ||
                                    (i['foto_path'] as String).isEmpty)
                                ? const Icon(
                                    Icons.devices,
                                    color: Colors.tealAccent,
                                  )
                                : null,
                          ),
                          title: Text(
                            '${i['tipo_equipo'] ?? 'Equipo desconocido'} ${i['marca'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cliente: ${i['nombre_cliente'] ?? 'Sin cliente'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    'Estado: ',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Chip(
                                    label: Text(
                                      estado.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _colorEstado(estado),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white54,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🧭 Modal de detalle
  Future<void> _mostrarDetalles(
    BuildContext context,
    Map<String, dynamic> ingreso,
  ) async {
    final estado = ingreso['estado_ingreso'] ?? 'pendiente';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Text(
              'Detalle del ingreso',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.tealAccent.withOpacity(0.15),
              backgroundImage:
                  (ingreso['foto_path'] != null &&
                      (ingreso['foto_path'] as String).isNotEmpty &&
                      File(ingreso['foto_path']).existsSync())
                  ? FileImage(File(ingreso['foto_path']))
                  : null,
              child:
                  (ingreso['foto_path'] == null ||
                      (ingreso['foto_path'] as String).isEmpty)
                  ? const Icon(
                      Icons.devices,
                      color: Colors.tealAccent,
                      size: 40,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              ingreso['nombre_cliente'] ?? 'Sin cliente',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${ingreso['tipo_equipo']} ${ingreso['marca']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                estado.toUpperCase(),
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              backgroundColor: _colorEstado(estado),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Crear diagnóstico'),
            onPressed: () async {
              Navigator.pop(context);
              await mostrarDiagnosticoModal(context, ingreso['id_ingreso']);
              await cargar();
            },
          ),
        ],
      ),
    );
  }
}
