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
                      Text('Actividad reciente', style: AppTextStyles.titulo),
                      const SizedBox(height: 10),

                      provider.ultimosIngresos.isEmpty
                          ? const Text(
                              'No hay ingresos recientes.',
                              style: TextStyle(color: Colors.white70),
                            )
                          : Column(
                              children: provider.ultimosIngresos.map((i) {
                                return Card(
                                  color: AppColors.fondo.withValues(alpha: 0.9),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.laptop_mac,
                                      color: Colors.tealAccent,
                                    ),
                                    title: Text(
                                      '${i['tipo_equipo'] ?? ''} ${i['marca'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Cliente: ${i['nombre_cliente'] ?? '-'}\n'
                                      'Fecha: ${i['fecha_ingreso'] ?? '-'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        height: 1.3,
                                      ),
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
