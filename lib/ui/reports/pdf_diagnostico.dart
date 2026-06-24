import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

/// Genera el PDF de Reporte Técnico de Diagnóstico.
/// Cadena de datos: diagnostico → ingreso → equipo → cliente
/// Incluye: descripción de falla, pruebas realizadas, posibles causas,
/// conclusiones, complejidad, tiempo estimado y datos del técnico.
class PdfDiagnostico {
  static Future<File> generar(Map<String, dynamic> diagnostico) async {
    final doc = pw.Document();

    // ── Extraer cadena de datos anidada ──────────────────────────────
    final ingreso = diagnostico['ingreso'] as Map<String, dynamic>? ?? {};
    final equipo  = ingreso['equipo']      as Map<String, dynamic>? ?? {};
    final cliente = equipo['cliente']      as Map<String, dynamic>? ?? {};
    final tecnico = diagnostico['tecnico'] as Map<String, dynamic>? ?? {};

    // Datos del cliente
    final nombreCliente = _str(cliente['nombre'])
        ?? _str(diagnostico['nombre_cliente'])
        ?? '-';
    final rutCliente    = _str(cliente['rut']) ?? '-';

    // Datos del equipo
    final tipoEquipo  = _str(equipo['tipo_equipo'])  ?? '-';
    final marcaEquipo = _str(equipo['marca'])         ?? '-';
    final modeloEquipo= _str(equipo['modelo'])        ?? '-';
    final serieEquipo = _str(equipo['numero_serie'])  ?? '-';

    // Datos técnicos del diagnóstico
    final descripcionFalla  = _str(diagnostico['descripcion_falla'])
        ?? _str(diagnostico['descripcion'])
        ?? 'No especificada';
    final pruebasRealizadas = _str(diagnostico['pruebas_realizadas'])
        ?? 'No registradas';
    final posiblesCausas    = _str(diagnostico['posibles_causas']) ?? '';
    final conclusiones      = _str(diagnostico['conclusiones'])     ?? '-';
    final estadoDiag        = _str(diagnostico['estado'])           ?? 'diagnosticado';
    final complejidad       = _str(diagnostico['complejidad'])      ?? '';
    final tiempoEst         = diagnostico['tiempo_estimado_hrs']?.toString() ?? '';

    // Datos del técnico asignado
    final tecnicoNombre = _str(tecnico['name'])
        ?? _str(diagnostico['tecnico_nombre'])
        ?? 'No asignado';

    // Fechas
    final fechaRaw = _str(diagnostico['fecha_diagnostico'])
        ?? _str(diagnostico['creado_en'])
        ?? _str(diagnostico['created_at'])
        ?? '';
    final fechaDiag = _fmtFecha(fechaRaw);

    // OT relacionada (referencia cruzada al ingreso)
    final idIng  = ingreso['id_ingreso']?.toString() ?? '';
    final refOT  = idIng.isNotEmpty ? 'OT-${idIng.padLeft(4, '0')}' : '-';

    // Folio propio del diagnóstico
    final idDiag = diagnostico['id_diagnostico']?.toString()
        ?? diagnostico['id']?.toString()
        ?? '0';
    final folio  = 'DX-${idDiag.padLeft(4, '0')}';
    final qrData = 'gontech://diagnosticos/$idDiag';

    doc.addPage(
      PdfBase.buildA4(
        titulo:    'Reporte Técnico de Diagnóstico',
        subtitulo: 'Servicio Técnico – Gontech Flow',
        folio:     folio,
        qrData:    qrData,
        content: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── 1. Tarjeta cliente + equipo ──────────────────────────
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
                        pw.Text('CLIENTE', style: PdfTema.etiqueta()),
                        pw.Text(nombreCliente, style: PdfTema.h3()),
                        pw.SizedBox(height: 4),
                        _fila('RUT', rutCliente),
                        _fila('OT Ref.', refOT),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Bloque equipo
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('EQUIPO DIAGNOSTICADO', style: PdfTema.etiqueta()),
                        pw.Text('$tipoEquipo $marcaEquipo'.trim(), style: PdfTema.h3()),
                        pw.SizedBox(height: 4),
                        _fila('Modelo', modeloEquipo),
                        _fila('S/N',    serieEquipo),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // ── 2. Metadatos del diagnóstico ─────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfTema.colorBorde),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _fila('Fecha diagnóstico', fechaDiag),
                  _fila('Técnico', tecnicoNombre),
                  if (tiempoEst.isNotEmpty) _fila('Tiempo est.', '$tiempoEst hrs'),
                  if (complejidad.isNotEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: _colorComplejidad(complejidad),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        complejidad.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfTema.colorPrimario,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      estadoDiag.replaceAll('_', ' ').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // ── 3. Descripción de la falla ───────────────────────────
            _seccion('DESCRIPCIÓN DE LA FALLA REPORTADA'),
            pw.SizedBox(height: 8),
            _bloqueCuerpo(descripcionFalla),

            pw.SizedBox(height: 12),

            // ── 4. Pruebas realizadas ────────────────────────────────
            _seccion('PRUEBAS Y DIAGNÓSTICOS REALIZADOS'),
            pw.SizedBox(height: 8),
            _bloqueCuerpo(pruebasRealizadas),

            if (posiblesCausas.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _seccion('POSIBLES CAUSAS IDENTIFICADAS'),
              pw.SizedBox(height: 8),
              _bloqueCuerpo(posiblesCausas),
            ],

            pw.SizedBox(height: 12),

            // ── 5. Conclusiones ──────────────────────────────────────
            _seccion('CONCLUSIONES TÉCNICAS'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfTema.colorAcento,
                border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(conclusiones, style: PdfTema.body()),
            ),

            pw.SizedBox(height: 18),

            // ── 6. Firma del técnico ──────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _bloquesFirma('FIRMA TÉCNICO RESPONSABLE', tecnicoNombre),
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

  static pw.Widget _bloqueCuerpo(String texto) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfTema.colorBorde),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(texto, style: PdfTema.body()),
    );
  }

  static pw.Widget _fila(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: PdfTema.etiqueta()),
          pw.Flexible(child: pw.Text(valor, style: PdfTema.body())),
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

  // Colores para la badge de complejidad
  static PdfColor _colorComplejidad(String c) {
    switch (c.toLowerCase()) {
      case 'critico': return PdfColors.red700;
      case 'alto':    return PdfColors.orange700;
      case 'medio':   return PdfColors.amber700;
      default:        return PdfColors.green700;
    }
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
