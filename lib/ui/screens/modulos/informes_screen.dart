import 'package:flutter/material.dart';
import '../../layout/layout_principal.dart';

class InformesScreen extends StatelessWidget {
  const InformesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Informes',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.lightBlueAccent),
            SizedBox(height: 16),
            Text('Sección de Informes (en construcción)'),
          ],
        ),
      ),
    );
  }
}
