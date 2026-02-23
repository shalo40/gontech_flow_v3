import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

class PdfInforme {
  static Future<File> generar(Map<String, dynamic> informe) async {
    final doc = pw.Document();

    final folio =
        'INF-${(informe['id_informe'] ?? '0000').toString().padLeft(4, '0')}';
    final qrData = 'gontech://informes/${informe['id_informe'] ?? ''}';

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _seccion('Informacion del Equipo', [
          _campo('Marca / Modelo', '${informe['marca'] ?? '-'} ${informe['modelo'] ?? ''}'),
          _campo('Cliente', informe['cliente'] ?? '-'),
          _campo('Falla diagnosticada', informe['descripcion_falla'] ?? '-'),
        ]),
        pw.SizedBox(height: 14),
        _seccion('Descripcion General', [
          pw.Text(
            informe['descripcion_general'] ?? 'Sin descripcion.',
            style: PdfTema.body(),
          ),
        ]),
        pw.SizedBox(height: 14),
        _seccion('Conclusiones', [
          pw.Text(
            informe['conclusiones'] ?? 'Sin conclusiones.',
            style: PdfTema.body(),
          ),
        ]),
        pw.SizedBox(height: 14),
        _seccion('Recomendaciones', [
          pw.Text(
            informe['recomendaciones'] ?? 'Sin recomendaciones.',
            style: PdfTema.body(),
          ),
        ]),
        pw.SizedBox(height: 14),
        _campo('Fecha del informe', informe['creado_en'] ?? '-'),
      ],
    );

    doc.addPage(
      PdfBase.buildA4(
        titulo: 'Informe Tecnico',
        subtitulo: 'Servicio Tecnico - Gontech Flow',
        folio: folio,
        qrData: qrData,
        content: content,
      ),
    );

    final file = await PdfUtils.guardarLocal(doc, '$folio.pdf');
    return file;
  }

  static pw.Widget _seccion(String titulo, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: PdfTema.h2()),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
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
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfTema.colorTexto,
              ),
            ),
            pw.TextSpan(text: valor, style: PdfTema.body()),
          ],
        ),
      ),
    );
  }
}
