import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'pdf_tema.dart';

class PdfBase {
  // Encabezado institucional
  static pw.Widget header({
    required String titulo,
    String? subtitulo,
    String? folio, // ej: ENT-2025-0001
    String? qrData, // se puede poner ID/URL
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfTema.colorPrimario, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GONTECH FLOW', style: PdfTema.h1()),
              if (subtitulo != null) pw.SizedBox(height: 2),
              if (subtitulo != null) pw.Text(subtitulo, style: PdfTema.body()),
              pw.SizedBox(height: 6),
              pw.Text(titulo, style: PdfTema.h2()),
              if (folio != null)
                pw.Text('Folio: $folio', style: PdfTema.small()),
            ],
          ),
          if (qrData != null && qrData.isNotEmpty)
            pw.Container(
              width: 70,
              height: 70,
              child: pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: qrData,
                color: PdfTema.colorPrimario,
              ),
            ),
        ],
      ),
    );
  }

  // Pie de página institucional
  static pw.Widget footer() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfTema.colorPrimario, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gontech Solutions • Soporte técnico y digitalización',
            style: PdfTema.small(),
          ),
          pw.Text('contacto@gontechsolutions.cl', style: PdfTema.small()),
        ],
      ),
    );
  }

  // Layout de página estándar
  static pw.Page buildA4({
    required pw.Widget content,
    String titulo = '',
    String? subtitulo,
    String? folio,
    String? qrData,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
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
              pw.SizedBox(height: 12),
              content,
              pw.Spacer(),
              footer(),
            ],
          ),
        );
      },
    );
  }
}
