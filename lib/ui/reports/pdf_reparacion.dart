import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

class PdfReparacion {
  static Future<File> generar({
    required Map<String, dynamic> reparacion,
    List<Map<String, dynamic>> repuestos = const [],
  }) async {
    final doc = pw.Document();

    final folio =
        'REP-${(reparacion['id_reparacion'] ?? '0000').toString().padLeft(4, '0')}';
    final qrData = 'gontech://reparaciones/${reparacion['id_reparacion'] ?? ''}';

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _seccion('Informacion del Equipo', [
          _campo('Marca / Modelo', '${reparacion['marca'] ?? '-'} ${reparacion['modelo'] ?? ''}'),
          _campo('Cliente', reparacion['cliente'] ?? '-'),
        ]),
        pw.SizedBox(height: 14),
        _seccion('Diagnostico', [
          _campo('Falla', reparacion['descripcion_falla'] ?? '-'),
          _campo('Conclusiones', reparacion['conclusiones'] ?? '-'),
        ]),
        pw.SizedBox(height: 14),
        _seccion('Detalle de la Reparacion', [
          _campo('Descripcion', reparacion['descripcion'] ?? '-'),
          _campo('Estado', _formatEstado(reparacion['estado'])),
          _campo('Fecha inicio', reparacion['fecha_inicio'] ?? '-'),
          _campo('Fecha fin', reparacion['fecha_fin'] ?? 'En curso'),
          if ((reparacion['notas'] ?? '').toString().isNotEmpty)
            _campo('Notas', reparacion['notas']),
        ]),
        if (repuestos.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('Repuestos utilizados', style: PdfTema.h2()),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfTema.colorTexto,
            ),
            cellStyle: PdfTema.body(),
            headerDecoration: pw.BoxDecoration(
              color: PdfTema.colorPrimario,
            ),
            cellHeight: 24,
            headers: ['Nombre', 'Cant.', 'Costo Unit.', 'Estado'],
            data: repuestos.map((r) => [
              r['nombre'] ?? '-',
              '${r['cantidad'] ?? 1}',
              '\$${r['costo_unitario'] ?? 0}',
              r['estado'] ?? '-',
            ]).toList(),
          ),
        ],
      ],
    );

    doc.addPage(
      PdfBase.buildA4(
        titulo: 'Reporte de Reparacion',
        subtitulo: 'Servicio Tecnico - Gontech Flow',
        folio: folio,
        qrData: qrData,
        content: content,
      ),
    );

    final file = await PdfUtils.guardarLocal(doc, '$folio.pdf');
    return file;
  }

  static String _formatEstado(dynamic estado) {
    switch (estado) {
      case 'en_proceso': return 'En proceso';
      case 'finalizada': return 'Finalizada';
      case 'pendiente': return 'Pendiente';
      default: return estado?.toString() ?? '-';
    }
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
