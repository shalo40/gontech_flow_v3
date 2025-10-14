import 'package:flutter/material.dart';
import '../../../core/dao/entrega_dao.dart';
import '../../../core/dao/ingreso_dao.dart';
import '../../../core/models/entrega.dart';

Future<void> mostrarEntregaModal(BuildContext context, int idReparacion) async {
  final observacionesCtrl = TextEditingController();
  final dao = EntregaDao();
  final ingresoDao = IngresoDAO();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Registrar Entrega',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Confirme que el equipo fue entregado al cliente.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: observacionesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones finales',
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
          ElevatedButton.icon(
            icon: const Icon(Icons.done_all, color: Colors.white),
            label: const Text('Confirmar entrega'),
            onPressed: () async {
              final entrega = Entrega(
                idReparacion: idReparacion,
                fechaEntrega: DateTime.now().toIso8601String(),
                observaciones: observacionesCtrl.text,
                firmaCliente: '', // lo agregaremos luego (firma digital)
                estado: 'entregado',
              );

              await dao.insertar(entrega);
              await ingresoDao.actualizarEstadoDesdeReparacion(
                idReparacion,
                'finalizado',
              );

              if (context.mounted) Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📦 Entrega registrada')),
              );
            },
          ),
        ],
      );
    },
  );
}
