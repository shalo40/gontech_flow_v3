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
    switch (estado?.toLowerCase()) {
      case 'pendiente': return Colors.orangeAccent;
      case 'diagnosticado': return Colors.tealAccent;
      case 'en_reparacion': return Colors.blueAccent;
      case 'entregado': return Colors.greenAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'diagnosticado': return Icons.analytics_outlined;
      case 'en_reparacion': return Icons.build_circle_outlined;
      case 'entregado': return Icons.check_circle_outline;
      default: return Icons.hourglass_empty;
    }
  }

  String _textoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return 'Pendiente de diagnóstico';
      case 'diagnosticado': return 'Diagnosticado / Pto. Enviado';
      case 'en_reparacion': return 'En mesa de trabajo';
      case 'entregado': return 'Entregado al cliente';
      default: return 'Estado Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = (equipo['estado'] ?? 'pendiente').toString().toLowerCase();
    final colorEst = _colorEstado(estado);
    final tieneFoto = equipo['foto_path'] != null && (equipo['foto_path'] as String).isNotEmpty;
        
    final idReal = _getIdEquipo();
    final qrData = 'EQUIPO-$idReal-${equipo['numero_serie'] ?? ''}';
    final nombreCliente = _getNombreCliente();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          // 🖼️ HEADER DINÁMICO
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.fondo,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorEst.withOpacity(0.25), AppColors.fondo],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorEst.withOpacity(0.5), width: 2),
                          boxShadow: [BoxShadow(color: colorEst.withOpacity(0.2), blurRadius: 12, spreadRadius: 2)],
                          image: tieneFoto && File(equipo['foto_path']).existsSync()
                              ? DecorationImage(image: FileImage(File(equipo['foto_path'])), fit: BoxFit.cover)
                              : null,
                        ),
                        child: !tieneFoto || !File(equipo['foto_path']).existsSync()
                            ? Icon(_iconoEstado(estado), color: colorEst, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${equipo['tipo_equipo'] ?? 'Equipo'} ${equipo['marca'] ?? ''}'.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipo['modelo'] ?? 'Modelo no especificado',
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 📋 CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildStatusSection(estado, colorEst),
                  const SizedBox(height: 16),
                  _buildInfoSection(nombreCliente),
                  const SizedBox(height: 16),
                  _buildQRSection(context, qrData, idReal),
                  const SizedBox(height: 16),
                  _buildActionsSection(context, qrData, idReal, nombreCliente),
                  const SizedBox(height: 60), // Espacio final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🟢 SECCIÓN DE ESTADO (Progress Bar)
  // ==========================================
  Widget _buildStatusSection(String estado, Color colorEst) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorEst.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorEst.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconoEstado(estado), color: colorEst, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTADO ACTUAL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(_textoEstado(estado), style: TextStyle(color: colorEst, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEstadoDots(estado, colorEst),
        ],
      ),
    );
  }

  Widget _buildEstadoDots(String estadoActual, Color colorEst) {
    final estados = ['pendiente', 'diagnosticado', 'en_reparacion', 'entregado'];
    final idx = estados.indexOf(estadoActual).clamp(0, estados.length - 1);

    return Row(
      children: List.generate(estados.length, (i) {
        final completado = i <= idx;
        final ultimo = i == estados.length - 1;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completado ? colorEst : Colors.white10,
                  border: completado ? null : Border.all(color: Colors.white24),
                  boxShadow: completado ? [BoxShadow(color: colorEst.withOpacity(0.5), blurRadius: 6)] : null,
                ),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(
                    height: 2,
                    color: completado ? colorEst.withOpacity(0.5) : Colors.white10,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ==========================================
  // 📋 SECCIÓN DE FICHA TÉCNICA Y CLIENTE
  // ==========================================
  Widget _buildInfoSection(String nombreCliente) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SeccionTitulo(titulo: 'Datos del Propietario', icono: Icons.person_outline),
          const SizedBox(height: 16),
          _infoTile(Icons.badge_outlined, 'Nombre / Razón Social', nombreCliente),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white12, height: 1),
          ),

          const _SeccionTitulo(titulo: 'Especificaciones Técnicas', icono: Icons.memory),
          const SizedBox(height: 16),
          _infoTile(Icons.devices_other, 'Tipo de Equipo', equipo['tipo_equipo'] ?? '-'),
          _infoTile(Icons.branding_watermark_outlined, 'Marca de Fabricante', equipo['marca'] ?? '-'),
          _infoTile(Icons.label_outline, 'Modelo', equipo['modelo'] ?? '-'),
          _infoTile(Icons.qr_code, 'Número de Serie', equipo['numero_serie'] ?? '-'),
          if ((equipo['descripcion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoTile(Icons.notes, 'Notas de Ingreso', equipo['descripcion'] ?? '-'),
          ]
        ],
      ),
    );
  }

  // ==========================================
  // 📱 SECCIÓN DE CÓDIGO QR
  // ==========================================
  Widget _buildQRSection(BuildContext context, String qrData, String idReal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const _SeccionTitulo(titulo: 'Trazabilidad', icono: Icons.qr_code_scanner),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: qrData,
              size: 160,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text('ID Interno: #$idReal', style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text('S/N: ${equipo['numero_serie'] ?? '-'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // 🚀 SECCIÓN DE ACCIONES RÁPIDAS
  // ==========================================
  Widget _buildActionsSection(BuildContext context, String qrData, String idReal, String nombreCliente) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _imprimirQR(context, idReal, nombreCliente),
            icon: const Icon(Icons.print, color: Colors.black),
            label: const Text('Imprimir QR', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ingresos', arguments: int.tryParse(idReal) ?? 0);
            },
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text('Ver Ingreso', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // --- Widgets Auxiliares ---
  Widget _infoTile(IconData icon, String label, String value) {
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🖨️ LÓGICA DE IMPRESIÓN PDF (Sin cambios)
  // ===========================
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
          pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 50 * PdfPageFormat.mm),
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
                  pw.Text('GONTECH SOLUTIONS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(nombreCliente, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    tituloEquipo.isEmpty ? 'Equipo sin especificar' : tituloEquipo,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text('Serie: ${numeroSerie.isEmpty ? '-' : numeroSerie}  ID: #$idReal', style: pw.TextStyle(fontSize: 7.5)),
                  pw.SizedBox(height: 4),
                  pw.Image(pw.MemoryImage(imageBytes), width: 90, height: 90),
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),
                  pw.Text('gontechsolutions.cl', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            );
          },
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File('${dir.path}/Etiqueta_Equipo_$idReal.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF guardado: ${file.path}'),
            backgroundColor: Colors.tealAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }
}

// Auxiliar para Títulos
class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Text(titulo.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}