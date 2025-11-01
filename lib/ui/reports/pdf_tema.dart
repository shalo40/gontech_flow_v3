import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfTema {
  static const PdfColor colorFondo = PdfColor.fromInt(0xFF121221);
  static const PdfColor colorPrimario = PdfColor.fromInt(0xFF19F5E6);
  static const PdfColor colorTexto = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor colorTextoSec = PdfColor.fromInt(0xCCFFFFFF);

  static pw.TextStyle h1() => pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: colorTexto,
  );
  static pw.TextStyle h2() => pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: colorTexto,
  );
  static pw.TextStyle body() =>
      pw.TextStyle(fontSize: 11, color: colorTextoSec);
  static pw.TextStyle small() =>
      pw.TextStyle(fontSize: 9, color: colorTextoSec);
}
