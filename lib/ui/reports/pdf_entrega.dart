import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

class PdfEntrega {
  static Future<File> generar(Map<String, dynamic> entrega) async {
    final doc = pw.Document();

    final folio =
        'ENT-${(entrega['id_entrega'] ?? '0000').toString().padLeft(4, '0')}';
    final qrData = 'gontech://entregas/${entrega['id_entrega'] ?? ''}';

    pw.Widget firmaWidget() {
      final path = (entrega['firma_path'] ?? '').toString();
      if (path.isEmpty) {
        return pw.Text('Sin firma registrada', style: PdfTema.small());
      }
      final file = File(path);
      if (!file.existsSync()) {
        return pw.Text(
          'Archivo de firma no encontrado',
          style: PdfTema.small(),
        );
      }
      final bytes = file.readAsBytesSync();
      final image = pw.MemoryImage(bytes);
      return pw.Container(
        height: 80,
        width: 220,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfTema.colorPrimario, width: 0.5),
        ),
        child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      );
    }

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Datos del Cliente', style: PdfTema.h2()),
        pw.SizedBox(height: 4),
        pw.Text(
          'Nombre: ${entrega['nombre_receptor'] ?? '-'}',
          style: PdfTema.body(),
        ),
        pw.Text(
          'RUT: ${entrega['rut_receptor'] ?? '-'}',
          style: PdfTema.body(),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Detalle de Reparación', style: PdfTema.h2()),
        pw.SizedBox(height: 4),
        pw.Text(
          'Reparación: ${entrega['descripcion_reparacion'] ?? '-'}',
          style: PdfTema.body(),
        ),
        pw.Text(
          'Fecha: ${entrega['fecha_entrega'] ?? '-'}',
          style: PdfTema.body(),
        ),
        pw.Text('Estado: ${entrega['estado'] ?? '-'}', style: PdfTema.body()),
        pw.SizedBox(height: 10),
        pw.Text(
          (entrega['observaciones']?.toString().isNotEmpty ?? false)
              ? 'Observaciones: ${entrega['observaciones']}'
              : 'Sin observaciones registradas.',
          style: PdfTema.body(),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Firma del Cliente', style: PdfTema.h2()),
                pw.SizedBox(height: 6),
                firmaWidget(),
              ],
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Text(
                'Declaro haber recibido el equipo a conformidad. '
                'Este comprobante respalda la devolución y cierra el proceso técnico.',
                style: PdfTema.small(),
              ),
            ),
          ],
        ),
      ],
    );

    doc.addPage(
      PdfBase.buildA4(
        titulo: 'Comprobante de Entrega',
        subtitulo: 'Servicio Técnico – Gontech Flow',
        folio: folio,
        qrData: qrData,
        content: content,
      ),
    );

    final file = await PdfUtils.guardarLocal(doc, '$folio.pdf');
    return file;
  }
}
