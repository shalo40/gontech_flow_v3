import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import '../../reports/pdf_informe.dart';
import '../../reports/pdf_utils.dart';
import 'informe_modal.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  String filtroTexto = '';
  String filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    final provider = context.read<HelpdeskProvider>();
    await provider.recargarInformes();
    // También necesitamos recargar diagnósticos técnicos para el Dashboard
    await provider.recargarDiagnosticos();
  }

  // --- Helpers de Compatibilidad y Extracción Segura ---
  String _getCliente(Map<String, dynamic> i) {
    if (i.containsKey('cliente') && i['cliente'] != null && i['cliente'].toString().isNotEmpty) {
      return i['cliente'].toString();
    }
    if (i['diagnostico'] != null && i['diagnostico']['ingreso'] != null && i['diagnostico']['ingreso']['equipo'] != null && i['diagnostico']['ingreso']['equipo']['cliente'] != null) {
      return i['diagnostico']['ingreso']['equipo']['cliente']['nombre'] ?? 'Cliente desconocido';
    }
    return 'Cliente desconocido';
  }

  String _getMarca(Map<String, dynamic> i) {
    if (i.containsKey('marca') && i['marca'] != null && i['marca'].toString().isNotEmpty) {
      return i['marca'].toString();
    }
    if (i['diagnostico'] != null && i['diagnostico']['ingreso'] != null && i['diagnostico']['ingreso']['equipo'] != null) {
      return i['diagnostico']['ingreso']['equipo']['marca'] ?? 'Sin marca';
    }
    return 'Equipo';
  }

  String _getFechaInforme(Map<String, dynamic> i) {
    // Intentar obtener la fecha de creación del informe o del diagnóstico
    final fechaRaw = i['creado_en'] ?? i['diagnostico']?['created_at'];
    if (fechaRaw != null) {
      return fechaRaw.toString().split('T').first;
    }
    return 'Sin fecha';
  }
  // --------------------------------------------------

  Color _colorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pendiente': return Colors.orangeAccent;
      case 'diagnosticado': return Colors.tealAccent;
      case 'en_reparacion': return Colors.blueAccent;
      case 'entregado': return Colors.greenAccent;
      default: return Colors.white54;
    }
  }

  IconData _iconoEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'diagnosticado': return Icons.analytics_outlined;
      case 'en_reparacion': return Icons.build_circle_outlined;
      case 'entregado': return Icons.check_circle_outline;
      default: return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado desde el cerebro (Provider)
    final provider = context.watch<HelpdeskProvider>();
    final informes = provider.informes;
    final loading = provider.loading;

    // Filtros por texto y estado para la lista scrolleable
    final informesFiltrados = informes.where((i) {
      final texto = filtroTexto.toLowerCase();
      final cliente = _getCliente(i).toLowerCase();
      final marca = _getMarca(i).toLowerCase();
      final coincideTexto = cliente.contains(texto) || marca.contains(texto);

      final estado = (i['diagnostico']?['estado'] ?? 'pendiente').toString().toLowerCase();
      final coincideEstado = filtroEstado == 'todos' || estado == filtroEstado;

      return coincideTexto && coincideEstado;
    }).toList();

    // Contadores para el mini-dashboard
    int porDiagnosticar = 0;
    int entregados = 0;
    for (var i in informes) {
      final estado = (i['diagnostico']?['estado'] ?? 'pendiente').toString().toLowerCase();
      if (estado == 'pendiente') porDiagnosticar++;
      if (estado == 'entregado') entregados++;
    }

    return LayoutPrincipal(
      titulo: 'Informes Técnicos',
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        foregroundColor: AppColors.fondo,
        onPressed: () async {
          await mostrarInformeModal(context, 0); 
          await _cargar();
        },
        child: const Icon(Icons.add_task),
      ),
      child: Column(
        children: [
          // 📊 1. TABLERO DE MÉTRICAS SUPERIOR (Copia exacta del dashboard)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(child: _CardMetricaInforme(titulo: 'Total Registrados', valor: informes.length.toString(), color: Colors.white, icono: Icons.article_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _CardMetricaInforme(titulo: 'Por Diagnosticar', valor: porDiagnosticar.toString(), color: Colors.orangeAccent, icono: Icons.hourglass_empty_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _CardMetricaInforme(titulo: 'Entregados', valor: entregados.toString(), color: Colors.greenAccent, icono: Icons.check_circle_outlined)),
              ],
            ),
          ),

          // 🔍 2. BUSCADOR MODERNIZADO
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (valor) => setState(() => filtroTexto = valor),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o marca...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 🏷️ 3. FILTROS POR ESTADO TÉCNICO (ChoiceChips rediseñados)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chipFiltro('todos', 'Todos', Icons.list_alt),
                _chipFiltro('pendiente', 'Pendiente', Icons.hourglass_empty),
                _chipFiltro('diagnosticado', 'Diagnosticado', Icons.analytics),
                _chipFiltro('en_reparacion', 'Reparación', Icons.build),
                _chipFiltro('entregado', 'Entregado', Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 📋 4. LISTA DE INFORMEStécnicos (Rediseño total de la tarjeta)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: loading && informes.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : informes.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in_outlined, color: Colors.white10, size: 60), SizedBox(height: 16), Text('No hay informes técnicos registrados.', style: TextStyle(color: Colors.white70))]))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: informesFiltrados.length,
                          itemBuilder: (context, index) {
                            final i = informesFiltrados[index];
                            return _cardInformeRedesigned(context, i);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String estado, String label, IconData icono) {
    final activo = filtroEstado == estado;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, size: 14, color: activo ? Colors.black : Colors.white60), const SizedBox(width: 6), Text(label)]),
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.white70, fontSize: 12, fontWeight: activo ? FontWeight.bold : FontWeight.normal),
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        selected: activo,
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = estado),
      ),
    );
  }

  // ===========================================
  // 🆕 TARJETA DE INFORME TÉCNICO (UI Premium)
  // ===========================================
  Widget _cardInformeRedesigned(BuildContext context, Map<String, dynamic> i) {
    final estado = (i['diagnostico']?['estado'] ?? 'pendiente').toString().toLowerCase();
    final colorEst = _colorEstado(estado);
    final cliente = _getCliente(i);
    final marca = _getMarca(i);
    final fecha = _getFechaInforme(i);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fondo.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        // Borde neón basado en el estado técnico del equipo
        border: Border.all(color: colorEst.withOpacity(0.4), width: 1),
        boxShadow: [BoxShadow(color: colorEst.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Navegación al detalle del informe o modal de visualización
            // arguments: i (pasa el informe técnico completo)
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícono de Estado Técnico
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: colorEst.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: colorEst.withOpacity(0.2))),
                  child: Center(child: Icon(_iconoEstado(estado), color: colorEst, size: 28)),
                ),
                const SizedBox(width: 16),
                
                // Info Central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$marca - ID: #${i['id'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(cliente, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white38, size: 12),
                          const SizedBox(width: 4),
                          Text(fecha, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botón PDF y Flecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orangeAccent, size: 24),
                      onPressed: () async {
                        try {
                          // arguments: i (pasa el informe técnico completo para el generador)
                          final file = await PdfInforme.generar(i);
                          await PdfUtils.abrir(file);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al generar PDF: $e'), backgroundColor: Colors.redAccent));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Componente auxiliar para las métricas superior ---
class _CardMetricaInforme extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaInforme({required this.titulo, required this.valor, required this.color, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: color, size: 18),
              Text(valor, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}