import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // <-- Inyección del Provider
import '../../../core/dao/diagnostico_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/repuesto_dao.dart';
import '../../../core/models/repuesto.dart';
import '../../../core/providers/helpdesk_provider.dart'; // <-- El cerebro
import '../../theme/app_colors.dart';
import 'presupuesto_modal.dart';

class DiagnosticoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> diagnostico;

  const DiagnosticoDetalleScreen({super.key, required this.diagnostico});

  @override
  State<DiagnosticoDetalleScreen> createState() =>
      _DiagnosticoDetalleScreenState();
}

class _DiagnosticoDetalleScreenState extends State<DiagnosticoDetalleScreen> {
  final _dao = DiagnosticoDao();
  final _ingresoDao = IngresoDAO();
  final _repuestoDao = RepuestoDao(); // Mantenemos el DAO de repuestos hasta migrar ese módulo

  late Map<String, dynamic> _d;
  List<Repuesto> _repuestos = [];
  bool _loadingRepuestos = true;

  static const _colorModulo = Colors.tealAccent;

  @override
  void initState() {
    super.initState();
    _d = widget.diagnostico;
    _cargarRepuestos();
  }

  // --- Buscador inteligente para API (Anidado) o Local (Plano) ---
  String _getNested(String localKey, List<String> apiPath, [String fallback = '']) {
    if (_d.containsKey(localKey) && _d[localKey] != null) {
      return _d[localKey].toString();
    }
    dynamic current = _d;
    for (final key in apiPath) {
      if (current == null || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString().isNotEmpty ? current.toString() : fallback;
  }

  int _getId() {
    return int.tryParse((_d['id_diagnostico'] ?? _d['id'] ?? '0').toString()) ?? 0;
  }
  // ---------------------------------------------------------------

  Future<void> _cargarRepuestos() async {
    setState(() => _loadingRepuestos = true);
    try {
      final idDiag = _getId();
      final data = await _repuestoDao.listarPorDiagnostico(idDiag);
      if (!mounted) return;
      setState(() {
        _repuestos = data.map((m) => Repuesto.fromMap(m)).toList();
        _loadingRepuestos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRepuestos = false);
    }
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amberAccent;
      case 'diagnosticado':
        return _colorModulo;
      case 'en_revision':
        return Colors.blueAccent;
      case 'finalizado':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.pending_actions;
      case 'diagnosticado':
        return Icons.biotech;
      case 'en_revision':
        return Icons.search;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'diagnosticado':
        return 'Diagnosticado';
      case 'en_revision':
        return 'En revision';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _d['estado'] ?? 'pendiente';
    final colorEst = _colorEstado(estado);

    String fechaStr = '';
    try {
      final rawFecha = _d['creado_en'] ?? _d['created_at'] ?? '';
      fechaStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(rawFecha));
    } catch (_) {
      fechaStr = 'Sin fecha';
    }

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(estado, colorEst),
          SliverToBoxAdapter(child: _buildStatusSection(estado, colorEst, fechaStr)),
          SliverToBoxAdapter(child: _buildEquipoSection()),
          SliverToBoxAdapter(child: _buildFallaSection()),
          SliverToBoxAdapter(child: _buildPruebasSection()),
          SliverToBoxAdapter(child: _buildConclusionesSection()),
          SliverToBoxAdapter(child: _buildRepuestosSection()),
          SliverToBoxAdapter(child: _buildActionsSection(estado)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(String estado, Color colorEst) {
    final idDiag = _getId();
    final tipo = _getNested('tipo_equipo', ['ingreso', 'equipo', 'tipo_equipo']);
    final marca = _getNested('marca', ['ingreso', 'equipo', 'marca']);

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.fondo,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorEst.withValues(alpha: 0.25),
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorEst.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.biotech, color: colorEst, size: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  'Diagnostico #$idDiag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$tipo $marca',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // STATUS
  // ──────────────────────────────────────────
  Widget _buildStatusSection(String estado, Color colorEst, String fechaStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorEst.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorEst.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(_iconoEstado(estado), color: colorEst, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _textoEstado(estado),
                    style: TextStyle(
                      color: colorEst,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Creado: $fechaStr',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _buildProgressDots(estado),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(String estadoActual) {
    final estados = ['pendiente', 'diagnosticado', 'en_revision', 'finalizado'];
    final idx = estados.indexOf(estadoActual).clamp(0, estados.length - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(estados.length, (i) {
        final completado = i <= idx;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completado
                ? _colorEstado(estados[i])
                : Colors.white.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }

  // ──────────────────────────────────────────
  // EQUIPO / CLIENTE
  // ──────────────────────────────────────────
  Widget _buildEquipoSection() {
    final tipo = _getNested('tipo_equipo', ['ingreso', 'equipo', 'tipo_equipo']);
    final marca = _getNested('marca', ['ingreso', 'equipo', 'marca']);
    final modelo = _getNested('modelo', ['ingreso', 'equipo', 'modelo']);
    final ns = _getNested('numero_serie', ['ingreso', 'equipo', 'numero_serie']);
    final cliente = _getNested('nombre_cliente', ['ingreso', 'equipo', 'cliente', 'nombre'], 'Sin cliente');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Equipo y cliente'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _infoRow(Icons.devices, 'Equipo', '$tipo $marca $modelo'),
                if (ns.isNotEmpty)
                  _infoRow(Icons.qr_code_2, 'N/S', ns),
                _infoRow(Icons.person_outline, 'Cliente', cliente),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // FALLA
  // ──────────────────────────────────────────
  Widget _buildFallaSection() {
    final falla = _d['descripcion_falla'] ?? 'Sin descripcion';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Descripcion de la falla'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    falla,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // PRUEBAS REALIZADAS (CHECKLIST VISUAL)
  // ──────────────────────────────────────────
  Widget _buildPruebasSection() {
    final pruebas = (_d['pruebas_realizadas'] ?? '').toString();
    final lista =
        pruebas.isNotEmpty ? pruebas.split(', ') : <String>[];

    if (lista.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _seccionTitulo('Pruebas realizadas')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _colorModulo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lista.length} prueba${lista.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: _colorModulo,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lista.map((prueba) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _colorModulo.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _colorModulo.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _colorModulo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.check,
                            color: _colorModulo, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prueba.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // CONCLUSIONES
  // ──────────────────────────────────────────
  Widget _buildConclusionesSection() {
    final conclusiones = _d['conclusiones'] ?? '';
    if (conclusiones.toString().trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Conclusiones'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.blueAccent.withValues(alpha: 0.7),
                    size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    conclusiones,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // REPUESTOS
  // ──────────────────────────────────────────
  Widget _buildRepuestosSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _seccionTitulo('Repuestos sugeridos')),
              if (_repuestos.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_repuestos.length}',
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingRepuestos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                    CircularProgressIndicator(color: _colorModulo, strokeWidth: 2),
              ),
            )
          else if (_repuestos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'Sin repuestos asociados a este diagnostico',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
            )
          else
            ..._repuestos.map((r) => Container(
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
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color:
                              Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.memory,
                            color: Colors.purpleAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.nombre ?? 'Sin nombre',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cantidad: ${r.cantidad} | ${r.estado}',
                              style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.costoUnitario != null && r.costoUnitario! > 0)
                        Text(
                          '\$${r.costoUnitario!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _colorModulo,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // ACCIONES
  // ──────────────────────────────────────────
  Widget _buildActionsSection(String estado) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Acciones'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (estado != 'finalizado')
                _actionButton(
                  Icons.attach_money,
                  'Crear presupuesto',
                  Colors.greenAccent,
                  () async {
                    await mostrarPresupuestoModal(
                      context,
                      _getId(),
                    );
                    if (mounted) Navigator.pop(context);
                  },
                ),
              if (estado != 'finalizado')
                _actionButton(
                  Icons.check_circle,
                  'Finalizar',
                  _colorModulo,
                  () async {
                    await _dao.actualizarEstado(_getId(), 'finalizado');
                    if (mounted) {
                      // Recargamos el Provider globalmente
                      await context.read<HelpdeskProvider>().recargarDiagnosticos();
                      Navigator.pop(context);
                    }
                  },
                ),
              _actionButton(
                Icons.delete_forever,
                'Eliminar',
                Colors.redAccent,
                () async {
                  await _dao.eliminar(_getId());
                  if (mounted) {
                    // Recargamos el Provider globalmente
                    await context.read<HelpdeskProvider>().recargarDiagnosticos();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  // ──────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              color: _colorModulo.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
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
}