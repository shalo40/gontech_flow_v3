import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// Paleta y estilos para documentos institucionales imprimibles.
/// Usa fondo blanco + colores corporativos oscuros para correcta legibilidad en papel.
class PdfTema {
  // ─── Colores corporativos ────────────────────────────────────────
  static const PdfColor colorFondo      = PdfColors.white;
  static const PdfColor colorPrimario   = PdfColor.fromInt(0xFF0D7A72); // Teal corporativo
  static const PdfColor colorSecundario = PdfColor.fromInt(0xFF1A5C57); // Teal oscuro
  static const PdfColor colorTexto      = PdfColor.fromInt(0xFF1A1A2E); // Azul oscuro
  static const PdfColor colorTextoSec   = PdfColor.fromInt(0xFF4A4A6A); // Gris azulado
  static const PdfColor colorBorde      = PdfColor.fromInt(0xFFD0EAE8); // Verde muy claro
  static const PdfColor colorFondoSec   = PdfColor.fromInt(0xFFF4FAFA); // Fondo secciones
  static const PdfColor colorAcento     = PdfColor.fromInt(0xFFE8F7F6); // Fondo tarjeta
  static const PdfColor colorRojo       = PdfColor.fromInt(0xFFC0392B); // Alertas
  static const PdfColor colorVerde      = PdfColor.fromInt(0xFF27AE60); // Confirmaciones

  // ─── Estilos de texto ───────────────────────────────────────────
  static pw.TextStyle h1() => pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    color: colorTexto,
    letterSpacing: 0.5,
  );

  static pw.TextStyle h2() => pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: colorPrimario,
  );

  static pw.TextStyle h3() => pw.TextStyle(
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
    color: colorTexto,
  );

  static pw.TextStyle body() => pw.TextStyle(
    fontSize: 10,
    color: colorTexto,
    lineSpacing: 1.4,
  );

  static pw.TextStyle small() => pw.TextStyle(
    fontSize: 8.5,
    color: colorTextoSec,
  );

  static pw.TextStyle etiqueta() => pw.TextStyle(
    fontSize: 7.5,
    fontWeight: pw.FontWeight.bold,
    color: colorTextoSec,
    letterSpacing: 0.8,
  );

  static pw.TextStyle valorDestacado() => pw.TextStyle(
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
    color: colorPrimario,
  );

  static pw.TextStyle cuerpoOscuro() => pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: colorTexto,
  );

  static pw.TextStyle legal() => pw.TextStyle(
    fontSize: 7.5,
    color: colorTextoSec,
    fontStyle: pw.FontStyle.italic,
    lineSpacing: 1.3,
  );
}
