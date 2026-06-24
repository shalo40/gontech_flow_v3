import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/cliente.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import '../../reports/pdf_informe.dart';
import '../../reports/pdf_presupuesto.dart';
import '../../reports/pdf_entrega.dart';
import '../../reports/pdf_ingreso.dart';
import '../../reports/pdf_diagnostico.dart';
import '../../reports/pdf_share_sheet.dart';


/// Pantalla de documentación de un cliente específico.
/// Muestra todos los documentos vinculados: Ingresos, Diagnósticos, Presupuestos, Informes, Entregas.
class DocumentosClienteScreen extends StatefulWidget {
  final Cliente cliente;

  const DocumentosClienteScreen({super.key, required this.cliente});

  @override
  State<DocumentosClienteScreen> createState() => _DocumentosClienteScreenState();
}

class _DocumentosClienteScreenState extends State<DocumentosClienteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    {'label': 'Ingresos',       'icon': Icons.login_rounded},
    {'label': 'Diagnósticos',   'icon': Icons.biotech_outlined},
    {'label': 'Presupuestos',   'icon': Icons.request_quote_outlined},
    {'label': 'Informes',       'icon': Icons.article_outlined},
    {'label': 'Entregas',       'icon': Icons.local_shipping_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final p = context.read<HelpdeskProvider>();
    await Future.wait([
      p.recargarIngresos(),
      p.recargarDiagnosticos(),
      p.recargarPresupuestos(),
      p.recargarInformes(),
      p.recargarEntregas(),
    ]);
  }

  // ─────────────────────────── Helpers ────────────────────────────
  String _fmtFecha(String? raw) {
    if (raw == null || raw.isEmpty) return 'Sin fecha';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _clienteNombre(dynamic doc) {
    // Intenta extraer el nombre desde distintas estructuras de la API
    final paths = [
      () => doc['nombre_cliente'],
      () => doc['equipo']?['cliente']?['nombre'],
      () => doc['ingreso']?['equipo']?['cliente']?['nombre'],
      () => doc['diagnostico']?['ingreso']?['equipo']?['cliente']?['nombre'],
      () => doc['reparacion']?['diagnostico']?['ingreso']?['equipo']?['cliente']?['nombre'],
    ];
    for (final p in paths) {
      final v = p();
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  bool _perteneceAlCliente(dynamic doc) {
    return _clienteNombre(doc).toLowerCase().trim() ==
        widget.cliente.nombre.toLowerCase().trim();
  }

  // ─────────────────────────── Build ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar(context)],
        body: TabBarView(
          controller: _tabController,
          children: [
            _TabIngresos(cliente: widget.cliente, ingresos: provider.ingresos, fmtFecha: _fmtFecha, perteneceAlCliente: _perteneceAlCliente),
            _TabDiagnosticos(diagnosticos: provider.diagnosticos, fmtFecha: _fmtFecha, perteneceAlCliente: _perteneceAlCliente),
            _TabPresupuestos(presupuestos: provider.presupuestos, fmtFecha: _fmtFecha, perteneceAlCliente: _perteneceAlCliente),
            _TabInformes(informes: provider.informes, fmtFecha: _fmtFecha, perteneceAlCliente: _perteneceAlCliente),
            _TabEntregas(entregas: provider.entregas, fmtFecha: _fmtFecha, perteneceAlCliente: _perteneceAlCliente),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final iniciales = widget.cliente.nombre.isNotEmpty
        ? widget.cliente.nombre[0].toUpperCase()
        : '?';

    // Altura exacta de la barra de estado del dispositivo (notch, island, etc.)
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: AppColors.fondo,
      // El leading (botón atrás) ya es gestionado por SliverAppBar sin SafeArea extra
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        // collapseMode.none preserva el gradiente al fondo al colapsar
        collapseMode: CollapseMode.parallax,
        background: Container(
          // El gradiente cubre TODO incluyendo la status bar (full-bleed)
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.tealAccent.withOpacity(0.2), AppColors.fondo],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // Padding superior = altura real de la barra de estado + espacio
          // para el botón de retroceso del SliverAppBar (~56px colapsado)
          // NO usar SafeArea aquí: el SliverAppBar ya gestiona el espacio del back button.
          child: Padding(
            padding: EdgeInsets.only(top: statusBarHeight + 52),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.tealAccent.withOpacity(0.15),
                  child: Text(
                    iniciales,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.cliente.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Dossier de documentos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: AppColors.fondo,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.tealAccent,
            indicatorWeight: 2.5,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: _tabs.map((t) => Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t['icon'] as IconData, size: 16),
                  const SizedBox(width: 6),
                  Text(t['label'] as String),
                ],
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB: INGRESOS
// ══════════════════════════════════════════════════════════════════
class _TabIngresos extends StatelessWidget {
  final Cliente cliente;
  final List<Map<String, dynamic>> ingresos;
  final String Function(String?) fmtFecha;
  final bool Function(dynamic) perteneceAlCliente;

  const _TabIngresos({
    required this.cliente,
    required this.ingresos,
    required this.fmtFecha,
    required this.perteneceAlCliente,
  });

  @override
  Widget build(BuildContext context) {
    final lista = ingresos.where(perteneceAlCliente).toList();
    if (lista.isEmpty) return _emptyState('No hay ingresos registrados', Icons.login_rounded);

    return RefreshIndicator(
      onRefresh: () async => context.read<HelpdeskProvider>().recargarIngresos(),
      color: Colors.tealAccent,
      backgroundColor: AppColors.fondo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final doc = lista[i];
          final equipo = doc['equipo'];
          final equipoStr = equipo != null
              ? '${equipo['tipo_equipo'] ?? ''} ${equipo['marca'] ?? ''}'.trim()
              : 'Equipo no especificado';
          final estado = doc['estado_ingreso'] ?? 'pendiente';
          final fecha = fmtFecha(doc['fecha_ingreso']);

          final folioOT = 'OT-${(doc['id_ingreso'] ?? '0').toString().padLeft(4, '0')}';
          final accentIngreso = _colorEstado(estado);

          return _DocCard(
            icon: Icons.login_rounded,
            title: equipoStr.isEmpty ? 'Ingreso #${doc['id_ingreso'] ?? '-'}' : equipoStr,
            subtitle: 'S/N: ${equipo?['numero_serie'] ?? '-'}',
            fecha: fecha,
            estado: estado,
            accentColor: accentIngreso,
            trailing: _BadgeEstado(estado: estado, color: accentIngreso),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((doc['accesorios'] ?? '').toString().isNotEmpty)
                  _infoRow(Icons.cable, 'Accesorios', doc['accesorios']),
                if ((doc['observaciones'] ?? '').toString().isNotEmpty)
                  _infoRow(Icons.notes, 'Observaciones', doc['observaciones']),
                const SizedBox(height: 10),
                // ── Botón PDF Comprobante de Recepción ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => PdfShareSheet.mostrar(
                      context,
                      titulo: 'Comprobante $folioOT',
                      nombreArchivo: '$folioOT.pdf',
                      subject: 'Comprobante de Recepción – Gontech Solutions',
                      generador: () => PdfIngreso.generar(doc),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('PDF Comprobante de Recepción'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentIngreso,
                      side: BorderSide(color: accentIngreso.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _colorEstado(String? e) {
    switch (e) {
      case 'en_reparacion': return Colors.blueAccent;
      case 'finalizado': return Colors.greenAccent;
      case 'archivado': return Colors.grey;
      default: return Colors.orangeAccent;
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB: DIAGNÓSTICOS
// ══════════════════════════════════════════════════════════════════
class _TabDiagnosticos extends StatelessWidget {
  final List<Map<String, dynamic>> diagnosticos;
  final String Function(String?) fmtFecha;
  final bool Function(dynamic) perteneceAlCliente;

  const _TabDiagnosticos({
    required this.diagnosticos,
    required this.fmtFecha,
    required this.perteneceAlCliente,
  });

  @override
  Widget build(BuildContext context) {
    final lista = diagnosticos.where(perteneceAlCliente).toList();
    if (lista.isEmpty) return _emptyState('Sin diagnósticos técnicos', Icons.biotech_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final doc = lista[i];
        final estado = doc['estado'] ?? 'pendiente';
        final id = doc['id_diagnostico'] ?? doc['id'] ?? '-';
        final fecha = fmtFecha(doc['fecha_diagnostico'] ?? doc['created_at']);

        final folioDX = 'DX-${id.toString().padLeft(4, '0')}';

        return _DocCard(
          icon: Icons.biotech_outlined,
          title: 'Diagnóstico #$id',
          subtitle: doc['ingreso']?['equipo']?['marca'] ?? '',
          fecha: fecha,
          estado: estado,
          accentColor: Colors.tealAccent,
          trailing: _BadgeEstado(estado: estado, color: Colors.tealAccent),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((doc['descripcion'] ?? '').isNotEmpty)
                _infoRow(Icons.description, 'Descripción', doc['descripcion']),
              if ((doc['descripcion_falla'] ?? '').isNotEmpty)
                _infoRow(Icons.warning_amber_outlined, 'Falla reportada', doc['descripcion_falla']),
              if ((doc['tiempo_estimado_hrs'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.timer_outlined, 'Tiempo estimado', '${doc['tiempo_estimado_hrs']} hrs'),
              const SizedBox(height: 10),
              // ── Botón PDF Reporte de Diagnóstico ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => PdfShareSheet.mostrar(
                    context,
                    titulo: 'Diagnóstico $folioDX',
                    nombreArchivo: '$folioDX.pdf',
                    subject: 'Reporte de Diagnóstico Técnico – Gontech Solutions',
                    generador: () => PdfDiagnostico.generar(doc),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF Reporte de Diagnóstico'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    side: const BorderSide(color: Color(0x6600FFD0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB: PRESUPUESTOS
// ══════════════════════════════════════════════════════════════════
class _TabPresupuestos extends StatelessWidget {
  final List<Map<String, dynamic>> presupuestos;
  final String Function(String?) fmtFecha;
  final bool Function(dynamic) perteneceAlCliente;

  const _TabPresupuestos({
    required this.presupuestos,
    required this.fmtFecha,
    required this.perteneceAlCliente,
  });

  @override
  Widget build(BuildContext context) {
    final lista = presupuestos.where(perteneceAlCliente).toList();
    if (lista.isEmpty) return _emptyState('Sin presupuestos emitidos', Icons.request_quote_outlined);

    final fmt = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final doc = lista[i];
        final estado = doc['estado'] ?? 'pendiente';
        final id = doc['id_presupuesto'] ?? doc['id'] ?? '-';
        final total = (doc['total'] as num?) ?? 0;
        final fecha = fmtFecha(doc['fecha_creacion'] ?? doc['created_at']);

        Color color;
        switch (estado) {
          case 'autorizado': color = Colors.greenAccent; break;
          case 'rechazado':  color = Colors.redAccent;   break;
          default:           color = Colors.amberAccent;
        }

        final folio = 'PRES-${id.toString().padLeft(4, '0')}';

        return _DocCard(
          icon: Icons.request_quote_outlined,
          title: 'Cotización #$id',
          subtitle: doc['descripcion'] ?? '',
          fecha: fecha,
          estado: estado,
          accentColor: color,
          trailing: _BadgeEstado(estado: estado, color: color),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL (IVA incl.)', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(fmt.format(total), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Botón PDF
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => PdfShareSheet.mostrar(
                    context,
                    titulo: 'Cotización $folio',
                    nombreArchivo: '$folio.pdf',
                    subject: 'Cotización de Servicios – Gontech Solutions',
                    generador: () => PdfPresupuesto.generar(presupuesto: doc),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF Cotización'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB: INFORMES TÉCNICOS
// ══════════════════════════════════════════════════════════════════
class _TabInformes extends StatelessWidget {
  final List<Map<String, dynamic>> informes;
  final String Function(String?) fmtFecha;
  final bool Function(dynamic) perteneceAlCliente;

  const _TabInformes({
    required this.informes,
    required this.fmtFecha,
    required this.perteneceAlCliente,
  });

  @override
  Widget build(BuildContext context) {
    final lista = informes.where(perteneceAlCliente).toList();
    if (lista.isEmpty) return _emptyState('Sin informes técnicos', Icons.article_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final doc = lista[i];
        final id = doc['id_informe'] ?? doc['id'] ?? '-';
        final fecha = fmtFecha(doc['creado_en'] ?? doc['created_at']);
        final tecnico = doc['tecnico']?['name'] ?? doc['tecnico_nombre'] ?? 'Técnico';

        final folio = 'INF-${id.toString().padLeft(4, '0')}';

        return _DocCard(
          icon: Icons.article_outlined,
          title: 'Informe Técnico #$id',
          subtitle: 'Responsable: $tecnico',
          fecha: fecha,
          estado: 'certificado',
          accentColor: Colors.purpleAccent,
          trailing: _BadgeEstado(estado: 'certificado', color: Colors.purpleAccent),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((doc['descripcion_general'] ?? '').isNotEmpty)
                _infoRow(Icons.description_outlined, 'Trabajo realizado', doc['descripcion_general']),
              if ((doc['conclusiones'] ?? '').isNotEmpty)
                _infoRow(Icons.fact_check_outlined, 'Conclusiones', doc['conclusiones']),
              if ((doc['recomendaciones'] ?? '').isNotEmpty)
                _infoRow(Icons.lightbulb_outline, 'Recomendaciones', doc['recomendaciones']),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => PdfShareSheet.mostrar(
                    context,
                    titulo: 'Informe $folio',
                    nombreArchivo: '$folio.pdf',
                    subject: 'Certificación Técnica – Gontech Solutions',
                    generador: () => PdfInforme.generar(doc),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF Informe Técnico'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purpleAccent,
                    side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB: ENTREGAS
// ══════════════════════════════════════════════════════════════════
class _TabEntregas extends StatelessWidget {
  final List<Map<String, dynamic>> entregas;
  final String Function(String?) fmtFecha;
  final bool Function(dynamic) perteneceAlCliente;

  const _TabEntregas({
    required this.entregas,
    required this.fmtFecha,
    required this.perteneceAlCliente,
  });

  @override
  Widget build(BuildContext context) {
    final lista = entregas.where(perteneceAlCliente).toList();
    if (lista.isEmpty) return _emptyState('Sin comprobantes de entrega', Icons.local_shipping_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (_, i) {
        final doc = lista[i];
        final estado = doc['estado'] ?? 'pendiente';
        final id = doc['id_entrega'] ?? doc['id'] ?? '-';

        // Cadena de datos anidada: entrega → reparacion → diagnostico → ingreso → equipo
        final reparacion  = doc['reparacion'];
        final diagnostico = reparacion?['diagnostico'];
        final ingreso     = diagnostico?['ingreso'];
        final equipo      = ingreso?['equipo'];

        final equipoStr   = equipo != null
            ? '${equipo['tipo_equipo'] ?? ''} ${equipo['marca'] ?? ''}'.trim()
            : 'Entrega #$id';
        final modelo      = equipo?['modelo'] ?? '';
        final serie       = equipo?['numero_serie'] ?? '';
        final receptor    = doc['nombre_receptor'] ?? '';

        // Fallback de fecha: fecha_entrega → created_at
        final fecha = fmtFecha(doc['fecha_entrega'] ?? doc['updated_at'] ?? doc['created_at']);

        Color color = estado == 'entregado' ? Colors.greenAccent : Colors.amberAccent;
        final folioEnt = 'ENT-${id.toString().padLeft(4, '0')}';

        return _DocCard(
          icon: Icons.local_shipping_outlined,
          title: equipoStr.isEmpty ? 'Entrega #$id' : equipoStr,
          subtitle: modelo.isNotEmpty ? modelo : (serie.isNotEmpty ? 'S/N: $serie' : 'Entrega #$id'),
          fecha: fecha,
          estado: estado,
          accentColor: color,
          trailing: _BadgeEstado(estado: estado, color: color),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (serie.isNotEmpty)
                _infoRow(Icons.qr_code_2_outlined, 'Número de serie', serie),
              if (receptor.isNotEmpty)
                _infoRow(Icons.person_outline, 'Recibido por', receptor),
              if ((doc['observaciones'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.notes_outlined, 'Observaciones', doc['observaciones']),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => PdfShareSheet.mostrar(
                    context,
                    titulo: 'Comprobante $folioEnt',
                    nombreArchivo: '$folioEnt.pdf',
                    subject: 'Comprobante de Entrega – Gontech Solutions',
                    generador: () => PdfEntrega.generar(doc),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('PDF Comprobante'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (doc['firma_path'] != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.draw_outlined, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Text('Firma del cliente registrada',
                          style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ══════════════════════════════════════════════════════════════════

Widget _emptyState(String msg, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Colors.white10),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.white38, fontSize: 14)),
      ],
    ),
  );
}

Widget _infoRow(IconData icon, String label, String? value) {
  if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.white38),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BadgeEstado extends StatelessWidget {
  final String estado;
  final Color color;

  const _BadgeEstado({required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        estado.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}

class _DocCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String fecha;
  final String estado;
  final Color accentColor;
  final Widget trailing;
  final Widget body;

  const _DocCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fecha,
    required this.estado,
    required this.accentColor,
    required this.trailing,
    required this.body,
  });

  @override
  State<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends State<_DocCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.accentColor.withOpacity(_expanded ? 0.35 : 0.15)),
          boxShadow: _expanded
              ? [BoxShadow(color: widget.accentColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.accentColor.withOpacity(0.2)),
                    ),
                    child: Icon(widget.icon, color: widget.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (widget.subtitle.isNotEmpty)
                          Text(widget.subtitle,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 10, color: Colors.white30),
                            const SizedBox(width: 4),
                            Text(widget.fecha, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      widget.trailing,
                      const SizedBox(height: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _expanded ? 0.5 : 0,
                        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white24, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              // Detalles expandibles
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.white.withOpacity(0.08), height: 1),
                            const SizedBox(height: 8),
                            widget.body,
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
