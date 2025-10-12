import 'package:flutter/material.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../../core/dao/cliente_dao.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'diagnostico_modal.dart';
import 'ingreso_modal.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  final ingresoDao = IngresoDao();
  final equipoDao = EquipoDao();
  final clienteDao = ClienteDao();
  List<Map<String, dynamic>> ingresos = [];
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final data = await ingresoDao
        .listarIngresosDetallados(); // Incluye cliente/equipo
    setState(() => ingresos = data);
  }

  @override
  Widget build(BuildContext context) {
    final ingresosFiltrados = ingresos
        .where(
          (i) =>
              i['nombre_cliente'].toString().toLowerCase().contains(
                filtro.toLowerCase(),
              ) ||
              i['marca'].toString().toLowerCase().contains(
                filtro.toLowerCase(),
              ) ||
              i['tipo_equipo'].toString().toLowerCase().contains(
                filtro.toLowerCase(),
              ),
        )
        .toList();

    return LayoutPrincipal(
      titulo: 'Ingresos',
      child: Column(
        children: [
          // 🔍 BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o equipo...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (valor) => setState(() => filtro = valor),
            ),
          ),

          Expanded(
            child: ingresosFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ingresos registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: ingresosFiltrados.length,
                    itemBuilder: (context, index) {
                      final i = ingresosFiltrados[index];
                      final estado = i['estado_ingreso'] ?? 'pendiente';

                      return Card(
                        color: AppColors.fondo.withOpacity(0.9),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.laptop_mac,
                            color: Colors.tealAccent,
                            size: 36,
                          ),
                          title: Text(
                            '${i['tipo_equipo'] ?? 'Equipo desconocido'} ${i['marca'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Cliente: ${i['nombre_cliente'] ?? 'Sin cliente'}\n'
                            'Ingreso: ${i['fecha_ingreso'] ?? '-'}\n'
                            'Estado: $estado',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.3,
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.withOpacity(
                                0.1,
                              ),
                              foregroundColor: Colors.tealAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.medical_services_outlined,
                              size: 20,
                            ),
                            label: const Text(
                              'Diagnóstico',
                              style: TextStyle(fontSize: 13),
                            ),
                            onPressed: () async {
                              await mostrarDiagnosticoModal(
                                context,
                                i['id_ingreso'],
                              );
                              await cargar();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ➕ BOTÓN FLOTANTE (crear ingreso)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton.extended(
              onPressed: () async {
                await mostrarIngresoModal(context, cargar as int);
                await cargar();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo ingreso'),
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
