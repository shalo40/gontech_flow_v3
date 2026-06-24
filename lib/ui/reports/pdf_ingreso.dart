import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

/// Genera el PDF de Comprobante de Recepción de Equipo (Ingreso/OT).
/// Cadena de datos: ingreso → equipo → cliente
/// Incluye: datos del cliente, equipo con número de serie, accesorios,
/// observaciones técnicas, estado de la OT y código QR de trazabilidad.
class PdfIngreso {
  static Future<File> generar(Map<String, dynamic> ingreso) async {
    final doc = pw.Document();

    // ── Extraer cadena de datos anidada ──────────────────────────────
    final equipo  = ingreso['equipo']  as Map<String, dynamic>? ?? {};
    final cliente = equipo['cliente']  as Map<String, dynamic>? ?? {};

    // Datos del cliente
    final nombreCliente = _str(cliente['nombre'])
        ?? _str(ingreso['nombre_cliente'])
        ?? '-';
    final rutCliente    = _str(cliente['rut'])      ?? '-';
    final telCliente    = _str(cliente['telefono'])  ?? '-';
    final emailCliente  = _str(cliente['email'])     ?? '-';

    // Datos del equipo
    final tipoEquipo  = _str(equipo['tipo_equipo'])  ?? '-';
    final marcaEquipo = _str(equipo['marca'])         ?? '-';
    final modeloEquipo= _str(equipo['modelo'])        ?? '-';
    final serieEquipo = _str(equipo['numero_serie'])  ?? '-';
    final colorEquipo = _str(equipo['color'])         ?? '';
    final estadoEquipoRaw = _str(equipo['condicion']) ?? '';

    // Datos del ingreso
    final accesorios   = _str(ingreso['accesorios'])     ?? 'Ninguno';
    final observaciones= _str(ingreso['observaciones'])  ?? 'Sin observaciones';
    final estadoOT     = _str(ingreso['estado_ingreso']) ?? 'pendiente';

    // Fechas
    final fechaRaw = _str(ingreso['fecha_ingreso'])
        ?? _str(ingreso['created_at'])
        ?? '';
    final fechaIngreso = _fmtFecha(fechaRaw);

    // Folio y QR
    final idIng  = ingreso['id_ingreso']?.toString() ?? '0';
    final folio  = 'OT-${idIng.padLeft(4, '0')}';
    final qrData = 'gontech://ingresos/$idIng';

    doc.addPage(
      PdfBase.buildA4(
        titulo:    'Comprobante de Recepción',
        subtitulo: 'Orden de Trabajo – Gontech Flow',
        folio:     folio,
        qrData:    qrData,
        content: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── 1. Tarjeta cliente + equipo ───────────────────────────
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
                  // Bloque cliente
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATOS DEL CLIENTE', style: PdfTema.etiqueta()),
                        pw.Text(nombreCliente, style: PdfTema.h3()),
                        pw.SizedBox(height: 4),
                        _fila('RUT',    rutCliente),
                        if (telCliente != '-') _fila('Tel.',  telCliente),
                        if (emailCliente != '-') _fila('Email', emailCliente),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Bloque equipo
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('EQUIPO RECIBIDO', style: PdfTema.etiqueta()),
                        pw.Text('$tipoEquipo $marcaEquipo'.trim(), style: PdfTema.h3()),
                        pw.SizedBox(height: 4),
                        _fila('Modelo', modeloEquipo),
                        _fila('S/N',    serieEquipo),
                        if (colorEquipo.isNotEmpty) _fila('Color', colorEquipo),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── 2. Detalles de la orden ───────────────────────────────
            _seccion('DETALLES DE LA ORDEN DE TRABAJO'),
            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfTema.colorBorde),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _fila('Fecha recepción', fechaIngreso),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfTema.colorPrimario,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          estadoOT.replaceAll('_', ' ').toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('ACCESORIOS INCLUIDOS', style: PdfTema.etiqueta()),
                  pw.SizedBox(height: 3),
                  pw.Text(accesorios, style: PdfTema.body()),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── 3. Observaciones técnicas ─────────────────────────────
            _seccion('OBSERVACIONES TÉCNICAS AL INGRESO'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfTema.colorBorde),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(observaciones, style: PdfTema.body()),
            ),

            pw.SizedBox(height: 18),

            // ── 4. Cláusula legal + firmas ────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfTema.colorBorde, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'El cliente declara haber entregado voluntariamente el equipo '
                'descrito para diagnóstico y/o reparación en las instalaciones '
                'de Gontech Solutions. El plazo estimado de respuesta es de 3 '
                'a 5 días hábiles. Folio: $folio.',
                style: PdfTema.small(),
                textAlign: pw.TextAlign.justify,
              ),
            ),

            pw.SizedBox(height: 20),

            // Espacios de firma
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _bloquesFirma('FIRMA CLIENTE', nombreCliente),
                _bloquesFirma('FIRMA TÉCNICO RECEPTOR', 'Gontech Solutions'),
              ],
            ),
          ],
        ),
      ),
    );

    return PdfUtils.guardarLocal(doc, '$folio.pdf');
  }

  // ─── Helpers privados ──────────────────────────────────────────────

  static pw.Widget _seccion(String titulo) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3, height: 14,
          decoration: pw.BoxDecoration(
            color: PdfTema.colorPrimario,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titulo, style: PdfTema.etiqueta()),
      ],
    );
  }

  static pw.Widget _fila(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text('$label:', style: PdfTema.etiqueta()),
          ),
          pw.Expanded(child: pw.Text(valor, style: PdfTema.body())),
        ],
      ),
    );
  }

  static pw.Widget _bloquesFirma(String titulo, String nombre) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 200, height: 55,
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfTema.colorTexto)),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(titulo, style: PdfTema.etiqueta()),
        pw.Text(nombre, style: PdfTema.small()),
      ],
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _fmtFecha(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
