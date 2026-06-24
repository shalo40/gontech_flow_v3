import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'pdf_utils.dart';

/// Bottom sheet reutilizable para generar y compartir PDFs institucionales.
/// Recibe un [Future<File>] generador y maneja estados loading/listo/error.
///
/// Uso:
/// ```dart
/// PdfShareSheet.mostrar(
///   context,
///   titulo: 'Cotización PRES-0001',
///   generador: () => PdfPresupuesto.generar(presupuesto: doc),
///   nombreArchivo: 'PRES-0001.pdf',
///   subject: 'Cotización Gontech Solutions',
/// );
/// ```
class PdfShareSheet {
  static void mostrar(
    BuildContext context, {
    required String titulo,
    required Future<File> Function() generador,
    required String nombreArchivo,
    String? subject,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PdfSheetBody(
        titulo: titulo,
        generador: generador,
        nombreArchivo: nombreArchivo,
        subject: subject,
      ),
    );
  }
}

// ─── Widget interno ──────────────────────────────────────────────────────────

class _PdfSheetBody extends StatefulWidget {
  final String titulo;
  final Future<File> Function() generador;
  final String nombreArchivo;
  final String? subject;

  const _PdfSheetBody({
    required this.titulo,
    required this.generador,
    required this.nombreArchivo,
    this.subject,
  });

  @override
  State<_PdfSheetBody> createState() => _PdfSheetBodyState();
}

class _PdfSheetBodyState extends State<_PdfSheetBody> {
  _Estado _estado = _Estado.generando;
  File?   _file;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generar();
  }

  Future<void> _generar() async {
    try {
      final file = await widget.generador();
      if (mounted) setState(() { _file = file; _estado = _Estado.listo; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _estado = _Estado.error; });
    }
  }

  Future<void> _ejecutar(_Accion accion) async {
    if (_file == null) return;
    try {
      switch (accion) {
        case _Accion.ver:
          await PdfUtils.abrir(_file!);
          break;
        case _Accion.compartir:
          await Printing.sharePdf(
            bytes: await _file!.readAsBytes(),
            filename: widget.nombreArchivo,
            subject: widget.subject,
          );
          break;
        case _Accion.imprimir:
          if (mounted) Navigator.pop(context);
          await Printing.layoutPdf(onLayout: (_) => _file!.readAsBytes());
          break;
        case _Accion.guardar:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('💾 Guardado: ${_file!.path.split(RegExp(r"[\\/]")).last}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0D7A72),
              duration: const Duration(seconds: 4),
            ));
            Navigator.pop(context);
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7A72).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined,
                      color: Color(0xFF0D7A72), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.titulo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(widget.nombreArchivo,
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 18),
          // Cuerpo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _buildCuerpo(),
          ),
        ],
      ),
    );
  }

  Widget _buildCuerpo() {
    switch (_estado) {
      case _Estado.generando:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF0D7A72), strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Generando documento institucional...',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
            ],
          ),
        );

      case _Estado.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              const Text('Error al generar el PDF',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(_error ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _estado = _Estado.generando);
                  _generar();
                },
                child: const Text('Reintentar', style: TextStyle(color: Color(0xFF0D7A72))),
              ),
            ],
          ),
        );

      case _Estado.listo:
        return Column(
          children: [
            // Barra de éxito
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D7A72).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D7A72).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF0D7A72), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Listo: ${_file!.path.split(RegExp(r"[\\/]")).last}',
                      style: const TextStyle(color: Color(0xFF0D7A72), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Botón principal: Compartir
            _btnPrincipal(
              icono: Icons.share_outlined,
              titulo: 'Compartir',
              subtitulo: 'WhatsApp, Gmail, Drive y más...',
              color: const Color(0xFF0D7A72),
              onTap: () => _ejecutar(_Accion.compartir),
            ),
            const SizedBox(height: 8),
            _btnPrincipal(
              icono: Icons.visibility_outlined,
              titulo: 'Ver documento',
              subtitulo: 'Abrir con el visor PDF',
              color: Colors.blueAccent,
              onTap: () => _ejecutar(_Accion.ver),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _btnSecundario(
                  icono: Icons.print_outlined,
                  titulo: 'Imprimir',
                  color: Colors.purpleAccent,
                  onTap: () => _ejecutar(_Accion.imprimir),
                )),
                const SizedBox(width: 8),
                Expanded(child: _btnSecundario(
                  icono: Icons.save_alt_outlined,
                  titulo: 'Guardar',
                  color: Colors.orangeAccent,
                  onTap: () => _ejecutar(_Accion.guardar),
                )),
              ],
            ),
          ],
        );
    }
  }

  Widget _btnPrincipal({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _btnSecundario({
    required IconData icono,
    required String titulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 22),
            const SizedBox(height: 4),
            Text(titulo, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

enum _Estado { generando, listo, error }
enum _Accion { ver, compartir, imprimir, guardar }
