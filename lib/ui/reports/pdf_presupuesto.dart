import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

class PdfPresupuesto {
  static Future<File> generar({
    required Map<String, dynamic> presupuesto,
  }) async {
    final doc = pw.Document();

    final folio =
        'PRES-${(presupuesto['id_presupuesto'] ?? '0000').toString().padLeft(4, '0')}';
    final qrData =
        'gontech://presupuestos/${presupuesto['id_presupuesto'] ?? ''}';

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 1. Datos Formales de Cotización
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFAFAFA),
            border: pw.Border.all(color: PdfTema.colorPrimario),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CLIENTE', style: PdfTema.small()),
                    pw.Text(presupuesto['cliente'] ?? '-', style: PdfTema.h2()),
                    pw.SizedBox(height: 8),
                    pw.Text('FECHA EMISION', style: PdfTema.small()),
                    pw.Text(
                      presupuesto['fecha_creacion'] ?? '-',
                      style: PdfTema.body(),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('EQUIPO A INTERVENIR', style: PdfTema.small()),
                    pw.Text(
                      '${presupuesto['tipo_equipo'] ?? '-'} ${presupuesto['marca'] ?? ''}',
                      style: PdfTema.h2(),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('ESTADO', style: PdfTema.small()),
                    pw.Text(
                      _formatEstado(presupuesto['estado']),
                      style: PdfTema.body(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // 2. Detalle Comercial
        _buildSeccion('Detalle de Servicios / Intervencion', [
          _buildCampo(
            'Diagnostico Tecnico',
            presupuesto['descripcion_falla'] ?? '-',
          ),
          _buildCampo(
            'Propuesta de Reparacion',
            presupuesto['descripcion'] ?? '-',
          ),
        ]),
        pw.SizedBox(height: 16),

        // 3. Total destacado (Estilo Cotización)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfTema.colorFondo,
            border: pw.Border.all(color: PdfTema.colorPrimario, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TOTAL A PAGAR',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfTema.colorTexto,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Valores expresados en Pesos Chilenos (CLP)',
                    style: PdfTema.small(),
                  ),
                ],
              ),
              pw.Text(
                '\$${presupuesto['total']?.toStringAsFixed(0) ?? '0'}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfTema.colorPrimario,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '* Valores sujetos a modificacion si se encuentran daños ocultos no detectados en evaluacion inicial.\n'
            '* Esta cotizacion tiene una validez de 10 dias habiles.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColor.fromInt(0xFF757575),
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),

        pw.SizedBox(height: 30),

        // 4. Sección de autorización
        _buildSeccion('Aprobacion de Presupuesto', [
          pw.Text(
            'Con la firma de este documento, el cliente aprueba la cotizacion de servicios detallada previamente y autoriza '
            'al servicio tecnico a proceder con las reparaciones y/o adquisicion de repuestos necesarios.',
            style: PdfTema.body(),
          ),
          pw.SizedBox(height: 35),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _firmaBox('Firma de Aprobacion Titular'),
              pw.SizedBox(width: 40),
              _firmaBox('Fecha de Aprobacion'),
            ],
          ),
        ]),
      ],
    );

    doc.addPage(
      PdfBase.buildA4(
        titulo: 'Cotizacion Comercial',
        subtitulo: 'Presupuesto de Servicios Automotriz / Tecnico',
        folio: folio,
        qrData: qrData,
        content: content,
      ),
    );

    return await PdfUtils.guardarLocal(doc, '$folio.pdf');
  }

  static String _formatEstado(dynamic estado) {
    switch (estado) {
      case 'autorizado':
        return 'Autorizado';
      case 'rechazado':
        return 'Rechazado';
      case 'pendiente':
        return 'Pendiente de aprobacion';
      default:
        return estado?.toString() ?? '-';
    }
  }

  static pw.Widget _firmaBox(String label) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Container(height: 1, color: PdfTema.colorTextoSec),
          pw.SizedBox(height: 4),
          pw.Text(label, style: PdfTema.small()),
        ],
      ),
    );
  }
  static pw.Widget _buildSeccion(String titulo, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFAFAFA),
        border: pw.Border.all(color: PdfTema.colorPrimario),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfTema.colorPrimario,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildCampo(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(etiqueta, style: PdfTema.small()),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(valor, style: PdfTema.body()),
          ),
        ],
      ),
    );
  }
}
