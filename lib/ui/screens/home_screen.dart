import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gontech_flow_v2/ui/layout/layout_principal.dart';
import '../../core/providers/helpdesk_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpdeskProvider>().cargarDashboard();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final Map<String, String> rutas = {
    'Clientes': '/clientes',
    'Equipos': '/equipos',
    'Ingresos': '/ingresos',
    'Diagnósticos': '/diagnosticos',
    'Presupuestos': '/presupuestos',
    'Reparaciones': '/reparaciones',
  };

  final Map<String, Color> colores = {
    'Clientes': Colors.blueAccent,
    'Equipos': Colors.purpleAccent,
    'Ingresos': Colors.greenAccent,
    'Diagnósticos': Colors.orangeAccent,
    'Presupuestos': Colors.tealAccent,
    'Reparaciones': Colors.amberAccent,
  };

  final Map<String, IconData> iconos = {
    'Clientes': Icons.group,
    'Equipos': Icons.devices,
    'Ingresos': Icons.receipt_long,
    'Diagnósticos': Icons.biotech,
    'Presupuestos': Icons.attach_money,
    'Reparaciones': Icons.build,
  };

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final auth = context.watch<AuthProvider>();

    return LayoutPrincipal(
      titulo: 'Panel Principal',
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Consumer<HelpdeskProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 200),
                    child: CircularProgressIndicator(
                      color: Colors.tealAccent,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: provider.cargarDashboard,
                color: Colors.tealAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${auth.nombre.split(' ').first}',
                        style: AppTextStyles.titulo,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Resumen general del taller',
                        style: AppTextStyles.etiqueta,
                      ),
                      const SizedBox(height: 20),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.resumen.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: ancho < 600
                                  ? 2
                                  : ancho < 900
                                  ? 3
                                  : 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: ancho < 400 ? 1 : 1.15,
                            ),
                        itemBuilder: (context, index) {
                          final key = provider.resumen.keys.elementAt(index);
                          return _tarjetaResumen(
                            context,
                            titulo: key,
                            valor: provider.resumen[key] ?? 0,
                            icono: iconos[key]!,
                            color: colores[key]!,
                            ruta: rutas[key]!,
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                      // ─── Actividad Reciente ────────────────────────────
                      Text('Actividad reciente', style: AppTextStyles.titulo),
                      const SizedBox(height: 4),
                      Text(
                        'Últimos ingresos al taller',
                        style: AppTextStyles.etiqueta,
                      ),
                      const SizedBox(height: 12),

                      provider.ultimosIngresos.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, color: Colors.white12, size: 40),
                                    SizedBox(height: 10),
                                    Text('Sin actividad reciente',
                                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: provider.ultimosIngresos.map((i) {
                                // Extrae datos reales de la estructura anidada de la API
                                final equipo     = i['equipo'];
                                final tipoEq     = equipo?['tipo_equipo'] ?? i['tipo_equipo'] ?? 'Equipo';
                                final marcaEq    = equipo?['marca']       ?? i['marca']       ?? '';
                                final modeloEq   = equipo?['modelo']      ?? i['modelo']      ?? '';
                                final serie      = equipo?['numero_serie'] ?? '';
                                final cliente    = equipo?['cliente'];
                                final nomCliente = cliente?['nombre'] ?? i['nombre_cliente'] ?? 'Cliente';
                                final estado     = (i['estado_ingreso'] ?? i['estado'] ?? 'pendiente').toString();

                                // Formatea la fecha
                                String fecha = '-';
                                final rawFecha = i['fecha_ingreso'] ?? i['created_at'];
                                if (rawFecha != null) {
                                  try {
                                    final dt = DateTime.parse(rawFecha.toString());
                                    final diff = DateTime.now().difference(dt);
                                    if (diff.inDays == 0) {
                                      fecha = 'Hoy ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                                    } else if (diff.inDays == 1) {
                                      fecha = 'Ayer';
                                    } else if (diff.inDays < 7) {
                                      fecha = 'Hace ${diff.inDays} días';
                                    } else {
                                      fecha = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
                                    }
                                  } catch (_) {
                                    fecha = rawFecha.toString().split('T').first;
                                  }
                                }

                                // Color por estado
                                Color colorEstado;
                                IconData iconoEstado;
                                switch (estado.toLowerCase()) {
                                  case 'en_reparacion':
                                    colorEstado = Colors.blueAccent; iconoEstado = Icons.build_circle_outlined; break;
                                  case 'finalizado':
                                    colorEstado = Colors.greenAccent; iconoEstado = Icons.check_circle_outline; break;
                                  case 'archivado':
                                    colorEstado = Colors.white38; iconoEstado = Icons.archive_outlined; break;
                                  default:
                                    colorEstado = Colors.orangeAccent; iconoEstado = Icons.hourglass_top_outlined;
                                }

                                return GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/ingresos'),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.fondo.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colorEstado.withValues(alpha: 0.25)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorEstado.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icono del estado
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            color: colorEstado.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: colorEstado.withValues(alpha: 0.25)),
                                          ),
                                          child: Icon(iconoEstado, color: colorEstado, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        // Información central
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$tipoEq $marcaEq'.trim().isEmpty
                                                    ? 'Equipo sin especificar'
                                                    : '$tipoEq $marcaEq'.trim(),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (modeloEq.isNotEmpty)
                                                Text(modeloEq,
                                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 12, color: Colors.white38),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(nomCliente,
                                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ),
                                                  if (serie.isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Text('S/N: $serie',
                                                        style: const TextStyle(color: Colors.white24, fontSize: 10,
                                                            fontFamily: 'monospace')),
                                                  ]
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Columna derecha: fecha + badge
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: colorEstado.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                estado.replaceAll('_', ' ').toUpperCase(),
                                                style: TextStyle(
                                                    color: colorEstado,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.3),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(fecha,
                                                style: const TextStyle(color: Colors.white30, fontSize: 10)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tarjetaResumen(
    BuildContext context, {
    required String titulo,
    required int valor,
    required IconData icono,
    required Color color,
    required String ruta,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondo.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await Navigator.pushNamed(context, ruta);
          if (!mounted) return;
          context.read<HelpdeskProvider>().cargarDashboard();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                '$valor',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
