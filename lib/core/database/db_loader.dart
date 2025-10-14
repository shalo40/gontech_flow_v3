import 'package:flutter/foundation.dart';
import '../dao/cliente_dao.dart';
import '../dao/equipo_dao.dart';
import '../dao/ingreso_dao.dart';
import '../dao/diagnostico_dao.dart';
import '../dao/presupuesto_dao.dart';
import '../dao/repuesto_dao.dart';
import '../dao/entrega_dao.dart';
import '../models/cliente.dart';
import '../models/equipo.dart';
import '../models/ingreso.dart';
import '../models/diagnostico.dart';
import '../models/presupuesto.dart';

/// 🚀 Cargador de datos de demostración Gontech Flow v3.
/// Genera datos de ejemplo coherentes con la estructura de la BD.
class DbLoader {
  final clienteDao = ClienteDao();
  final equipoDao = EquipoDao();
  final ingresoDao = IngresoDAO();
  final diagnosticoDao = DiagnosticoDao();
  final presupuestoDao = PresupuestoDao();
  final repuestoDao = RepuestoDao();
  final entregaDao = EntregaDao();

  Future<void> cargarDatosDemo() async {
    debugPrint('🚀 Iniciando carga de datos demo Gontech Flow v3...');

    // === 1️⃣ CLIENTES ===
    final clientes = [
      Cliente(
        nombre: 'Gonzalo Castillo De La Fuente',
        telefono: '96122622',
        correo: 'g.castillo@gontech.cl',
        direccion: 'Antofagasta Centro',
        notas: 'Cliente principal, tester y soporte TI.',
      ),
      Cliente(
        nombre: 'Michelle De La Fuente',
        telefono: '99887766',
        correo: 'michelle@gontech.cl',
        direccion: 'Antofagasta Sur',
        notas: 'Área comercial y ventas.',
      ),
    ];

    final idClientes = <int>[];
    for (final c in clientes) {
      final id = await clienteDao.insertar(c);
      idClientes.add(id);
    }
    debugPrint('👥 Clientes cargados OK: $idClientes');

    // === 2️⃣ EQUIPOS ===
    final equipos = [
      Equipo(
        id_cliente: idClientes[0],
        tipo_equipo: 'Notebook',
        marca: 'Acer',
        modelo: 'Aspire 5',
        numero_serie: 'ACR2024A5',
        descripcion: 'Notebook personal de Gonzalo para desarrollo técnico',
      ),
      Equipo(
        id_cliente: idClientes[1],
        tipo_equipo: 'All-in-One',
        marca: 'HP',
        modelo: 'Pavilion 24',
        numero_serie: 'HP24MICH',
        descripcion: 'Equipo de oficina para área comercial',
      ),
    ];

    final idEquipos = <int>[];
    for (final e in equipos) {
      final id = await equipoDao.insertar(e);
      idEquipos.add(id);
    }
    debugPrint('💻 Equipos cargados: $idEquipos');

    // === 🧾 INGRESOS (ahora con QR) ===
    final fecha1 = DateTime.now().toIso8601String();
    final fecha2 = DateTime.now()
        .subtract(const Duration(days: 2))
        .toIso8601String();

    final ingresos = [
      Ingreso(
        id_equipo: idEquipos[0],
        fecha_ingreso: fecha1,
        accesorios: 'Cargador original, mochila negra',
        observaciones: 'Pantalla con líneas verticales',
        estado_ingreso: 'pendiente',
        qr_code: 'EQUIPO-${idEquipos[0]}-$fecha1', // 👈 QR generado
      ),
      Ingreso(
        id_equipo: idEquipos[1],
        fecha_ingreso: fecha2,
        accesorios: 'Teclado y mouse inalámbrico',
        observaciones: 'Sistema lento al iniciar',
        estado_ingreso: 'pendiente',
        qr_code: 'EQUIPO-${idEquipos[1]}-$fecha2', // 👈 QR generado
      ),
    ];

    final idIngresos = <int>[];
    for (final i in ingresos) {
      final id = await ingresoDao.insertar(i);
      idIngresos.add(id);
    }
    debugPrint('📦 Ingresos cargados OK: $idIngresos');

    // === 🧪 DIAGNÓSTICOS ===
    final diagnosticos = [
      Diagnostico(
        id_ingreso: idIngresos[0],
        id_tecnico: 1,
        descripcion_falla: 'Pantalla trizada y sin imagen',
        pruebas_realizadas: 'Prueba GPU, voltaje LVDS, reemplazo panel test',
        conclusiones: 'Se confirma falla de pantalla LED, requiere cambio',
        estado: 'en_revision',
      ),
      Diagnostico(
        id_ingreso: idIngresos[1],
        id_tecnico: 1,
        descripcion_falla: 'Sistema extremadamente lento',
        pruebas_realizadas: 'SMART test, benchmark SSD',
        conclusiones: 'HDD con sectores dañados, reemplazo por SSD 480GB',
        estado: 'diagnosticado',
      ),
    ];

    final idDiagnosticos = <int>[];
    for (final d in diagnosticos) {
      final id = await diagnosticoDao.insertar(d);
      idDiagnosticos.add(id);
    }
    debugPrint('🧪 Diagnósticos cargados OK: $idDiagnosticos');

    // === 💰 PRESUPUESTOS ===
    final presupuestos = [
      Presupuesto(
        idDiagnostico: idDiagnosticos[0],
        descripcion: 'Cambio pantalla LED + limpieza interna',
        total: 85000,
        estado: 'pendiente',
        fechaCreacion: DateTime.now().toIso8601String(),
      ),
      Presupuesto(
        idDiagnostico: idDiagnosticos[1],
        descripcion: 'Instalación SSD 480GB + clonación Windows 11',
        total: 70000,
        estado: 'pendiente',
        fechaCreacion: DateTime.now().toIso8601String(),
      ),
    ];

    final idPresupuestos = <int>[];
    for (final p in presupuestos) {
      final id = await presupuestoDao.insertar(p);
      idPresupuestos.add(id);
    }
    debugPrint('💰 Presupuestos cargados OK: $idPresupuestos');

    debugPrint('✅ Carga de datos completada correctamente.');
  }
}
