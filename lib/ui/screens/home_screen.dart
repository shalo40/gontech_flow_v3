import 'package:flutter/material.dart';
import 'package:gontech_flow_v2/ui/layout/layout_principal.dart';
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

  final List<Map<String, dynamic>> _resumenes = [
    {
      'titulo': 'Clientes',
      'icono': Icons.group,
      'color': Colors.blueAccent,
      'valor': 23,
    },
    {
      'titulo': 'Equipos',
      'icono': Icons.devices,
      'color': Colors.purpleAccent,
      'valor': 42,
    },
    {
      'titulo': 'Ingresos',
      'icono': Icons.receipt_long,
      'color': Colors.greenAccent,
      'valor': 12,
    },
    {
      'titulo': 'Diagnósticos',
      'icono': Icons.biotech,
      'color': Colors.orangeAccent,
      'valor': 8,
    },
    {
      'titulo': 'Presupuestos',
      'icono': Icons.attach_money,
      'color': Colors.tealAccent,
      'valor': 5,
    },
    {
      'titulo': 'Reparaciones',
      'icono': Icons.build,
      'color': Colors.amberAccent,
      'valor': 7,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;

    return LayoutPrincipal(
      titulo: 'Panel Principal',
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenido 👋', style: AppTextStyles.titulo),
                  const SizedBox(height: 6),
                  Text(
                    'Resumen general del taller',
                    style: AppTextStyles.etiqueta,
                  ),
                  const SizedBox(height: 20),

                  // 🧱 GRID de tarjetas resumen
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _resumenes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      final r = _resumenes[index];
                      return _tarjetaResumen(
                        titulo: r['titulo'],
                        valor: r['valor'],
                        icono: r['icono'],
                        color: r['color'],
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  Text('Accesos rápidos', style: AppTextStyles.titulo),
                  const SizedBox(height: 10),

                  // ⚙️ Botones de acceso rápido
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _botonAcceso(
                        context,
                        Icons.group,
                        'Clientes',
                        '/clientes',
                      ),
                      _botonAcceso(
                        context,
                        Icons.devices,
                        'Equipos',
                        '/equipos',
                      ),
                      _botonAcceso(
                        context,
                        Icons.receipt_long,
                        'Ingresos',
                        '/ingresos',
                      ),
                      _botonAcceso(
                        context,
                        Icons.build,
                        'Reparaciones',
                        '/reparaciones',
                      ),
                      _botonAcceso(
                        context,
                        Icons.assignment,
                        'Informes',
                        '/informes',
                      ),
                      _botonAcceso(
                        context,
                        Icons.done_all,
                        'Entregas',
                        '/entregas',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Tarjeta resumen ----------
  Widget _tarjetaResumen({
    required String titulo,
    required int valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondo.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
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

  // ---------- Botones de acceso rápido ----------
  Widget _botonAcceso(
    BuildContext context,
    IconData icono,
    String texto,
    String ruta,
  ) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, ruta),
      icon: Icon(icono, size: 20),
      label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primario.withOpacity(0.95),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
    );
  }
}
