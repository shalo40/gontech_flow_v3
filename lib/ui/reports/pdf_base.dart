import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'pdf_tema.dart';

/// Layout institucional imprimible para todos los documentos Gontech Flow.
/// Header de 2 bloques: izquierdo (isotipo + marca) | derecho (título + folio + QR).
/// Banda de color debajo del header y footer con paginación.
class PdfBase {
  // ─── Header institucional de 2 bloques ─────────────────────────
  static pw.Widget header({
    required String titulo,
    String? subtitulo,
    String? folio,
    String? qrData,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // ── Bloque izquierdo: Isotipo + Marca ──────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Isotipo "GT" en recuadro verde
                pw.Container(
                  width: 44,
                  height: 44,
                  decoration: pw.BoxDecoration(
                    color: PdfTema.colorPrimario,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'GT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GONTECH FLOW',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfTema.colorTexto,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.Text(
                      'Gontech Solutions – Servicio Técnico',
                      style: PdfTema.small(),
                    ),
                    pw.Text(
                      'contacto@gontechsolutions.cl',
                      style: PdfTema.small(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Bloque derecho: Título + Folio + QR ──────────────
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(titulo.toUpperCase(), style: PdfTema.h2()),
                if (subtitulo != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(subtitulo, style: PdfTema.small()),
                ],
                if (folio != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfTema.colorAcento,
                      border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'Folio: $folio',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfTema.colorPrimario,
                      ),
                    ),
                  ),
                ],
                if (qrData != null && qrData.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: qrData,
                    width: 55,
                    height: 55,
                    color: PdfTema.colorPrimario,
                  ),
                ],
              ],
            ),
          ],
        ),

        // ── Banda de color ─────────────────────────────────────────
        pw.SizedBox(height: 8),
        pw.Container(
          height: 3,
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [PdfTema.colorPrimario, PdfTema.colorSecundario],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Footer institucional con paginación ───────────────────────
  static pw.Widget footer(pw.Context context) {
    final now = DateTime.now();
    final fecha =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return pw.Column(
      children: [
        pw.Container(height: 1, color: PdfTema.colorBorde),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Documento generado por Gontech Flow  •  Gontech Solutions SpA',
              style: PdfTema.small(),
            ),
            pw.Row(
              children: [
                pw.Text(fecha, style: PdfTema.small()),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Pág. ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfTema.colorTextoSec,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Layout de página A4 estándar ─────────────────────────────
  static pw.Page buildA4({
    required pw.Widget content,
    String titulo = '',
    String? subtitulo,
    String? folio,
    String? qrData,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      build: (context) {
        return pw.Container(
          color: PdfTema.colorFondo,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              header(
                titulo: titulo,
                subtitulo: subtitulo,
                folio: folio,
                qrData: qrData,
              ),
              pw.SizedBox(height: 16),
              pw.Container(width: double.infinity, child: content),
              pw.SizedBox(height: 12),
              footer(context),
            ],
          ),
        );
      },
    );
  }

  /// Página multi-content (para documentos largos con pw.MultiPage).
  static pw.MultiPage buildMultiA4({
    required List<pw.Widget> Function(pw.Context) builder,
    String titulo = '',
    String? subtitulo,
    String? folio,
    String? qrData,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      header: (context) => pw.Column(children: [
        header(
          titulo: titulo,
          subtitulo: subtitulo,
          folio: folio,
          qrData: qrData,
        ),
        pw.SizedBox(height: 16),
      ]),
      footer: (context) => pw.Column(children: [
        pw.SizedBox(height: 12),
        footer(context),
      ]),
      build: builder,
    );
  }
}
