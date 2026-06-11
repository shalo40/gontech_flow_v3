import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/dao/cliente_dao.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/cliente.dart';
import '../../../core/models/equipo.dart';
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
  final _clienteDao = ClienteDao();
  final _equipoDao = EquipoDao();
  final _ingresoDao = IngresoDAO();

  Cliente? _cliente;
  List<Equipo> _equipos = [];
  List<Map<String, dynamic>> _ingresos = [];
  bool _loading = true;

  static const _colorModulo = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final cliente = await _clienteDao.obtenerPorId(widget.idCliente);
      final equipos = await _equipoDao.listarPorCliente(widget.idCliente);
      final todosIngresos = await _ingresoDao.listarIngresosDetallados();
      final ingresosCliente = todosIngresos
          .where((i) => i['nombre_cliente'] == cliente?.nombre)
          .toList();

      if (!mounted) return;
      setState(() {
        _cliente = cliente;
        _equipos = equipos;
        _ingresos = ingresosCliente;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _colorModulo),
            )
          : _cliente == null
              ? const Center(
                  child: Text('Cliente no encontrado',
                      style: TextStyle(color: Colors.white70)),
                )
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildInfoSection()),
                    SliverToBoxAdapter(child: _buildEquiposSection()),
                    SliverToBoxAdapter(child: _buildIngresosSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
      floatingActionButton: _cliente != null
          ? FloatingActionButton.extended(
              backgroundColor: _colorModulo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo ingreso'),
              onPressed: () async {
                await mostrarIngresoModal(context, widget.idCliente);
                await _cargar();
              },
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    final c = _cliente!;
    final tieneFoto = c.fotoPath?.isNotEmpty ?? false;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.fondo,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            await mostrarClienteModal(
              context,
              clienteExistente: c,
              onGuardado: _cargar,
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _colorModulo.withValues(alpha: 0.3),
                AppColors.fondo,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'cliente_${c.idCliente}',
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: _colorModulo.withValues(alpha: 0.25),
                    backgroundImage:
                        tieneFoto ? FileImage(File(c.fotoPath!)) : null,
                    child: !tieneFoto
                        ? Text(
                            c.nombre.isNotEmpty
                                ? c.nombre[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  c.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((c.rut ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'RUT: ${c.rut}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final c = _cliente!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard('Equipos', '${_equipos.length}', Icons.devices),
              const SizedBox(width: 12),
              _statCard('Ingresos', '${_ingresos.length}', Icons.receipt_long),
              const SizedBox(width: 12),
              _statCard(
                'Activos',
                '${_ingresos.where((i) => i['estado_ingreso'] != 'finalizado').length}',
                Icons.pending_actions,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _seccionTitulo('Contacto'),
          const SizedBox(height: 8),
          _infoTile(Icons.phone_outlined, 'Telefono', c.telefono),
          _infoTile(Icons.email_outlined, 'Correo', c.correo),
          _infoTile(Icons.location_on_outlined, 'Direccion', c.direccion),
          if (c.notas.isNotEmpty)
            _infoTile(Icons.notes_outlined, 'Notas', c.notas),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _colorModulo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _colorModulo.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _colorModulo, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _colorModulo.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquiposSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Equipos registrados'),
          const SizedBox(height: 8),
          if (_equipos.isEmpty)
            _emptyHint('Sin equipos asociados')
          else
            ..._equipos.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.devices,
                            color: Colors.purpleAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.marca} ${e.modelo}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${e.tipo_equipo} - S/N: ${e.numero_serie}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildIngresosSection() {
    final formato = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Historial de ingresos'),
          const SizedBox(height: 8),
          if (_ingresos.isEmpty)
            _emptyHint('Sin ingresos registrados')
          else
            ..._ingresos.map((i) {
              final estado = i['estado_ingreso'] ?? 'pendiente';
              Color colorEstado;
              switch (estado) {
                case 'finalizado':
                  colorEstado = Colors.greenAccent;
                  break;
                case 'en_reparacion':
                  colorEstado = Colors.amberAccent;
                  break;
                default:
                  colorEstado = Colors.orangeAccent;
              }

              String fechaStr = '-';
              try {
                fechaStr = formato.format(
                    DateTime.parse(i['fecha_ingreso'] ?? ''));
              } catch (_) {}

              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IngresoDetalleScreen(ingreso: i, equipo: null,),
                    ),
                  );
                  _cargar();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                    Container(
                      width: 8,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorEstado,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i['tipo_equipo'] ?? ''} ${i['marca'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fechaStr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        estado.replaceAll('_', ' '),
                        style: TextStyle(
                          color: colorEstado,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
               ),
              );
            }),
        ],
      ),
    );
  }

  Widget _seccionTitulo(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _emptyHint(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
