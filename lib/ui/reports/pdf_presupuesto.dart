import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'pdf_base.dart';
import 'pdf_tema.dart';
import 'pdf_utils.dart';

/// Genera el PDF de Cotización Comercial (presupuesto) con:
/// - Datos anidados: presupuesto → diagnostico → ingreso → equipo → cliente
/// - Tabla de ítems (mano de obra + repuestos)
/// - Subtotal / IVA 19% / Total en CLP
/// - Cláusula legal de validez 10 días
/// - Espacios de firma del cliente y técnico
class PdfPresupuesto {
  static Future<File> generar({
    required Map<String, dynamic> presupuesto,
  }) async {
    final doc = pw.Document();

    // ── Extraer cadena de datos anidada ──────────────────────────
    final diagnostico = presupuesto['diagnostico'] as Map<String, dynamic>? ?? {};
    final ingreso     = diagnostico['ingreso']    as Map<String, dynamic>? ?? {};
    final equipo      = ingreso['equipo']         as Map<String, dynamic>? ?? {};
    final cliente     = equipo['cliente']         as Map<String, dynamic>? ?? {};

    // Campos directos con fallback a anidados
    final nombreCliente = _str(presupuesto['nombre_cliente'])
        ?? _str(cliente['nombre'])
        ?? _str(presupuesto['cliente'])
        ?? '-';
    final rutCliente    = _str(cliente['rut']) ?? '-';
    final tipoEquipo    = _str(equipo['tipo_equipo'])  ?? _str(presupuesto['tipo_equipo'])  ?? '-';
    final marcaEquipo   = _str(equipo['marca'])        ?? _str(presupuesto['marca'])        ?? '';
    final modeloEquipo  = _str(equipo['modelo'])       ?? _str(presupuesto['modelo'])       ?? '';
    final serieEquipo   = _str(equipo['numero_serie']) ?? '-';
    final descripFalla  = _str(diagnostico['descripcion'])
        ?? _str(presupuesto['descripcion_falla'])
        ?? '-';
    final propuesta     = _str(presupuesto['descripcion']) ?? '-';

    // Fechas
    final fechaRaw   = _str(presupuesto['fecha_creacion'])
        ?? _str(presupuesto['created_at'])
        ?? '';
    final fechaEmision = _fmtFecha(fechaRaw);

    // Folio
    final idPres = presupuesto['id_presupuesto']?.toString() ?? '0';
    final folio  = 'PRES-${idPres.padLeft(4, '0')}';
    final qrData = 'gontech://presupuestos/$idPres';

    // ── Ítems / Repuestos ────────────────────────────────────────
    final repuestos = presupuesto['repuestos'] as List? ?? [];

    // Calcular totales
    double subtotalRepuestos = 0;
    for (final r in repuestos) {
      final precio = (r['precio_unitario'] as num?)?.toDouble() ?? 0;
      final cant   = (r['cantidad'] as num?)?.toInt() ?? 1;
      subtotalRepuestos += precio * cant;
    }

    final manoDeObra = (presupuesto['mano_de_obra'] as num?)?.toDouble()
        ?? (presupuesto['total'] as num?)?.toDouble().clamp(0, double.infinity) ?? 0;

    // Si hay repuestos, mano de obra = total - repuestos; sino usar total directamente
    final manoDeObraFinal = repuestos.isNotEmpty
        ? ((presupuesto['mano_de_obra'] as num?)?.toDouble() ?? 0)
        : (presupuesto['total'] as num?)?.toDouble() ?? manoDeObra;

    final subtotal = manoDeObraFinal + subtotalRepuestos;
    final iva      = subtotal * 0.19;
    final total    = subtotal + iva;

    final fmt  = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final estado = _formatEstado(_str(presupuesto['estado']));

    // ── Contenido ────────────────────────────────────────────────
    doc.addPage(
      PdfBase.buildMultiA4(
        titulo:    'Cotización Comercial',
        subtitulo: 'Presupuesto de Servicios Técnicos',
        folio:     folio,
        qrData:    qrData,
        builder:   (context) => [
          // 1. Tarjeta de datos formales
          _tarjetaDatos(
            nombreCliente: nombreCliente,
            rutCliente:    rutCliente,
            tipoEquipo:    '$tipoEquipo $marcaEquipo'.trim(),
            modeloEquipo:  modeloEquipo,
            serieEquipo:   serieEquipo,
            fechaEmision:  fechaEmision,
            estado:        estado,
          ),

          pw.SizedBox(height: 14),

          // 2. Detalle técnico
          _seccion('Detalle de Intervención', [
            _campo('Falla diagnosticada', descripFalla),
            _campo('Propuesta de reparación', propuesta),
          ]),

          pw.SizedBox(height: 14),

          // 3. Tabla de ítems (si hay repuestos)
          if (repuestos.isNotEmpty) ...[
            _seccion('Detalle de Repuestos', [
              _tablaRepuestos(repuestos, fmt),
            ]),
            pw.SizedBox(height: 14),
          ],

          // 4. Totales
          _bloqueTotal(
            manoDeObra:  manoDeObraFinal,
            subtotal:    subtotal,
            iva:         iva,
            total:       total,
            fmt:         fmt,
          ),

          pw.SizedBox(height: 6),
          pw.Text(
            '* Valores expresados en Pesos Chilenos (CLP) con IVA (19%) incluido.\n'
            '* Esta cotización tiene una validez de 10 días hábiles desde la fecha de emisión.\n'
            '* Los valores están sujetos a modificación si se detectan daños ocultos.',
            style: PdfTema.legal(),
          ),

          pw.SizedBox(height: 24),

          // 5. Sección de autorización + firmas
          _seccion('Aprobación de Presupuesto', [
            pw.Text(
              'Con la firma de este documento, el cliente aprueba la cotización de servicios '
              'detallada anteriormente y autoriza al servicio técnico a proceder con las '
              'reparaciones y/o adquisición de repuestos necesarios.',
              style: PdfTema.body(),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              children: [
                _firmaBox('Firma del Cliente'),
                pw.SizedBox(width: 32),
                _firmaBox('Firma del Técnico'),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                _firmaBox('RUT Cliente: $rutCliente'),
                pw.SizedBox(width: 32),
                _firmaBox('Fecha de Aprobación'),
              ],
            ),
          ]),
        ],
      ),
    );

    return PdfUtils.guardarLocal(doc, '$folio.pdf');
  }

  // ── Widgets privados ─────────────────────────────────────────────

  static pw.Widget _tarjetaDatos({
    required String nombreCliente,
    required String rutCliente,
    required String tipoEquipo,
    required String modeloEquipo,
    required String serieEquipo,
    required String fechaEmision,
    required String estado,
  }) {
    return pw.Container(
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
                pw.Text('CLIENTE', style: PdfTema.etiqueta()),
                pw.Text(nombreCliente, style: PdfTema.h3()),
                pw.SizedBox(height: 2),
                pw.Text('RUT: $rutCliente', style: PdfTema.small()),
                pw.SizedBox(height: 10),
                pw.Text('FECHA DE EMISIÓN', style: PdfTema.etiqueta()),
                pw.Text(fechaEmision, style: PdfTema.body()),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EQUIPO A INTERVENIR', style: PdfTema.etiqueta()),
                pw.Text(tipoEquipo, style: PdfTema.h3()),
                pw.SizedBox(height: 2),
                if (modeloEquipo.isNotEmpty) pw.Text('Modelo: $modeloEquipo', style: PdfTema.small()),
                pw.Text('N/S: $serieEquipo', style: PdfTema.small()),
                pw.SizedBox(height: 10),
                pw.Text('ESTADO', style: PdfTema.etiqueta()),
                pw.Text(estado, style: PdfTema.body()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tablaRepuestos(List items, NumberFormat fmt) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfTema.colorBorde, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfTema.colorPrimario),
          children: ['DESCRIPCIÓN', 'CANT.', 'PRECIO UNIT.', 'SUBTOTAL']
              .map((h) => _celdaHeader(h))
              .toList(),
        ),
        // Mano de obra (si aplica)
        // Filas de repuestos
        ...items.map((r) {
          final desc    = r['nombre'] ?? r['descripcion'] ?? 'Repuesto';
          final cant    = (r['cantidad'] as num?)?.toInt() ?? 1;
          final precio  = (r['precio_unitario'] as num?)?.toDouble() ?? 0;
          final sub     = precio * cant;
          return pw.TableRow(
            children: [
              _celda(desc.toString()),
              _celda(cant.toString(), align: pw.TextAlign.center),
              _celda(fmt.format(precio), align: pw.TextAlign.right),
              _celda(fmt.format(sub), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _bloqueTotal({
    required double manoDeObra,
    required double subtotal,
    required double iva,
    required double total,
    required NumberFormat fmt,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfTema.colorPrimario, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _filaTotales('Mano de obra:', fmt.format(manoDeObra), bold: false),
              _filaTotales('Subtotal:', fmt.format(subtotal), bold: false),
              _filaTotales('IVA (19%):', fmt.format(iva), bold: false),
              pw.SizedBox(height: 4),
              pw.Container(height: 0.5, color: PdfTema.colorBorde, width: 180),
              pw.SizedBox(height: 4),
              _filaTotales('TOTAL A PAGAR:', fmt.format(total), bold: true, large: true),
            ],
          ),
          pw.Text(
            fmt.format(total),
            style: PdfTema.valorDestacado(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _filaTotales(String label, String valor, {bool bold = false, bool large = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: large ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfTema.colorTexto,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: large ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: bold ? PdfTema.colorPrimario : PdfTema.colorTextoSec,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _celdaHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
  );

  static pw.Widget _celda(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: PdfTema.body(), textAlign: align),
    );

  static pw.Widget _firmaBox(String label) {
    return pw.Flexible(
      child: pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 28),
            pw.Container(height: 0.5, color: PdfTema.colorTextoSec),
            pw.SizedBox(height: 4),
            pw.Text(label, style: PdfTema.small()),
          ],
        ),
      ),
    );
  }

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

  static String _formatEstado(String? estado) {
    switch (estado) {
      case 'autorizado': return 'Autorizado ✓';
      case 'rechazado':  return 'Rechazado';
      case 'pendiente':  return 'Pendiente de aprobación';
      default:           return estado ?? '-';
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
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
