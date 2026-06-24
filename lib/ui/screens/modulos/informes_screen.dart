import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cliente.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'documentos_cliente_screen.dart';
import 'informe_modal.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final p = context.read<HelpdeskProvider>();
    await Future.wait([
      p.recargarClientes(),
      p.recargarIngresos(),
      p.recargarDiagnosticos(),
      p.recargarPresupuestos(),
      p.recargarInformes(),
      p.recargarEntregas(),
    ]);
  }

  // ─── Cuenta documentos del cliente en la memoria del provider ───
  _ClienteStats _stats(HelpdeskProvider p, Cliente c) {
    bool match(dynamic doc) {
      final paths = [
        doc['nombre_cliente'],
        doc['equipo']?['cliente']?['nombre'],
        doc['ingreso']?['equipo']?['cliente']?['nombre'],
        doc['diagnostico']?['ingreso']?['equipo']?['cliente']?['nombre'],
        doc['reparacion']?['diagnostico']?['ingreso']?['equipo']?['cliente']?['nombre'],
      ];
      return paths.any((v) => v?.toString().toLowerCase().trim() == c.nombre.toLowerCase().trim());
    }

    return _ClienteStats(
      ingresos:     p.ingresos.where(match).length,
      diagnosticos: p.diagnosticos.where(match).length,
      presupuestos: p.presupuestos.where(match).length,
      informes:     p.informes.where(match).length,
      entregas:     p.entregas.where(match).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final clientes = provider.clientes
        .where((c) => c.nombre.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return LayoutPrincipal(
      titulo: 'Documentación',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_task),
        label: const Text('Informe Técnico', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          await mostrarInformeModal(context, 0);
          await _cargar();
        },
      ),
      child: Column(
        children: [
          // ─── Buscador ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _filtro = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nombre o RUT…',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.person_search_outlined, color: Colors.tealAccent, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // ─── Resumen global ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatPill(label: 'Clientes', value: provider.clientes.length, icon: Icons.people_outline, color: Colors.tealAccent),
                const SizedBox(width: 8),
                _StatPill(label: 'Ingresos', value: provider.ingresos.length, icon: Icons.login_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                _StatPill(label: 'Informes', value: provider.informes.length, icon: Icons.article_outlined, color: Colors.purpleAccent),
              ],
            ),
          ),

          // ─── Lista de clientes ──────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: provider.loading && clientes.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : clientes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_outlined, size: 60, color: Colors.white10),
                              SizedBox(height: 16),
                              Text('No hay clientes registrados.', style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: clientes.length,
                          itemBuilder: (_, i) {
                            final cliente = clientes[i];
                            final stats = _stats(provider, cliente);
                            return _ClienteDocCard(
                              cliente: cliente,
                              stats: stats,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentosClienteScreen(cliente: cliente),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tarjeta de cliente en la lista de documentación
// ══════════════════════════════════════════════════════════════════
class _ClienteDocCard extends StatelessWidget {
  final Cliente cliente;
  final _ClienteStats stats;
  final VoidCallback onTap;

  const _ClienteDocCard({required this.cliente, required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inicial = cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : '?';
    final total = stats.total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(total > 0 ? 0.1 : 0.05)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.tealAccent.withOpacity(0.1),
              child: Text(inicial,
                  style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cliente.nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if ((cliente.rut ?? '').isNotEmpty)
                    Text('RUT: ${cliente.rut}',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 8),
                  // Chips de documentos
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (stats.ingresos > 0)     _DocChip(label: '${stats.ingresos} Ingresos',     color: Colors.orangeAccent),
                      if (stats.diagnosticos > 0)  _DocChip(label: '${stats.diagnosticos} Diagnóst.', color: Colors.tealAccent),
                      if (stats.presupuestos > 0)  _DocChip(label: '${stats.presupuestos} Presupu.',  color: Colors.amberAccent),
                      if (stats.informes > 0)      _DocChip(label: '${stats.informes} Informes',      color: Colors.purpleAccent),
                      if (stats.entregas > 0)      _DocChip(label: '${stats.entregas} Entregas',      color: Colors.greenAccent),
                      if (total == 0)
                        const _DocChip(label: 'Sin documentos', color: Colors.white24),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ══════════════════════════════════════════════════════════════════
class _DocChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DocChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteStats {
  final int ingresos, diagnosticos, presupuestos, informes, entregas;

  const _ClienteStats({
    required this.ingresos,
    required this.diagnosticos,
    required this.presupuestos,
    required this.informes,
    required this.entregas,
  });

  int get total => ingresos + diagnosticos + presupuestos + informes + entregas;
}