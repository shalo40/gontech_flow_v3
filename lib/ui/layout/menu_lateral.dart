import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MenuLateral extends StatelessWidget {
  final Function(String) onSelect;
  final String correo;
  final String nombre;

  const MenuLateral({
    super.key,
    required this.onSelect,
    required this.correo,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.fondo,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(correo, style: const TextStyle(fontSize: 13)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primario, Colors.blueGrey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          _item(context, Icons.dashboard_rounded, 'Inicio', '/home'),
          const Divider(color: Colors.white24, height: 8),

          _seccionTitulo('Gestion Tecnica'),
          _item(context, Icons.group, 'Clientes', '/clientes'),
          _item(context, Icons.devices, 'Equipos', '/equipos'),
          _item(context, Icons.receipt_long, 'Ingresos', '/ingresos'),
          _item(context, Icons.biotech_rounded, 'Diagnosticos', '/diagnosticos'),
          _item(context, Icons.attach_money, 'Presupuestos', '/presupuestos'),
          _item(context, Icons.build, 'Reparaciones', '/reparaciones'),
          _item(context, Icons.inventory_2, 'Repuestos', '/repuestos'),
          _item(context, Icons.done_all, 'Entregas', '/entregas'),

          const Divider(color: Colors.white24, height: 8),

          _seccionTitulo('Reportes y Control'),
          _item(context, Icons.assignment, 'Informes', '/informes'),
          _item(context, Icons.bar_chart, 'Estadisticas', '/estadisticas'),

          const Divider(color: Colors.white24, height: 8),

          _seccionTitulo('Sistema'),
          _item(context, Icons.settings, 'Ajustes', '/ajustes'),
          _logoutItem(context),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String titulo,
    String ruta,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelect(ruta);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Colors.tealAccent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutItem(BuildContext context) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 14),
            const Text(
              'Cerrar sesion',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Text(
        texto.toUpperCase(),
        style: AppTextStyles.etiqueta.copyWith(
          color: Colors.white54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
