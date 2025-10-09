import 'package:flutter/material.dart';

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(nombre),
            accountEmail: Text(correo),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
            decoration: const BoxDecoration(color: Colors.blueAccent),
          ),
          _item(Icons.group, 'Clientes', '/clientes', context),
          _item(Icons.devices, 'Equipos', '/equipos', context),
          _item(Icons.receipt_long, 'Ingresos', '/ingresos', context),
          _item(
            Icons.biotech_rounded,
            'Diagnósticos',
            '/diagnosticos',
            context,
          ),
          _item(Icons.attach_money, 'Presupuestos', '/presupuestos', context),
          _item(Icons.build, 'Reparaciones', '/reparaciones', context),
          _item(Icons.inventory_2, 'Repuestos', '/repuestos', context),
          _item(Icons.assignment, 'Informes', '/informes', context),
          _item(Icons.done_all, 'Entregas', '/entregas', context),
          const Divider(),
          _item(Icons.settings, 'Ajustes', '/ajustes', context),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String titulo,
    String ruta,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(titulo),
      onTap: () {
        Navigator.pop(context);
        onSelect(ruta);
      },
    );
  }
}
