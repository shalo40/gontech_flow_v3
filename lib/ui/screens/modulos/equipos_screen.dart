import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/dao/equipo_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final equipoDao = EquipoDao();
  List<Map<String, dynamic>> equipos = [];
  String filtroTexto = '';
  String filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await equipoDao.listarDetallado();
    setState(() => equipos = data);
  }

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

  String _descripcionEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente de diagnóstico';
      case 'diagnosticado':
        return 'Pendiente de aprobación de presupuesto';
      case 'en_reparacion':
        return 'En proceso de reparación';
      case 'entregado':
        return 'Equipo entregado al cliente';
      default:
        return 'Estado desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final equiposFiltrados = equipos.where((e) {
      final texto = filtroTexto.toLowerCase();
      final coincideTexto =
          e['nombre_cliente'].toString().toLowerCase().contains(texto) ||
          e['marca'].toString().toLowerCase().contains(texto) ||
          e['tipo_equipo'].toString().toLowerCase().contains(texto);
      final coincideEstado =
          filtroEstado == 'todos' ||
          (e['estado'] ?? 'pendiente') == filtroEstado;
      return coincideTexto && coincideEstado;
    }).toList();

    final agrupados = <String, List<Map<String, dynamic>>>{};
    for (final e in equiposFiltrados) {
      final fecha = (e['fecha_ingreso'] ?? 'Sin fecha').split('T').first;
      agrupados.putIfAbsent(fecha, () => []).add(e);
    }

    return LayoutPrincipal(
      titulo: 'Equipos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, tipo o marca...',
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
              onChanged: (valor) => setState(() => filtroTexto = valor),
            ),
          ),

          // 🏷️ Filtros por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chipFiltro('todos', 'Todos', Icons.list_alt),
                _chipFiltro('pendiente', 'Pendiente', Icons.hourglass_empty),
                _chipFiltro('diagnosticado', 'Diagnosticado', Icons.analytics),
                _chipFiltro('en_reparacion', 'Reparación', Icons.build),
                _chipFiltro('entregado', 'Entregado', Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 📋 Lista agrupada
          Expanded(
            child: RefreshIndicator(
              onRefresh: cargar,
              color: Colors.tealAccent,
              child: equiposFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay equipos registrados.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView(
                      children: agrupados.entries.map((grupo) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                '📅 ${grupo.key}',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...grupo.value.map((e) => _cardEquipo(context, e)),
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

  Widget _chipFiltro(String estado, String label, IconData icono) {
    final activo = filtroEstado == estado;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          color: activo ? Colors.black : Colors.white70,
          fontSize: 12,
        ),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.3),
        selected: activo,
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }

  Widget _cardEquipo(BuildContext context, Map<String, dynamic> e) {
    final estado = e['estado'] ?? 'pendiente';

    return Card(
      color: AppColors.fondo.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _mostrarDetalles(context, e),
        leading: CircleAvatar(
          backgroundColor: Colors.tealAccent.withOpacity(0.15),
          backgroundImage:
              (e['foto_path'] != null &&
                  (e['foto_path'] as String).isNotEmpty &&
                  File(e['foto_path']).existsSync())
              ? FileImage(File(e['foto_path']))
              : null,
          child: (e['foto_path'] == null || (e['foto_path'] as String).isEmpty)
              ? Icon(_iconoEstado(estado), color: Colors.tealAccent)
              : null,
        ),
        title: Text(
          '${e['tipo_equipo'] ?? 'Equipo'} ${e['marca'] ?? ''}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Cliente: ${e['nombre_cliente'] ?? 'N/D'}\n'
          'Serie: ${e['numero_serie'] ?? '-'}',
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
        trailing: Chip(
          label: Text(
            estado.toUpperCase(),
            style: const TextStyle(color: Colors.black, fontSize: 11),
          ),
          backgroundColor: _colorEstado(estado),
        ),
      ),
    );
  }

  // ===========================
  // 💬 DETALLES DEL EQUIPO
  // ===========================
  Future<void> _mostrarDetalles(
    BuildContext context,
    Map<String, dynamic> equipo,
  ) async {
    final estado = equipo['estado'] ?? 'pendiente';

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.fondo.withOpacity(0.97),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.tealAccent.withOpacity(0.15),
                    backgroundImage:
                        (equipo['foto_path'] != null &&
                            (equipo['foto_path'] as String).isNotEmpty &&
                            File(equipo['foto_path']).existsSync())
                        ? FileImage(File(equipo['foto_path']))
                        : null,
                    child:
                        (equipo['foto_path'] == null ||
                            (equipo['foto_path'] as String).isEmpty)
                        ? const Icon(
                            Icons.computer,
                            color: Colors.tealAccent,
                            size: 40,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    equipo['nombre_cliente'] ?? 'Sin cliente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${equipo['tipo_equipo']} ${equipo['marca']} - ${equipo['modelo']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(
                      estado.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _colorEstado(estado),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _descripcionEstado(estado),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // QR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data:
                          'EQUIPO-${equipo['id_equipo']}-${equipo['numero_serie'] ?? ''}',
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Código QR único del equipo',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Detalles técnicos
                  _detalleItem('ID Equipo', equipo['id_equipo'].toString()),
                  _detalleItem('Número de serie', equipo['numero_serie']),
                  _detalleItem('Tipo', equipo['tipo_equipo']),
                  _detalleItem('Marca', equipo['marca']),
                  _detalleItem('Modelo', equipo['modelo']),
                  _detalleItem('Descripción', equipo['descripcion']),
                  const SizedBox(height: 16),

                  // Botones
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _imprimirQR(
                            context,
                            equipo['id_equipo'].toString(),
                            equipo['numero_serie'] ?? '',
                            equipo['nombre_cliente'] ?? '',
                          );
                        },
                        icon: const Icon(Icons.print, color: Colors.black),
                        label: const Text('Imprimir QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/ingresos',
                            arguments: equipo['id_equipo'],
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Ver ingreso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black),
                        label: const Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detalleItem(String titulo, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // 🖨️ FUNCIÓN DE IMPRESIÓN QR
  // ===========================
  Future<void> _imprimirQR(
    BuildContext context,
    String idEquipo,
    String numeroSerie,
    String cliente,
  ) async {
    try {
      final pdf = pw.Document();

      // Logo Gontech Solutions
      final logo = await rootBundle.load('lib/ui/assets/images/logo.png');
      final logoBytes = logo.buffer.asUint8List();

      // Generar el QR
      final qrImage = await QrPainter(
        data: 'EQUIPO-$idEquipo-$numeroSerie',
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImageData(400, format: ImageByteFormat.png);

      final imageBytes = qrImage!.buffer.asUint8List();

      // Etiqueta profesional (80x50 mm)
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            80 * PdfPageFormat.mm,
            50 * PdfPageFormat.mm,
          ),
          margin: const pw.EdgeInsets.all(6),
          build: (pw.Context context) {
            return pw.Container(
              color: PdfColors.white,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Logo + Marca
                  pw.Image(pw.MemoryImage(logoBytes), height: 28),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GONTECH SOLUTIONS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.Text(
                    cliente,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),

                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),

                  // Info del equipo
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'All-in-One HP Pavilion 24',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Serie: $numeroSerie   ID: #$idEquipo',
                    style: pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 4),

                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),

                  // Código QR centrado
                  pw.SizedBox(height: 4),
                  pw.Image(pw.MemoryImage(imageBytes), width: 90, height: 90),
                  pw.SizedBox(height: 4),

                  // Footer
                  pw.Divider(color: PdfColors.grey400, thickness: 0.3),
                  pw.Text(
                    'gontechsolutions.cl',
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Guardar en Descargas
      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      final file = File('${downloadsDir.path}/Etiqueta_Equipo_$idEquipo.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ PDF guardado en Descargas: ${file.path}'),
          backgroundColor: Colors.tealAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el QR: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
