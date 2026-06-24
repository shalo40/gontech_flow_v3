import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

/// Genera el PDF de Comprobante de Entrega con:
/// - Cadena anidada: entrega → reparacion → diagnostico → ingreso → equipo → cliente
/// - Datos del equipo: tipo, marca, modelo, número de serie
/// - Receptor: nombre + RUT
/// - Fecha y hora de entrega
/// - Imagen de firma incrustada en el documento
/// - Declaración legal de conformidad
class PdfEntrega {
  static Future<File> generar(Map<String, dynamic> entrega) async {
    final doc = pw.Document();

    // ── Extraer cadena de datos anidada ──────────────────────────
    final reparacion  = entrega['reparacion']  as Map<String, dynamic>? ?? {};
    final diagnostico = reparacion['diagnostico'] as Map<String, dynamic>? ?? {};
    final ingreso     = diagnostico['ingreso']    as Map<String, dynamic>? ?? {};
    final equipo      = ingreso['equipo']         as Map<String, dynamic>? ?? {};
    final cliente     = equipo['cliente']         as Map<String, dynamic>? ?? {};

    // Datos del equipo
    final tipoEquipo  = _str(equipo['tipo_equipo'])  ?? '-';
    final marca       = _str(equipo['marca'])        ?? '-';
    final modelo      = _str(equipo['modelo'])       ?? '-';
    final serie       = _str(equipo['numero_serie']) ?? '-';

    // Datos del cliente
    final nombreCliente = _str(cliente['nombre'])
        ?? _str(entrega['nombre_receptor'])
        ?? '-';
    final rutCliente    = _str(cliente['rut']) ?? '-';

    // Datos del receptor (quien retira — puede ser diferente al titular)
    final nombreReceptor = _str(entrega['nombre_receptor']) ?? nombreCliente;
    final rutReceptor    = _str(entrega['rut_receptor'])    ?? rutCliente;

    // Descripción del trabajo
    final descReparacion = _str(reparacion['descripcion'])
        ?? _str(entrega['descripcion_reparacion'])
        ?? _str(diagnostico['descripcion'])
        ?? '-';
    final observaciones  = _str(entrega['observaciones']) ?? '';

    // Fechas
    final fechaRaw   = _str(entrega['fecha_entrega'])
        ?? _str(entrega['updated_at'])
        ?? _str(entrega['created_at'])
        ?? '';
    final fechaEntrega = _fmtFechaHora(fechaRaw);

    // Estado
    final estado = _str(entrega['estado']) ?? 'entregado';

    // Folio
    final idEnt  = entrega['id_entrega']?.toString() ?? '0';
    final folio  = 'ENT-${idEnt.padLeft(4, '0')}';
    final qrData = 'gontech://entregas/$idEnt';

    // Firma digital
    pw.Widget firmaWidget() {
      final path = _str(entrega['firma_path']) ?? '';
      if (path.isEmpty) {
        return pw.Container(
          height: 70,
          width: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfTema.colorBorde),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text('Sin firma registrada', style: PdfTema.small()),
        );
      }
      final file = File(path);
      if (!file.existsSync()) {
        return pw.Container(
          height: 70,
          width: 220,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfTema.colorBorde)),
          alignment: pw.Alignment.center,
          child: pw.Text('Archivo de firma no encontrado', style: PdfTema.small()),
        );
      }
      final bytes = file.readAsBytesSync();
      return pw.Container(
        height: 80,
        width: 220,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Center(
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      );
    }

    doc.addPage(
      PdfBase.buildA4(
        titulo:    'Comprobante de Entrega',
        subtitulo: 'Servicio Técnico – Gontech Flow',
        folio:     folio,
        qrData:    qrData,
        content: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. Tarjeta de datos principales
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfTema.colorAcento,
                border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('EQUIPO ENTREGADO', style: PdfTema.etiqueta()),
                        pw.Text('$tipoEquipo $marca'.trim(), style: PdfTema.h3()),
                        pw.SizedBox(height: 2),
                        pw.Text('Modelo: $modelo', style: PdfTema.small()),
                        pw.Text('N/S: $serie',    style: PdfTema.small()),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECEPTOR', style: PdfTema.etiqueta()),
                        pw.Text(nombreReceptor, style: PdfTema.h3()),
                        pw.SizedBox(height: 2),
                        pw.Text('RUT: $rutReceptor', style: PdfTema.small()),
                        pw.SizedBox(height: 8),
                        pw.Text('FECHA DE ENTREGA', style: PdfTema.etiqueta()),
                        pw.Text(fechaEntrega, style: PdfTema.body()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // 2. Detalle de reparación
            _seccion('Detalle de Reparación Realizada', [
              _campo('Trabajo efectuado', descReparacion),
              if (observaciones.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _campo('Observaciones', observaciones),
              ],
              pw.SizedBox(height: 4),
              _campo('Estado', estado.toUpperCase()),
            ]),

            pw.SizedBox(height: 14),

            // 3. Declaración legal + firma
            _seccion('Conformidad de Recepción', [
              pw.Text(
                'El receptor declara haber recibido el equipo descrito en el presente comprobante '
                'en condiciones satisfactorias y a conformidad con el servicio técnico prestado. '
                'Con la firma adjunta se cierra formalmente el proceso de reparación y devolución '
                'del equipo a su titular.',
                style: PdfTema.body(),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Columna firma
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Firma del Receptor', style: PdfTema.etiqueta()),
                      pw.SizedBox(height: 6),
                      firmaWidget(),
                      pw.SizedBox(height: 6),
                      pw.Text('$nombreReceptor • RUT: $rutReceptor', style: PdfTema.small()),
                    ],
                  ),
                  pw.SizedBox(width: 24),
                  // Columna datos equipo resumen
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfTema.colorBorde),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('RESUMEN DE ENTREGA', style: PdfTema.etiqueta()),
                          pw.SizedBox(height: 8),
                          _resumenFila('Folio', folio),
                          _resumenFila('Cliente', nombreCliente),
                          _resumenFila('Equipo', '$tipoEquipo $marca'.trim()),
                          _resumenFila('Serie', serie),
                          _resumenFila('Fecha', fechaEntrega),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );

    return PdfUtils.guardarLocal(doc, '$folio.pdf');
  }

  // ── Widgets privados ─────────────────────────────────────────────

  static pw.Widget _seccion(String titulo, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfTema.colorFondoSec,
        border: pw.Border.all(color: PdfTema.colorBorde),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo.toUpperCase(), style: PdfTema.h2()),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _campo(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(etiqueta, style: PdfTema.etiqueta()),
          ),
          pw.Expanded(child: pw.Text(valor, style: PdfTema.body())),
        ],
      ),
    );
  }

  static pw.Widget _resumenFila(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(label, style: PdfTema.etiqueta()),
          ),
          pw.Expanded(child: pw.Text(valor, style: PdfTema.body())),
        ],
      ),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _fmtFechaHora(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final fecha = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      final hora  = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      return '$fecha  $hora hrs';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
