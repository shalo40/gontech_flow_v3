import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import 'menu_lateral.dart';

class LayoutPrincipal extends StatelessWidget {
  final Widget child;
  final String titulo;
  final Widget? floatingActionButton;

  const LayoutPrincipal({
    super.key,
    required this.child,
    required this.titulo,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: MenuLateral(
        onSelect: (ruta) => Navigator.pushReplacementNamed(context, ruta),
        correo: auth.correo,
        nombre: auth.nombre,
      ),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
