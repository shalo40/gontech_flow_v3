import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfUtils {
  static Future<File> guardarLocal(
    pw.Document doc,
    String nombreArchivo,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/GontechFlow';
    await Directory(path).create(recursive: true);
    final file = File('$path/$nombreArchivo');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<void> abrir(File file) async {
    await OpenFilex.open(file.path);
  }

  static Future<void> imprimir(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static Future<void> compartir(pw.Document doc, String nombre) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: nombre);
  }
}
