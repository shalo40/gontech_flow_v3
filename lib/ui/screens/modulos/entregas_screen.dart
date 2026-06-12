import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/dao/entrega_dao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../layout/menu_lateral.dart';
import 'entrega_modal.dart';
import 'firma_modal.dart';
import '../../reports/pdf_entrega.dart';
import '../../reports/pdf_utils.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  final entregaDao = EntregaDao();
  List<Map<String, dynamic>> entregas = [];
  List<Map<String, dynamic>> filtradas = [];
  final busquedaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await entregaDao.listarDetallado();
    if (mounted) {
      setState(() {
        entregas = data;
        filtradas = data;
      });
    }
  }

  void _filtrar(String texto) {
    setState(() {
      filtradas = entregas
          .where(
            (e) =>
                (e['nombre_receptor'] ?? '').toString().toLowerCase().contains(
                  texto.toLowerCase(),
                ) ||
                (e['rut_receptor'] ?? '').toString().toLowerCase().contains(
                  texto.toLowerCase(),
                ) ||
                (e['descripcion_reparacion'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(texto.toLowerCase()),
          )
          .toList();
    });
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '-';
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return fecha;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amberAccent;
      case 'entregado':
        return Colors.tealAccent;
      case 'anulado':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MenuLateral(
        onSelect: (ruta) {
          Navigator.pop(context);
          Navigator.pushNamed(context, ruta);
        },
        correo: 'g.castillo@gontech.cl',
        nombre: 'Gonzalo Castillo',
      ),
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Gestión de Entregas'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Registrar nueva entrega',
            icon: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.tealAccent,
            ),
            onPressed: () => mostrarEntregaModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.tealAccent,
        onRefresh: cargar,
        child: Column(
          children: [
            // 🔍 Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: busquedaCtrl,
                onChanged: _filtrar,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente, RUT o reparación...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            // 📋 Listado de entregas
            Expanded(
              child: filtradas.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay entregas registradas.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filtradas.length,
                      itemBuilder: (context, index) {
                        final e = filtradas[index];
                        final color = _colorEstado(e['estado'] ?? 'pendiente');

                        return GestureDetector(
                          onTap: () => _mostrarDetalleEntrega(context, e),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.fondo.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: Icon(
                                e['estado'] == 'entregado'
                                    ? Icons.verified
                                    : Icons.pending_actions,
                                color: color,
                                size: 30,
                              ),
                              title: Text(
                                e['nombre_receptor'] ?? '-',
                                style: AppTextStyles.tituloCard.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'RUT: ${e['rut_receptor'] ?? '-'}\n'
                                'Reparación: ${e['descripcion_reparacion'] ?? '-'}\n'
                                'Fecha: ${_formatearFecha(e['fecha_entrega'])}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧾 Detalle modal inferior
  void _mostrarDetalleEntrega(
    BuildContext context,
    Map<String, dynamic> entrega,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondo.withOpacity(0.97),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: _colorEstado(entrega['estado']),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Comprobante de Entrega',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white24),

                // Datos generales
                Text(
                  'Cliente: ${entrega['nombre_receptor'] ?? '-'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'RUT: ${entrega['rut_receptor'] ?? '-'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Reparación: ${entrega['descripcion_reparacion'] ?? '-'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Fecha entrega: ${_formatearFecha(entrega['fecha_entrega'])}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  entrega['observaciones']?.isNotEmpty == true
                      ? '📝 ${entrega['observaciones']}'
                      : 'Sin observaciones registradas.',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Firma
                if (entrega['firma_path'] != null &&
                    entrega['firma_path'].toString().isNotEmpty)
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Firma del Cliente',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Image.file(
                          File(entrega['firma_path']),
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'Sin firma registrada',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),

                const SizedBox(height: 20),

                // Botón para registrar firma
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.withOpacity(0.2),
                      foregroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.border_color_outlined),
                    label: const Text('Registrar Firma del Cliente'),
                    onPressed: () {
                      Navigator.pop(context);
                      mostrarFirmaModal(
                        context,
                        entrega['id_entrega'],
                        'entrega',
                        cargar,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Botón PDF
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.withOpacity(0.2),
                      foregroundColor: Colors.tealAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Generar comprobante PDF'),
                    onPressed: () async {
                      try {
                        final file = await PdfEntrega.generar(entrega);
                        await PdfUtils.abrir(file);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📄 PDF generado correctamente'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar PDF: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
