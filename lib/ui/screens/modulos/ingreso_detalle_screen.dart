import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../theme/app_colors.dart';
import 'diagnostico_modal.dart';

class IngresoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> ingreso;

  const IngresoDetalleScreen({super.key, required this.ingreso, Object? equipo});

  @override
  State<IngresoDetalleScreen> createState() => _IngresoDetalleScreenState();
}

class _IngresoDetalleScreenState extends State<IngresoDetalleScreen> {
  final _dao = IngresoDAO();
  late Map<String, dynamic> _ingreso;

  static const _colorModulo = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _ingreso = widget.ingreso;
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente_diagnostico':
        return Colors.orangeAccent;
      case 'pendiente_aprobacion':
        return Colors.amber;
      case 'en_reparacion':
        return Colors.blueAccent;
      case 'finalizado':
        return Colors.greenAccent;
      case 'archivado':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente_diagnostico':
        return 'Pendiente de diagnostico';
      case 'pendiente_aprobacion':
        return 'Pendiente de aprobacion';
      case 'en_reparacion':
        return 'En reparacion';
      case 'finalizado':
        return 'Finalizado';
      case 'archivado':
        return 'Archivado';
      default:
        return 'Pendiente';
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'pendiente_diagnostico':
        return Icons.hourglass_top;
      case 'pendiente_aprobacion':
        return Icons.approval;
      case 'en_reparacion':
        return Icons.build;
      case 'finalizado':
        return Icons.check_circle;
      case 'archivado':
        return Icons.archive;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _ingreso['estado_ingreso'] ?? 'pendiente_diagnostico';
    final colorEst = _colorEstado(estado);
    final tieneFoto =
        _ingreso['foto_path'] != null &&
        (_ingreso['foto_path'] as String).isNotEmpty;

    String fechaStr = '';
    try {
      fechaStr = DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(_ingreso['fecha_ingreso'] ?? ''));
    } catch (_) {
      fechaStr = 'Sin fecha';
    }

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.fondo,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorEst.withValues(alpha: 0.3), AppColors.fondo],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: colorEst.withValues(alpha: 0.2),
                        backgroundImage: tieneFoto
                            ? FileImage(File(_ingreso['foto_path']))
                            : null,
                        child: !tieneFoto
                            ? Icon(
                                _iconoEstado(estado),
                                color: colorEst,
                                size: 36,
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_ingreso['tipo_equipo'] ?? 'Equipo'} ${_ingreso['marca'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _ingreso['nombre_cliente'] ?? 'Sin cliente',
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
          ),
          SliverToBoxAdapter(child: _buildStatusSection(estado, colorEst)),
          SliverToBoxAdapter(child: _buildInfoSection(fechaStr)),
          SliverToBoxAdapter(child: _buildActionsSection(estado)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String estado, Color colorEst) {
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
                  const Text(
                    'Estado actual',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _textoEstado(estado),
                    style: TextStyle(
                      color: colorEst,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildEstadoTimeline(estado),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoTimeline(String estadoActual) {
    final estados = [
      'pendiente_diagnostico',
      'pendiente_aprobacion',
      'en_reparacion',
      'finalizado',
    ];
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

  Widget _buildInfoSection(String fecha) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Informacion del ingreso'),
          const SizedBox(height: 10),
          _infoTile(Icons.calendar_today, 'Fecha de ingreso', fecha),
          _infoTile(
            Icons.computer,
            'Equipo',
            '${_ingreso['tipo_equipo'] ?? ''} ${_ingreso['marca'] ?? ''} ${_ingreso['modelo'] ?? ''}',
          ),
          _infoTile(
            Icons.person_outline,
            'Cliente',
            _ingreso['nombre_cliente'] ?? 'Sin cliente',
          ),
          _infoTile(
            Icons.cable,
            'Accesorios',
            _ingreso['accesorios'] ?? 'Sin accesorios',
          ),
          const SizedBox(height: 16),
          // Cuadro de Resumen/Observaciones
          if ((_ingreso['observaciones'] ?? '').toString().trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.speaker_notes,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OBSERVACIONES DEL INGRESO',
                        style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ingreso['observaciones'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(String estado) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Acciones'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (estado != 'finalizado' && estado != 'archivado')
                _actionButton(
                  Icons.biotech,
                  'Crear diagnostico',
                  Colors.tealAccent,
                  () async {
                    await mostrarDiagnosticoModal(
                      context,
                      _ingreso['id_ingreso'],
                    );
                    if (mounted) Navigator.pop(context);
                  },
                ),
              if (estado != 'finalizado' && estado != 'archivado')
                _actionButton(
                  Icons.check_circle,
                  'Finalizar',
                  Colors.greenAccent,
                  () async {
                    await _dao.actualizarEstado(
                      _ingreso['id_ingreso'],
                      'finalizado',
                    );
                    if (mounted) Navigator.pop(context);
                  },
                ),
              if (estado == 'finalizado')
                _actionButton(Icons.archive, 'Archivar', Colors.grey, () async {
                  await _dao.actualizarEstado(
                    _ingreso['id_ingreso'],
                    'archivado',
                  );
                  if (mounted) Navigator.pop(context);
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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

  Widget _infoTile(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _colorModulo.withValues(alpha: 0.6), size: 20),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
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
