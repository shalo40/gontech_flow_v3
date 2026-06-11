import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_colors.dart';

class EquipoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> equipo;

  const EquipoDetalleScreen({super.key, required this.equipo});

  static const _colorModulo = Colors.deepPurpleAccent;

  // --- Helpers de compatibilidad API / Local ---
  String _getNombreCliente() {
    if (equipo.containsKey('nombre_cliente') && equipo['nombre_cliente'] != null) {
      return equipo['nombre_cliente'];
    }
    if (equipo.containsKey('cliente') && equipo['cliente'] != null) {
      return equipo['cliente']['nombre'] ?? 'Sin cliente';
    }
    return 'Sin cliente';
  }

  String _getIdEquipo() {
    return (equipo['id_equipo'] ?? equipo['id'] ?? '').toString();
  }
  // ---------------------------------------------

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber;
      case 'diagnosticado':
        return Colors.tealAccent;
      case 'en_reparacion':
        return Colors.blueAccent;
      case 'entregado':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado) {
      case 'diagnosticado':
        return Icons.analytics_outlined;
      case 'en_reparacion':
        return Icons.build_circle_outlined;
      case 'entregado':
        return Icons.check_circle_outline;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente de diagnostico';
      case 'diagnosticado':
        return 'Diagnosticado';
      case 'en_reparacion':
        return 'En proceso de reparacion';
      case 'entregado':
        return 'Entregado al cliente';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = equipo['estado'] ?? 'pendiente';
    final colorEst = _colorEstado(estado);
    final tieneFoto = equipo['foto_path'] != null &&
        (equipo['foto_path'] as String).isNotEmpty;
        
    final idReal = _getIdEquipo();
    final qrData = 'EQUIPO-$idReal-${equipo['numero_serie'] ?? ''}';
    final nombreCliente = _getNombreCliente();

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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _colorModulo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                          image: tieneFoto
                              ? DecorationImage(
                                  image: FileImage(
                                      File(equipo['foto_path'])),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !tieneFoto
                            ? Icon(_iconoEstado(estado),
                                color: _colorModulo, size: 36)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${equipo['tipo_equipo'] ?? 'Equipo'} ${equipo['marca'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        equipo['modelo'] ?? '',
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
          SliverToBoxAdapter(child: _buildInfoSection(nombreCliente)),
          SliverToBoxAdapter(child: _buildQRSection(context, qrData, idReal)),
          SliverToBoxAdapter(
              child: _buildActionsSection(context, qrData, idReal)),
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
                  Text(
                    'Estado actual',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
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
            _buildEstadoDots(estado),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoDots(String estadoActual) {
    final estados = ['pendiente', 'diagnosticado', 'en_reparacion', 'entregado'];
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

  Widget _buildInfoSection(String nombreCliente) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Detalles tecnicos'),
          const SizedBox(height: 10),
          _infoTile(Icons.devices, 'Tipo', equipo['tipo_equipo'] ?? '-'),
          _infoTile(Icons.business, 'Marca', equipo['marca'] ?? '-'),
          _infoTile(Icons.phone_android, 'Modelo', equipo['modelo'] ?? '-'),
          _infoTile(Icons.qr_code_2, 'N/S', equipo['numero_serie'] ?? '-'),
          _infoTile(Icons.description, 'Descripcion',
              equipo['descripcion'] ?? '-'),
          const SizedBox(height: 16),
          _seccionTitulo('Cliente'),
          const SizedBox(height: 10),
          _infoTile(Icons.person, 'Nombre', nombreCliente),
        ],
      ),
    );
  }

  Widget _buildQRSection(BuildContext context, String qrData, String idReal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _seccionTitulo('Codigo QR'),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'ID: #$idReal  |  S/N: ${equipo['numero_serie'] ?? '-'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, String qrData, String idReal) {
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
              _actionButton(
                context,
                Icons.print,
                'Imprimir QR',
                Colors.tealAccent,
                () => _imprimirQR(context, idReal, _getNombreCliente()),
              ),
              _actionButton(
                context,
                Icons.receipt_long,
                'Ver ingresos',
                Colors.orangeAccent,
                () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/ingresos',
                      arguments: int.tryParse(idReal) ?? 0);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
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
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
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

  Future<void> _imprimirQR(BuildContext context, String idReal, String nombreCliente) async {
    try {
      final pdf = pw.Document();

      final logo = await rootBundle.load('lib/ui/assets/images/logo.png');
      final logoBytes = logo.buffer.asUint8List();
      final numeroSerie = equipo['numero_serie'] ?? '';

      final qrImage = await QrPainter(
        data: 'EQUIPO-$idReal-$numeroSerie',
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImageData(400, format: ImageByteFormat.png);

      final imageBytes = qrImage!.buffer.asUint8List();
      final tituloEquipo = '${equipo['tipo_equipo'] ?? ''} ${equipo['marca'] ?? ''} ${equipo['modelo'] ?? ''}'.trim();

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            50 * PdfPageFormat.mm,
          ),
          margin: const pw.EdgeInsets.all(6),
          build: (pw.Context ctx) {
            return pw.Container(
              color: PdfColors.white,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), height: 28),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GONTECH SOLUTIONS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    nombreCliente,
                    style:
                        pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),
                  pw.SizedBox(height: 3),
                  
                  pw.Text(
                    tituloEquipo.isEmpty ? 'Equipo sin especificar' : tituloEquipo,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Serie: ${numeroSerie.isEmpty ? '-' : numeroSerie}   ID: #$idReal',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Image(pw.MemoryImage(imageBytes),
                      width: 90, height: 90),
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),
                  pw.Text(
                    'gontechsolutions.cl',
                    style:
                        pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file =
          File('${dir.path}/Etiqueta_Equipo_$idReal.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF guardado: ${file.path}'),
            backgroundColor: Colors.tealAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}