import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/helpdesk_provider.dart';
import '../layout/layout_principal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpdeskProvider>().recargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoPesos = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    return LayoutPrincipal(
      titulo: 'Estadisticas',
      child: Consumer<HelpdeskProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.recargarTodo,
            color: Colors.tealAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen General', style: AppTextStyles.titulo),
                  const SizedBox(height: 6),
                  Text(
                    'Metricas del taller en tiempo real',
                    style: AppTextStyles.etiqueta,
                  ),
                  const SizedBox(height: 20),

                  _seccionTitulo('Volumenes'),
                  _gridMetricas([
                    _Metrica('Clientes', provider.resumen['Clientes'] ?? 0, Icons.group, Colors.blueAccent),
                    _Metrica('Equipos', provider.resumen['Equipos'] ?? 0, Icons.devices, Colors.purpleAccent),
                    _Metrica('Ingresos', provider.resumen['Ingresos'] ?? 0, Icons.receipt_long, Colors.greenAccent),
                    _Metrica('Diagnosticos', provider.resumen['Diagnósticos'] ?? 0, Icons.biotech, Colors.orangeAccent),
                  ]),

                  const SizedBox(height: 24),
                  _seccionTitulo('Reparaciones'),
                  _gridMetricas([
                    _Metrica('En proceso', provider.reparacionesEnProceso, Icons.engineering, Colors.amberAccent),
                    _Metrica('Finalizadas', provider.reparacionesFinalizadas, Icons.check_circle, Colors.greenAccent),
                    _Metrica('Total', provider.resumen['Reparaciones'] ?? 0, Icons.build, Colors.tealAccent),
                  ]),

                  const SizedBox(height: 24),
                  _seccionTitulo('Presupuestos'),
                  _gridMetricas([
                    _Metrica('Pendientes', provider.presupuestosPendientes, Icons.hourglass_empty, Colors.orangeAccent),
                    _Metrica('Autorizados', provider.presupuestosAutorizados, Icons.thumb_up, Colors.greenAccent),
                    _Metrica('Total', provider.resumen['Presupuestos'] ?? 0, Icons.attach_money, Colors.tealAccent),
                  ]),

                  const SizedBox(height: 24),
                  _seccionTitulo('Entregas'),
                  _gridMetricas([
                    _Metrica('Pendientes', provider.entregasPendientes, Icons.pending_actions, Colors.orangeAccent),
                    _Metrica('Completadas', provider.entregasCompletadas, Icons.done_all, Colors.greenAccent),
                  ]),

                  const SizedBox(height: 24),
                  _seccionTitulo('Financiero'),
                  _tarjetaFinanciera(
                    'Ingresos autorizados',
                    formatoPesos.format(provider.resumen['Ingresos'] ?? 0),
                    Icons.monetization_on,
                    Colors.tealAccent,
                  ),

                  const SizedBox(height: 24),
                  _seccionTitulo('Tasa de conversion'),
                  _barraProgreso(
                    'Presupuestos autorizados',
                    provider.presupuestosAutorizados,
                    provider.resumen['Presupuestos'] ?? 0,
                    Colors.greenAccent,
                  ),
                  const SizedBox(height: 12),
                  _barraProgreso(
                    'Reparaciones finalizadas',
                    provider.reparacionesFinalizadas,
                    provider.resumen['Reparaciones'] ?? 0,
                    Colors.tealAccent,
                  ),
                  const SizedBox(height: 12),
                  _barraProgreso(
                    'Entregas completadas',
                    provider.entregasCompletadas,
                    provider.entregasPendientes + provider.entregasCompletadas,
                    Colors.blueAccent,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _seccionTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto.toUpperCase(),
        style: AppTextStyles.etiqueta.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _gridMetricas(List<_Metrica> metricas) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metricas.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final m = metricas[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.fondo.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: m.color.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m.icono, color: m.color, size: 28),
              const SizedBox(height: 8),
              Text(
                '${m.valor}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tarjetaFinanciera(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), AppColors.fondo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraProgreso(
    String titulo,
    int completados,
    int total,
    Color color,
  ) {
    final porcentaje = total > 0 ? completados / total : 0.0;
    final porcentajeTexto = (porcentaje * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondo.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '$completados / $total ($porcentajeTexto%)',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrica {
  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;

  _Metrica(this.titulo, this.valor, this.icono, this.color);
}
