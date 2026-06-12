import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'diagnostico_modal.dart';
import 'package:intl/intl.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarIngresos();
  }

  // --- Helpers de Extracción Segura (Soporte Laravel API / SQLite Local) ---
  int _getId(Map<String, dynamic> i) {
    return int.tryParse((i['id_ingreso'] ?? i['id'] ?? '0').toString()) ?? 0;
  }

  String _getCliente(Map<String, dynamic> i) {
    if (i['nombre_cliente'] != null) return i['nombre_cliente'].toString();
    if (i['equipo'] != null && i['equipo']['cliente'] != null) {
      return i['equipo']['cliente']['nombre'] ?? 'Sin cliente';
    }
    return 'Sin cliente';
  }

  String _getEquipoTexto(Map<String, dynamic> i) {
    String tipo = 'Equipo';
    String marca = '';
    String modelo = '';

    if (i['equipo'] != null) {
      tipo = i['equipo']['tipo_equipo'] ?? tipo;
      marca = i['equipo']['marca'] ?? '';
      modelo = i['equipo']['modelo'] ?? '';
    } else {
      tipo = i['tipo_equipo'] ?? tipo;
      marca = i['marca'] ?? '';
      modelo = i['modelo'] ?? '';
    }
    return '$tipo • $marca $modelo'.trim();
  }

  String _getEstado(Map<String, dynamic> i) {
    return i['estado'] ?? i['estado_ingreso'] ?? 'ingresado';
  }

  String _getAccesorios(Map<String, dynamic> i) {
    return i['accesorios_entregados'] ?? i['accesorios'] ?? 'Sin accesorios';
  }

  String _getFotoPath(Map<String, dynamic> i) {
    if (i['equipo'] != null && i['equipo']['foto_path'] != null) {
      return i['equipo']['foto_path'].toString();
    }
    return i['foto_path']?.toString() ?? '';
  }
  // ------------------------------------------------------------------------

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ingresado':
      case 'pendiente_diagnostico':
        return Colors.orangeAccent;
      case 'pendiente_aprobacion':
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

  String _textoEstado(String estado) {
    switch (estado) {
      case 'ingresado':
      case 'pendiente_diagnostico':
        return 'Pendiente de diagnóstico';
      case 'pendiente_aprobacion':
        return 'Pendiente de aprobación';
      case 'en_reparacion':
        return 'En reparación';
      case 'finalizado':
        return 'Finalizado';
      case 'archivado':
        return 'Archivado';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado global del taller reactivamente
    final ingresos = context.watch<HelpdeskProvider>().ingresos;
    final isLoading = context.watch<HelpdeskProvider>().loading;

    final ingresosFiltrados = ingresos.where((i) {
      final texto = _filtro.toLowerCase();
      final cliente = _getCliente(i).toLowerCase();
      final equipo = _getEquipoTexto(i).toLowerCase();
      return cliente.contains(texto) || equipo.contains(texto);
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
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
          ),

          // 📋 Lista de ingresos con soporte de actualización por arrastre
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: isLoading && ingresos.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : ingresosFiltrados.isEmpty
                      ? Center(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              Center(
                                child: const Text(
                                  'No hay ingresos registrados',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: ingresosFiltrados.length,
                          itemBuilder: (context, index) {
                            final i = ingresosFiltrados[index];
                            final estado = _getEstado(i);
                            final clienteName = _getCliente(i);
                            final equipoDesc = _getEquipoTexto(i);
                            final pathFoto = _getFotoPath(i);

                            final fecha = i['fecha_ingreso'] != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(i['fecha_ingreso']))
                                : 'Sin fecha';

                            return Card(
                              color: AppColors.fondo.withOpacity(0.9),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                onTap: () => _mostrarDetalles(context, i),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.tealAccent.withOpacity(0.15),
                                  backgroundImage: (pathFoto.isNotEmpty && File(pathFoto).existsSync())
                                      ? FileImage(File(pathFoto))
                                      : null,
                                  child: pathFoto.isEmpty || !File(pathFoto).existsSync()
                                      ? const Icon(Icons.devices, color: Colors.tealAccent)
                                      : null,
                                ),
                                title: Text(
                                  equipoDesc,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cliente: $clienteName',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Motivo: ${i['observaciones'] ?? 'No especificado'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fecha: $fecha',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Chip(
                                        label: Text(
                                          _textoEstado(estado),
                                          style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: _colorEstado(estado),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 28),
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

  // 🧭 Modal de detalle interno
  Future<void> _mostrarDetalles(BuildContext context, Map<String, dynamic> ingreso) async {
    final estado = _getEstado(ingreso);
    final clienteName = _getCliente(ingreso);
    final equipoDesc = _getEquipoTexto(ingreso);
    final pathFoto = _getFotoPath(ingreso);
    final accesorios = _getAccesorios(ingreso);
    final idIngreso = _getId(ingreso);

    final fecha = ingreso['fecha_ingreso'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ingreso['fecha_ingreso']))
        : 'Sin fecha';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Detalle del ingreso', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.tealAccent.withOpacity(0.15),
                backgroundImage: (pathFoto.isNotEmpty && File(pathFoto).existsSync())
                    ? FileImage(File(pathFoto))
                    : null,
                child: pathFoto.isEmpty || !File(pathFoto).existsSync()
                    ? const Icon(Icons.devices, color: Colors.tealAccent, size: 40)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                clienteName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                equipoDesc,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  _textoEstado(estado),
                  style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _colorEstado(estado),
              ),
              const Divider(color: Colors.white24, height: 24),
              _detalleCampo('Fecha de ingreso', fecha),
              _detalleCampo('Motivo del ingreso', ingreso['observaciones'] ?? 'Sin observaciones'),
              _detalleCampo('Accesorios', accesorios),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Crear diagnóstico'),
            onPressed: () async {
              Navigator.pop(context);
              // Despliega el modal pasándole el ID de ingreso verificado
              await mostrarDiagnosticoModal(context, idIngreso);
              await _cargar();
            },
          ),
        ],
      ),
    );
  }

  Widget _detalleCampo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$titulo:',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              valor,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}