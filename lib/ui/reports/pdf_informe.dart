import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

/// Genera el PDF de Informe Técnico (Certificado Técnico Profesional) con:
/// - Cadena anidada: informe → diagnostico → ingreso → equipo → cliente
/// - Layout de 2 columnas (datos del equipo + datos del cliente)
/// - Secciones: Falla Diagnosticada / Procedimiento / Conclusiones / Recomendaciones
/// - Cláusula de certificación técnica
/// - Línea de firma del técnico con nombre y cargo
class PdfInforme {
  static Future<File> generar(Map<String, dynamic> informe) async {
    final doc = pw.Document();

    // ── Extraer cadena de datos anidada ──────────────────────────
    final diagnostico = informe['diagnostico'] as Map<String, dynamic>? ?? {};
    final ingreso     = diagnostico['ingreso']  as Map<String, dynamic>? ?? {};
    final equipo      = ingreso['equipo']       as Map<String, dynamic>? ?? {};
    final cliente     = equipo['cliente']       as Map<String, dynamic>? ?? {};

    // Técnico responsable
    final tecnico      = informe['tecnico']   as Map<String, dynamic>? ?? {};
    final nombreTecnico = _str(tecnico['name'])
        ?? _str(informe['tecnico_nombre'])
        ?? 'Técnico Gontech';
    final cargoTecnico  = _str(tecnico['cargo']) ?? 'Técnico en Reparación';

    // Datos del equipo
    final tipoEquipo  = _str(equipo['tipo_equipo'])  ?? '-';
    final marca       = _str(equipo['marca'])        ?? '-';
    final modelo      = _str(equipo['modelo'])       ?? '-';
    final serie       = _str(equipo['numero_serie']) ?? '-';

    // Datos del cliente
    final nombreCliente = _str(cliente['nombre'])
        ?? _str(informe['cliente'])
        ?? '-';
    final rutCliente    = _str(cliente['rut']) ?? '-';
    final telefonoCli   = _str(cliente['telefono']) ?? '-';

    // Contenido del informe
    final fallaDesc      = _str(diagnostico['descripcion'])
        ?? _str(informe['descripcion_falla'])
        ?? '-';
    final descGeneral    = _str(informe['descripcion_general']) ?? 'Sin descripción del procedimiento.';
    final conclusiones   = _str(informe['conclusiones'])   ?? 'Sin conclusiones registradas.';
    final recomendaciones = _str(informe['recomendaciones']) ?? 'Sin recomendaciones.';

    // Fecha
    final fechaRaw   = _str(informe['creado_en']) ?? _str(informe['created_at']) ?? '';
    final fechaInforme = _fmtFecha(fechaRaw);

    // Folio
    final idInf  = informe['id_informe']?.toString() ?? '0';
    final folio  = 'INF-${idInf.padLeft(4, '0')}';
    final qrData = 'gontech://informes/$idInf';

    doc.addPage(
      PdfBase.buildMultiA4(
        titulo:    'Informe Técnico',
        subtitulo: 'Certificado de Evaluación Técnica – Gontech Flow',
        folio:     folio,
        qrData:    qrData,
        builder:   (context) => [
          // 1. Layout de 2 columnas: datos equipo | datos cliente
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Columna izquierda: Equipo
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfTema.colorAcento,
                    border: pw.Border.all(color: PdfTema.colorBorde),
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(6),
                      bottomLeft: pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DATOS DEL EQUIPO', style: PdfTema.etiqueta()),
                      pw.SizedBox(height: 8),
                      _campo('Tipo',   tipoEquipo),
                      _campo('Marca',  marca),
                      _campo('Modelo', modelo),
                      _campo('Serie',  serie),
                    ],
                  ),
                ),
              ),
              // Columna derecha: Cliente
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border(
                      top:    pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
                      right:  pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
                      bottom: pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
                      left:   pw.BorderSide.none,
                    ),
                    borderRadius: const pw.BorderRadius.only(
                      topRight: pw.Radius.circular(6),
                      bottomRight: pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DATOS DEL CLIENTE', style: PdfTema.etiqueta()),
                      pw.SizedBox(height: 8),
                      _campo('Nombre',   nombreCliente),
                      _campo('RUT',      rutCliente),
                      _campo('Teléfono', telefonoCli),
                      _campo('Fecha',    fechaInforme),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // 2. Falla diagnosticada
          _seccion('Falla Diagnosticada', [
            pw.Text(fallaDesc, style: PdfTema.body()),
          ]),

          pw.SizedBox(height: 12),

          // 3. Procedimiento / Descripción general
          _seccion('Procedimiento Técnico Realizado', [
            pw.Text(descGeneral, style: PdfTema.body()),
          ]),

          pw.SizedBox(height: 12),

          // 4. Conclusiones
          _seccion('Conclusiones', [
            pw.Text(conclusiones, style: PdfTema.body()),
          ]),

          pw.SizedBox(height: 12),

          // 5. Recomendaciones
          _seccion('Recomendaciones', [
            pw.Text(recomendaciones, style: PdfTema.body()),
          ]),

          pw.SizedBox(height: 20),

          // 6. Cláusula de certificación
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF0F9F8),
              border: pw.Border(
                left: pw.BorderSide(color: PdfTema.colorPrimario, width: 3),
                top: pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
                right: pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
                bottom: pw.BorderSide(color: PdfTema.colorBorde, width: 0.5),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CERTIFICACIÓN TÉCNICA', style: PdfTema.h2()),
                pw.SizedBox(height: 6),
                pw.Text(
                  'El presente documento certifica que el equipo $tipoEquipo marca $marca, '
                  'N/S: $serie, propiedad del cliente $nombreCliente, fue evaluado y/o '
                  'intervenido por personal técnico calificado de Gontech Solutions. '
                  'El diagnóstico y procedimientos descritos en este informe corresponden '
                  'a la evaluación técnica realizada el $fechaInforme.',
                  style: PdfTema.body(),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // 7. Firma del técnico
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 200, height: 0.5, color: PdfTema.colorTextoSec),
                  pw.SizedBox(height: 4),
                  pw.Text(nombreTecnico, style: PdfTema.cuerpoOscuro()),
                  pw.Text(cargoTecnico,  style: PdfTema.small()),
                  pw.Text('Gontech Solutions – Servicio Técnico', style: PdfTema.small()),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return PdfUtils.guardarLocal(doc, '$folio.pdf');
  }

  // ── Widgets privados ─────────────────────────────────────────────

  static pw.Widget _seccion(String titulo, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: PdfTema.colorFondoSec,
        border: pw.Border.all(color: PdfTema.colorBorde),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo.toUpperCase(), style: PdfTema.h2()),
          pw.SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _campo(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfTema.colorTextoSec,
              ),
            ),
            pw.TextSpan(text: valor, style: PdfTema.body()),
          ],
        ),
      ),
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
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
