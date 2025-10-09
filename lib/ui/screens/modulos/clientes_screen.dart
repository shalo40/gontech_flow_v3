import 'package:flutter/material.dart';
import 'package:gontech_flow_v2/ui/screens/modulos/ingreso_modal.dart';
import '../../../core/dao/cliente_dao.dart';
import '../../../core/models/cliente.dart';
import '../../../core/database/database_helper.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClienteDao _dao = ClienteDao();
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  final TextEditingController _busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // 🧠 Cargar clientes
  Future<void> _cargarClientes() async {
    final data = await _dao.listar();
    setState(() {
      _clientes = data;
      _clientesFiltrados = data;
    });
  }

  // 🔍 Filtro
  void _filtrar() {
    final q = _busquedaCtrl.text.toLowerCase();
    setState(() {
      _clientesFiltrados = _clientes
          .where(
            (c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.correo.toLowerCase().contains(q) ||
                c.telefono.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  // 🧱 Modal agregar / editar cliente
  Future<void> _mostrarModalCliente({Cliente? cliente}) async {
    final nombre = TextEditingController(text: cliente?.nombre ?? '');
    final telefono = TextEditingController(text: cliente?.telefono ?? '');
    final correo = TextEditingController(text: cliente?.correo ?? '');
    final direccion = TextEditingController(text: cliente?.direccion ?? '');
    final notas = TextEditingController(text: cliente?.notas ?? '');

    final esNuevo = cliente == null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(esNuevo ? 'Nuevo cliente' : 'Editar cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombre, 'Nombre *'),
              _campo(telefono, 'Teléfono'),
              _campo(correo, 'Correo'),
              _campo(direccion, 'Dirección'),
              _campo(notas, 'Notas'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombre.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debe ingresar un nombre')),
                );
                return;
              }

              // Evitar duplicados por correo o nombre
              final duplicado = _clientes.any(
                (c) =>
                    c.nombre.toLowerCase() == nombre.text.toLowerCase() &&
                    c.id_cliente != cliente?.id_cliente,
              );
              if (duplicado) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ya existe un cliente con ese nombre.'),
                  ),
                );
                return;
              }

              final nuevo = Cliente(
                id_cliente: cliente?.id_cliente,
                nombre: nombre.text,
                telefono: telefono.text,
                correo: correo.text,
                direccion: direccion.text,
                notas: notas.text,
              );

              if (esNuevo) {
                await _dao.insertar(nuevo);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente agregado correctamente'),
                  ),
                );
              } else {
                await _dao.actualizar(nuevo);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente actualizado')),
                );
              }

              if (context.mounted) Navigator.pop(context);
              _cargarClientes();
            },
            child: Text(esNuevo ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // 🗑 Validar si cliente tiene ingresos antes de eliminar
  Future<bool> _puedeEliminar(int idCliente) async {
    final db = await DatabaseHelper().db;
    final ingresos = await db.query(
      'ingresos',
      where:
          'id_equipo IN (SELECT id_equipo FROM equipos WHERE id_cliente = ?)',
      whereArgs: [idCliente],
      limit: 1,
    );
    return ingresos.isEmpty;
  }

  Future<void> _eliminarCliente(Cliente c) async {
    final permitido = await _puedeEliminar(c.id_cliente!);
    if (!permitido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar el cliente: tiene ingresos asociados.',
          ),
        ),
      );
      return;
    }

    await _dao.eliminar(c.id_cliente!);
    _cargarClientes();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cliente eliminado.')));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Clientes',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar cliente...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  heroTag: 'add_cliente',
                  backgroundColor: AppColors.primario,
                  onPressed: () => _mostrarModalCliente(),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Lista de clientes
            Expanded(
              child: _clientesFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay clientes registrados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _clientesFiltrados.length,
                      itemBuilder: (context, i) {
                        final c = _clientesFiltrados[i];
                        return Card(
                          color: AppColors.fondo.withOpacity(0.85),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              c.nombre,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              c.correo.isNotEmpty
                                  ? c.correo
                                  : c.telefono.isNotEmpty
                                  ? c.telefono
                                  : 'Sin contacto',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Crear ingreso',
                                  icon: const Icon(
                                    Icons.add_box_outlined,
                                    color: Colors.tealAccent,
                                  ),
                                  onPressed: () {
                                    mostrarIngresoModal(context, c.id_cliente!);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Editar cliente',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.amberAccent,
                                  ),
                                  onPressed: () =>
                                      _mostrarModalCliente(cliente: c),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar cliente',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _eliminarCliente(c),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
