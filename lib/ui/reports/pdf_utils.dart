import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

/// Utilidades para guardar, abrir, compartir e imprimir documentos PDF.
/// Todos los métodos son estáticos y operan sobre [pw.Document].
class PdfUtils {
  static const String _carpeta = 'GontechFlow';

  /// Guarda el documento PDF en el directorio de documentos de la aplicación.
  /// Retorna el [File] generado con la ruta completa.
  static Future<File> guardarLocal(
    pw.Document doc,
    String nombreArchivo,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_carpeta';
    await Directory(path).create(recursive: true);
    final file = File('$path/$nombreArchivo');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  /// Guarda el documento y retorna un registro con el [File] y su ruta legible.
  static Future<({File file, String ruta})> guardarYMostrarRuta(
    pw.Document doc,
    String nombreArchivo,
  ) async {
    final file = await guardarLocal(doc, nombreArchivo);
    final rutaCorta = '$_carpeta/$nombreArchivo';
    return (file: file, ruta: rutaCorta);
  }

  /// Abre el PDF con el visor del dispositivo (via open_filex).
  static Future<void> abrir(File file) async {
    await OpenFilex.open(file.path);
  }

  /// Imprime el documento via el sistema de impresión nativo.
  static Future<void> imprimir(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  /// Abre el menú nativo de compartir (WhatsApp, Gmail, Drive, etc.)
  static Future<void> compartir(pw.Document doc, String nombre) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: nombre);
  }

  /// Comparte un PDF desde bytes ya generados (sin necesitar el documento).
  static Future<void> compartirBytes(Uint8List bytes, String nombre) async {
    await Printing.sharePdf(bytes: bytes, filename: nombre);
  }

  /// Imprime desde bytes ya generados.
  static Future<void> imprimirBytes(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
