import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/cliente.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'cliente_modal.dart';
import 'ingreso_modal.dart';
import 'cliente_detalle_screen.dart'; // <-- Preparado para tu pantalla de detalle

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final buscadorCtrl = TextEditingController();
  List<Cliente> _filtrados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    final provider = context.read<HelpdeskProvider>();
    await provider.recargarClientes();
    // También recargamos ingresos para saber si tienen equipos en el taller
    await provider.recargarIngresos(); 
    _filtrar(buscadorCtrl.text);
  }

  void _filtrar(String q) {
    final query = q.trim().toLowerCase();
    final provider = context.read<HelpdeskProvider>();
    
    setState(() {
      _filtrados = provider.clientes.where((c) {
        return c.nombre.toLowerCase().contains(query) ||
            c.correo.toLowerCase().contains(query) ||
            c.telefono.toLowerCase().contains(query);
      }).toList();
      
      _filtrados.sort((a, b) => a.nombre.compareTo(b.nombre));
    });
  }

  Map<String, List<Cliente>> _agruparPorLetra(List<Cliente> items) {
    final map = <String, List<Cliente>>{};
    for (final c in items) {
      final letra = (c.nombre.isNotEmpty ? c.nombre[0] : '#').toUpperCase();
      map.putIfAbsent(letra, () => []).add(c);
    }
    return Map<String, List<Cliente>>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  // --- Detector Inteligente de Trabajos Activos ---
  int _contarIngresosActivos(Cliente c, List<dynamic> ingresosGlobales) {
    return ingresosGlobales.where((i) {
      final estado = (i['estado'] ?? i['estado_ingreso'] ?? '').toString().toLowerCase();
      if (estado == 'finalizado' || estado == 'archivado') return false;
      
      final nombreCli = (i['nombre_cliente'] ?? i['equipo']?['cliente']?['nombre'] ?? '').toString().toLowerCase();
      return nombreCli == c.nombre.toLowerCase();
    }).length;
  }

  Future<void> _eliminarCliente(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Eliminar cliente', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text('¿Estás seguro de eliminar a "${c.nombre}"? Se perderá su registro en la agenda.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true && c.idCliente != null) {
      try {
        final provider = context.read<HelpdeskProvider>();
        await provider.eliminarCliente(c.idCliente!);
        _filtrar(buscadorCtrl.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cliente eliminado del sistema.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorLetra(_filtrados);
    final provider = context.watch<HelpdeskProvider>();
    final isLoading = provider.loading;
    final ingresosGlobales = provider.ingresos;

    return LayoutPrincipal(
      titulo: 'Directorio de Clientes',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        elevation: 4,
        onPressed: () async => await mostrarClienteModal(context, onGuardado: _cargar),
      ),
      child: Column(
        children: [
          // 🔍 Buscador Inteligente
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: buscadorCtrl,
              onChanged: _filtrar,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o teléfono...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                suffixIcon: buscadorCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          buscadorCtrl.clear();
                          _filtrar('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 📋 Lista CRM
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: isLoading && _filtrados.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : _filtrados.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 80), // <-- SOLUCIÓN AL OVERLAP DEL BOTÓN FLOTANTE
                          children: grupos.entries.map((entry) {
                            final letra = entry.key;
                            final items = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Separador Alfabético Moderno
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                  child: Row(
                                    children: [
                                      Text(letra, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                                    ],
                                  ),
                                ),
                                ...items.map((c) => _tarjetaCliente(c, ingresosGlobales)),
                              ],
                            );
                          }).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            buscadorCtrl.text.isNotEmpty ? 'No encontramos a "${buscadorCtrl.text}"' : 'Tu directorio está vacío',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (buscadorCtrl.text.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => mostrarClienteModal(context, onGuardado: _cargar),
              icon: const Icon(Icons.add),
              label: const Text('Registrar nuevo cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.withOpacity(0.15),
                foregroundColor: Colors.tealAccent,
                elevation: 0,
              ),
            )
        ],
      ),
    );
  }

  Widget _tarjetaCliente(Cliente c, List<dynamic> ingresosGlobales) {
    final activos = _contarIngresosActivos(c, ingresosGlobales);

    return Card(
      color: AppColors.fondo.withOpacity(0.8),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: activos > 0 ? Colors.tealAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (c.idCliente != null) {
            // NAVEGACIÓN AL DETALLE DEL CLIENTE
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClienteDetalleScreen(idCliente: c.idCliente!)),
            ).then((_) => _cargar()); // Recargar al volver por si se editaron cosas
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Avatar e Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (c.fotoPath?.isNotEmpty ?? false) _mostrarFotoAmpliada(c);
                    },
                    child: Hero(
                      tag: 'cliente_${c.idCliente ?? c.nombre}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.tealAccent.withOpacity(0.15),
                        backgroundImage: (c.fotoPath?.isNotEmpty ?? false) ? FileImage(File(c.fotoPath!)) : null,
                        child: (c.fotoPath?.isEmpty ?? true)
                            ? Text(c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 18))
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.nombre,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 🔥 HIGHLIGHT DE NEGOCIO ACTIVO
                            if (activos > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.build_circle, color: Colors.orangeAccent, size: 12),
                                    const SizedBox(width: 4),
                                    Text('$activos en taller', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if ((c.telefono).trim().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(c.telefono, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        const SizedBox(height: 2),
                        if ((c.correo).trim().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.email, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Expanded(child: Text(c.correo, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              
              // Fila Inferior: Botonera CRM Rápida
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      if (c.idCliente != null) {
                        await mostrarIngresoModal(context, c.idCliente!);
                        _cargar();
                      }
                    },
                    icon: const Icon(Icons.add_to_queue, size: 16, color: Colors.tealAccent),
                    label: const Text('Ingresar Equipo', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 36),
                      backgroundColor: Colors.tealAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 20),
                        tooltip: 'Editar cliente',
                        onPressed: () async => await mostrarClienteModal(context, clienteExistente: c, onGuardado: _cargar),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Eliminar',
                        onPressed: () => _eliminarCliente(c),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFotoAmpliada(Cliente c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: 'cliente_${c.idCliente ?? c.nombre}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(c.fotoPath!), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}