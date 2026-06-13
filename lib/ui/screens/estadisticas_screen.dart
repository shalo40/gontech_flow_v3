import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/helpdesk_provider.dart';
import '../layout/layout_principal.dart';
import '../theme/app_colors.dart';

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
    final formatoPesos = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return LayoutPrincipal(
      titulo: 'Centro de Mando',
      child: Consumer<HelpdeskProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
          }

          // Cálculos Estratégicos
          final totalPresupuestos = provider.presupuestosPendientes + provider.presupuestosAutorizados;
          final totalReparaciones = provider.reparacionesEnProceso + provider.reparacionesFinalizadas;
          final totalEntregas = provider.entregasPendientes + provider.entregasCompletadas;

          return RefreshIndicator(
            onRefresh: provider.recargarTodo,
            color: Colors.tealAccent,
            backgroundColor: AppColors.fondo,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rendimiento Financiero', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // 💰 PANEL FINANCIERO PRINCIPAL
                  _TarjetaFinancieraPremium(
                    titulo: 'Ingresos Proyectados / Autorizados',
                    valor: formatoPesos.format(provider.resumen['Ingresos'] ?? 0),
                    icono: Icons.account_balance_wallet,
                    colorPrincipal: Colors.tealAccent,
                  ),
                  const SizedBox(height: 24),

                  const Text('Embudos de Conversión', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Mide la eficiencia comercial y técnica del taller', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),

                  // 📊 BARRAS DE PROGRESO ESTRATÉGICAS
                  _BarraKPI(
                    titulo: 'Tasa de Aprobación Comercial',
                    subtitulo: 'Presupuestos aceptados por el cliente',
                    completados: provider.presupuestosAutorizados,
                    total: totalPresupuestos > 0 ? totalPresupuestos : 1,
                    colorBase: Colors.greenAccent,
                    icono: Icons.handshake,
                  ),
                  const SizedBox(height: 16),
                  _BarraKPI(
                    titulo: 'Eficiencia de Quirófano',
                    subtitulo: 'Reparaciones terminadas vs En proceso',
                    completados: provider.reparacionesFinalizadas,
                    total: totalReparaciones > 0 ? totalReparaciones : 1,
                    colorBase: Colors.blueAccent,
                    icono: Icons.hardware,
                  ),
                  const SizedBox(height: 16),
                  _BarraKPI(
                    titulo: 'Flujo de Mostrador',
                    subtitulo: 'Equipos retirados por el cliente',
                    completados: provider.entregasCompletadas,
                    total: totalEntregas > 0 ? totalEntregas : 1,
                    colorBase: Colors.purpleAccent,
                    icono: Icons.storefront,
                  ),

                  const SizedBox(height: 32),
                  const Text('Cuellos de Botella Activos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 🚨 ALERTAS DE OPERACIÓN
                  Row(
                    children: [
                      Expanded(child: _AlertaOperativa('Cotizaciones\nEstancadas', provider.presupuestosPendientes.toString(), Colors.orangeAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _AlertaOperativa('Equipos en\nMesa', provider.reparacionesEnProceso.toString(), Colors.amberAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _AlertaOperativa('Listos sin\nRetirar', provider.entregasPendientes.toString(), Colors.pinkAccent)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text('Métricas Base', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // 📦 MÉTRICAS HISTÓRICAS (Lo que antes ocupaba toda la pantalla)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      _MetricaSimple('Clientes Base', provider.resumen['Clientes']?.toString() ?? '0', Icons.group_outlined),
                      _MetricaSimple('Equipos Históricos', provider.resumen['Equipos']?.toString() ?? '0', Icons.devices_other),
                      _MetricaSimple('Órdenes Ingreso', provider.resumen['Ingresos']?.toString() ?? '0', Icons.receipt_long),
                      _MetricaSimple('Informes Emitidos', provider.resumen['Diagnósticos']?.toString() ?? '0', Icons.fact_check_outlined),
                    ],
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
}

// ==========================================
// 💳 COMPONENTES VISUALES PREMIUM
// ==========================================

class _TarjetaFinancieraPremium extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorPrincipal;

  const _TarjetaFinancieraPremium({required this.titulo, required this.valor, required this.icono, required this.colorPrincipal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPrincipal.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorPrincipal.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: colorPrincipal.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colorPrincipal.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icono, color: colorPrincipal, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(valor, style: TextStyle(color: colorPrincipal, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraKPI extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int completados;
  final int total;
  final Color colorBase;
  final IconData icono;

  const _BarraKPI({required this.titulo, required this.subtitulo, required this.completados, required this.total, required this.colorBase, required this.icono});

  @override
  Widget build(BuildContext context) {
    final porcentaje = total > 0 ? completados / total : 0.0;
    final porcentajeTexto = (porcentaje * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: colorBase, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(subtitulo, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$completados / $total', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('$porcentajeTexto%', style: TextStyle(color: colorBase, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(colorBase),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaOperativa extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _AlertaOperativa(this.titulo, this.valor, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(valor, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2)),
        ],
      ),
    );
  }
}

class _MetricaSimple extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _MetricaSimple(this.titulo, this.valor, this.icono);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.white38, size: 24),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(titulo, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}