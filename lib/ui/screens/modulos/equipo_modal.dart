import 'package:flutter/material.dart';
import '../../../core/models/equipo.dart';
import '../../../core/dao/equipo_dao.dart';
import '../../theme/app_colors.dart';

Future<int?> mostrarEquipoModal(BuildContext context, int idCliente) async {
  final dao = EquipoDao();

  final tipoCtrl = TextEditingController();
  final marcaCtrl = TextEditingController();
  final modeloCtrl = TextEditingController();
  final serieCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  int? idEquipoCreado;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Registrar nuevo equipo',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(tipoCtrl, 'Tipo de equipo (ej: Notebook, PC, Tablet)'),
            _campo(marcaCtrl, 'Marca'),
            _campo(modeloCtrl, 'Modelo'),
            _campo(serieCtrl, 'N° de serie'),
            _campo(descCtrl, 'Descripción o falla reportada'),
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
            if (tipoCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debe ingresar al menos el tipo de equipo'),
                ),
              );
              return;
            }

            final nuevo = Equipo(
              id_cliente: idCliente,
              tipo_equipo: tipoCtrl.text,
              marca: marcaCtrl.text,
              modelo: modeloCtrl.text,
              numero_serie: serieCtrl.text,
              descripcion: descCtrl.text,
            );

            idEquipoCreado = await dao.insertar(nuevo);

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );

  return idEquipoCreado;
}

Widget _campo(TextEditingController ctrl, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent),
        ),
      ),
    ),
  );
}
