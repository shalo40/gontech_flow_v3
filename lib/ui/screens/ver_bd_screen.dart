import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../layout/layout_principal.dart';
import '../theme/app_colors.dart';

class VerBDScreen extends StatefulWidget {
  const VerBDScreen({super.key});

  @override
  State<VerBDScreen> createState() => _VerBDScreenState();
}

class _VerBDScreenState extends State<VerBDScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<String> _tablas = [];
  List<Map<String, dynamic>> _datos = [];
  String? _tablaSeleccionada;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarTablas();
  }

  Future<void> _cargarTablas() async {
    final db = await dbHelper.database;
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
    );
    setState(() {
      _tablas = res.map((e) => e['name'] as String).toList();
    });
  }

  Future<void> _cargarDatos(String tabla) async {
    setState(() {
      _cargando = true;
      _tablaSeleccionada = tabla;
    });

    final db = await dbHelper.database;
    final res = await db.rawQuery('SELECT * FROM $tabla');
    setState(() {
      _datos = res;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Ver base de datos',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tablaSeleccionada,
              hint: const Text('Seleccionar tabla'),
              items: _tablas
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (tabla) {
                if (tabla != null) _cargarDatos(tabla);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _tablaSeleccionada == null
                  ? const Center(child: Text('Seleccione una tabla'))
                  : _datos.isEmpty
                  ? const Center(child: Text('Sin registros'))
                  : ListView.builder(
                      itemCount: _datos.length,
                      itemBuilder: (context, i) {
                        final fila = _datos[i];
                        return Card(
                          color: AppColors.fondo.withOpacity(0.85),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: fila.entries
                                  .map(
                                    (e) => Text(
                                      "${e.key}: ${e.value ?? 'null'}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
