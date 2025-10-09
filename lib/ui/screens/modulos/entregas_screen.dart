import 'package:flutter/material.dart';
import '../../layout/layout_principal.dart';

class EntregasScreen extends StatelessWidget {
  const EntregasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Entregas',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, size: 80, color: Colors.lightGreenAccent),
            SizedBox(height: 16),
            Text('Sección de Entregas (en construcción)'),
          ],
        ),
      ),
    );
  }
}
