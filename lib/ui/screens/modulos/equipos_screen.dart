import 'package:flutter/material.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final equipoDao = EquipoDao();
  List<Map<String, dynamic>> equipos = [];

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await equipoDao.listarDetallado();
    setState(() => equipos = data);
  }

  Color _colorEstado(String? estado) {
    switch (estado) {
      case 'diagnosticado':
        return Colors.tealAccent;
      case 'en_reparacion':
        return Colors.amberAccent;
      case 'entregado':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Equipos',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: equipos.isEmpty
            ? const Center(
                child: Text(
                  'No hay equipos registrados.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : RefreshIndicator(
                onRefresh: cargar,
                color: Colors.tealAccent,
                child: ListView.builder(
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final e = equipos[index];
                    final estado = e['estado'] ?? 'pendiente';
                    return Card(
                      color: AppColors.fondo.withOpacity(0.9),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent.withOpacity(0.2),
                          child: const Icon(
                            Icons.computer,
                            color: Colors.tealAccent,
                          ),
                        ),
                        title: Text(
                          '${e['tipo_equipo'] ?? 'Equipo'} ${e['marca'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Cliente: ${e['nombre_cliente'] ?? 'N/D'}\n'
                          'Modelo: ${e['modelo'] ?? '-'}\n'
                          'Serie: ${e['numero_serie'] ?? '-'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _colorEstado(estado),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              estado,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '📋 Detalles del equipo de ${e['nombre_cliente']} (en construcción)',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
