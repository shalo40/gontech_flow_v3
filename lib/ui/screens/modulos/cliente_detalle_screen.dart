import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/cliente.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import 'cliente_modal.dart';
import 'ingreso_modal.dart';
import 'ingreso_detalle_screen.dart';

class ClienteDetalleScreen extends StatefulWidget {
  final int idCliente;
  const ClienteDetalleScreen({super.key, required this.idCliente});

  @override
  State<ClienteDetalleScreen> createState() => _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends State<ClienteDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<HelpdeskProvider>();
    // Nos aseguramos de tener la info global fresca
    await provider.recargarClientes();
    await provider.recargarIngresos();
  }

  // Helper de filtrado local para evitar crear endpoints nuevos en el Provider
  Cliente? _obtenerCliente(HelpdeskProvider provider) {
    try {
      return provider.clientes.firstWhere((c) => c.idCliente == widget.idCliente);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _obtenerIngresosDelCliente(HelpdeskProvider provider, Cliente c) {
    return provider.ingresos.where((i) {
      final nombreCli = (i['nombre_cliente'] ?? i['equipo']?['cliente']?['nombre'] ?? '').toString().toLowerCase();
      return nombreCli == c.nombre.toLowerCase();
    }).toList();
  }

  // Extrae los equipos únicos a partir de los ingresos registrados
  List<Map<String, dynamic>> _obtenerEquiposUnicos(List<dynamic> ingresos) {
    final Map<String, Map<String, dynamic>> equipos = {};
    for (var i in ingresos) {
      final eq = i['equipo'];
      if (eq != null && eq['id'] != null) {
        equipos[eq['id'].toString()] = eq;
      }
    }
    return equipos.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final cliente = _obtenerCliente(provider);
    final isLoading = provider.loading;

    if (isLoading && cliente == null) {
      return const Scaffold(backgroundColor: AppColors.fondo, body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)));
    }

    if (cliente == null) {
      return Scaffold(
        backgroundColor: AppColors.fondo,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Cliente no encontrado en el sistema.', style: TextStyle(color: Colors.white70))),
      );
    }

    final ingresosCliente = _obtenerIngresosDelCliente(provider, cliente);
    final equiposCliente = _obtenerEquiposUnicos(ingresosCliente);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Registrar Ingreso', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await mostrarIngresoModal(context, cliente.idCliente!);
          _cargarDatos(); // Refrescar tras agregar
        },
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(cliente),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Módulo de Contacto
                  _buildContactoCard(cliente),
                  
                  const SizedBox(height: 24),
                  // Módulo de Equipos Registrados
                  const Text('Parque de Equipos', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildEquiposSection(equiposCliente),

                  const SizedBox(height: 24),
                  // Módulo de Historial de Ingresos
                  const Text('Historial de Servicios', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildIngresosSection(ingresosCliente),
                  
                  const SizedBox(height: 100), // Espacio para el FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Cliente cliente) {
    final tieneFoto = cliente.fotoPath?.isNotEmpty ?? false;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.fondo,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar Cliente',
          onPressed: () async {
            await mostrarClienteModal(context, clienteExistente: cliente, onGuardado: _cargarDatos);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.tealAccent.withOpacity(0.25), AppColors.fondo],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Hero(
                  tag: 'cliente_${cliente.idCliente}',
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.tealAccent.withOpacity(0.15),
                    backgroundImage: tieneFoto ? FileImage(File(cliente.fotoPath!)) : null,
                    child: !tieneFoto
                        ? Text(
                            cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cliente.nombre,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((cliente.rut ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('RUT: ${cliente.rut}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactoCard(Cliente cliente) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _infoRow(Icons.phone_outlined, cliente.telefono, fallback: 'Sin teléfono'),
          const Divider(color: Colors.white12, height: 20),
          _infoRow(Icons.email_outlined, cliente.correo, fallback: 'Sin correo'),
          if ((cliente.direccion ?? '').isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 20),
            _infoRow(Icons.location_on_outlined, cliente.direccion!),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String valor, {String fallback = ''}) {
    final texto = valor.trim().isEmpty ? fallback : valor;
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.tealAccent.withOpacity(0.8)),
        const SizedBox(width: 14),
        Expanded(child: Text(texto, style: TextStyle(color: valor.trim().isEmpty ? Colors.white38 : Colors.white, fontSize: 14))),
      ],
    );
  }

  Widget _buildEquiposSection(List<Map<String, dynamic>> equipos) {
    if (equipos.isEmpty) {
      return _emptyHint('No hay equipos registrados para este cliente.');
    }
    return Column(
      children: equipos.map((e) {
        return Card(
          color: Colors.black26,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.devices, color: Colors.purpleAccent, size: 20),
            ),
            title: Text('${e['marca'] ?? 'Marca'} ${e['modelo'] ?? ''}'.trim(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('S/N: ${e['numero_serie'] ?? 'Desconocido'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIngresosSection(List<dynamic> ingresos) {
    if (ingresos.isEmpty) {
      return _emptyHint('El cliente aún no tiene ingresos en el taller.');
    }
    
    // Ordenamos por fecha descendente
    ingresos.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));

    return Column(
      children: ingresos.map((i) {
        final estado = (i['estado'] ?? i['estado_ingreso'] ?? 'ingresado').toString().toLowerCase();
        final equipoStr = i['equipo'] != null 
            ? '${i['equipo']['tipo_equipo']} ${i['equipo']['marca']}' 
            : '${i['tipo_equipo']} ${i['marca']}';
        
        final fechaRaw = i['created_at'] ?? i['fecha_ingreso'];
        final fechaStr = fechaRaw != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(fechaRaw.toString())) : 'Reciente';

        Color colorEstado = Colors.amberAccent;
        if (estado == 'finalizado') colorEstado = Colors.greenAccent;
        else if (estado.contains('reparacion')) colorEstado = Colors.blueAccent;

        return Card(
          color: Colors.black26,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => IngresoDetalleScreen(ingreso: i, equipo: i['equipo'])));
            },
            title: Text(equipoStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(fechaStr, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colorEstado.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(estado.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyHint(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
      ),
      child: Text(mensaje, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
    );
  }
}