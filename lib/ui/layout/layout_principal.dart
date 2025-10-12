import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import 'menu_lateral.dart';

class LayoutPrincipal extends StatefulWidget {
  final Widget child;
  final String titulo;
  final Widget? floatingActionButton; // 👈 Nuevo parámetro opcional

  const LayoutPrincipal({
    super.key,
    required this.child,
    required this.titulo,
    this.floatingActionButton, // 👈 agregado
  });

  @override
  State<LayoutPrincipal> createState() => _LayoutPrincipalState();
}

class _LayoutPrincipalState extends State<LayoutPrincipal> {
  final SessionManager _session = SessionManager();
  String _correo = '';
  String _nombre = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await _session.obtener_usuario();
    setState(() {
      _correo = usuario['correo'] ?? '';
      _nombre = usuario['nombre'] ?? '';
    });
  }

  void _navegar(String ruta) {
    Navigator.pushReplacementNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _session.cerrar_sesion();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: MenuLateral(onSelect: _navegar, correo: _correo, nombre: _nombre),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton, // 👈 agregado aquí
    );
  }
}
