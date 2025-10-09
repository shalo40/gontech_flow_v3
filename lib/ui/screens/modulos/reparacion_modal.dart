import 'package:flutter/material.dart';
import '../../../core/dao/reparacion_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/reparacion.dart';

Future<void> mostrarReparacionModal(
  BuildContext context,
  int idDiagnostico,
) async {
  final descripcionCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();
  final dao = ReparacionDao();
  final ingresoDao = IngresoDao();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Nueva Reparación',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del trabajo',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (descripcionCtrl.text.isEmpty) return;

              final reparacion = Reparacion(
                idDiagnostico: idDiagnostico,
                descripcionTrabajo: descripcionCtrl.text,
                observaciones: observacionesCtrl.text,
                fechaInicio: DateTime.now().toIso8601String(),
                estado: 'en_proceso',
              );

              await dao.insertar(reparacion);
              await ingresoDao.actualizarEstadoDesdeDiagnostico(
                idDiagnostico,
                'en_reparacion',
              );
              if (context.mounted) Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔧 Reparación iniciada')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
