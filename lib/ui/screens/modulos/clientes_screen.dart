import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/dao/cliente_dao.dart';
import '../../../core/models/cliente.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'cliente_modal.dart';
import 'ingreso_modal.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final dao = ClienteDao();
  final buscadorCtrl = TextEditingController();

  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await dao.listar();
    data.sort((a, b) => a.nombre.compareTo(b.nombre));
    if (!mounted) return;
    setState(() {
      _clientes = data;
      _filtrados = data;
    });
  }

  void _filtrar(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtrados = _clientes.where((c) {
        return c.nombre.toLowerCase().contains(query) ||
            c.correo.toLowerCase().contains(query) ||
            c.telefono.toLowerCase().contains(query);
      }).toList();
    });
  }

  Map<String, List<Cliente>> _agruparPorLetra(List<Cliente> items) {
    final map = <String, List<Cliente>>{};
    for (final c in items) {
      final letra = (c.nombre.isNotEmpty ? c.nombre[0] : '#').toUpperCase();
      map.putIfAbsent(letra, () => []).add(c);
    }
    final ordenadas = Map<String, List<Cliente>>.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return ordenadas;
  }

  Future<void> _eliminarCliente(Cliente c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.9),
        title: const Text(
          'Eliminar cliente',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar a "${c.nombre}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await dao.eliminar(c.id_cliente!);
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente eliminado correctamente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorLetra(_filtrados);

    return LayoutPrincipal(
      titulo: 'Clientes',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
        backgroundColor: Colors.tealAccent,
        foregroundColor: AppColors.fondo,
        onPressed: () async {
          await mostrarClienteModal(context, onGuardado: _cargar);
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Buscador
            TextField(
              controller: buscadorCtrl,
              onChanged: _filtrar,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o teléfono...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📋 Lista agrupada
            Expanded(
              child: _filtrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay clientes registrados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView(
                      children: grupos.entries.map((entry) {
                        final letra = entry.key;
                        final items = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                              child: Text(
                                letra,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            ...items.map((c) => _tarjetaCliente(c)),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💎 Tarjeta visual de cliente con foto, nombre y opciones desplegables
  Widget _tarjetaCliente(Cliente c) {
    return Card(
      color: Colors.grey.shade900.withOpacity(0.9),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: () {
            if (c.foto_path.isNotEmpty) {
              _mostrarFotoAmpliada(c);
            }
          },
          child: Hero(
            tag: 'cliente_${c.id_cliente ?? c.nombre}',
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.tealAccent.withOpacity(0.15),
              backgroundImage: (c.foto_path.isNotEmpty)
                  ? FileImage(File(c.foto_path))
                  : null,
              child: (c.foto_path.isEmpty)
                  ? const Icon(Icons.person, color: Colors.tealAccent)
                  : null,
            ),
          ),
        ),
        iconColor: Colors.tealAccent,
        collapsedIconColor: Colors.white60,
        title: Text(
          c.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          [c.telefono, c.correo].where((s) => s.trim().isNotEmpty).join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        children: [
          _itemOpcion(
            icon: Icons.playlist_add,
            texto: 'Registrar ingreso',
            onTap: () async {
              await mostrarIngresoModal(context, c.id_cliente!);
              await _cargar();
            },
          ),
          const Divider(color: Colors.white24, height: 0),
          _itemOpcion(
            icon: Icons.edit,
            texto: 'Editar cliente',
            onTap: () async {
              await mostrarClienteModal(
                context,
                clienteExistente: c,
                onGuardado: _cargar,
              );
            },
          ),
          const Divider(color: Colors.white24, height: 0),
          _itemOpcion(
            icon: Icons.delete_forever,
            texto: 'Eliminar',
            color: Colors.redAccent,
            onTap: () => _eliminarCliente(c),
          ),
        ],
      ),
    );
  }

  /// 🔍 Visualización completa de foto
  void _mostrarFotoAmpliada(Cliente c) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: 'cliente_${c.id_cliente ?? c.nombre}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(c.foto_path), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  /// 📦 Item de menú dentro del desplegable
  Widget _itemOpcion({
    required IconData icon,
    required String texto,
    Color color = Colors.tealAccent,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(texto, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
