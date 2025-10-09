import 'package:flutter/material.dart';
import '../../layout/layout_principal.dart';

class RepuestosScreen extends StatelessWidget {
  const RepuestosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Repuestos',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text('Sección de Repuestos (en construcción)'),
          ],
        ),
      ),
    );
  }
}
