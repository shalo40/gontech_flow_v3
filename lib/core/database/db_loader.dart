import 'package:flutter/foundation.dart';
import 'package:gontech_flow_v2/core/database/database_helper.dart';
import '../dao/cliente_dao.dart';
import '../dao/equipo_dao.dart';
import '../dao/ingreso_dao.dart';
import '../dao/diagnostico_dao.dart';
import '../dao/presupuesto_dao.dart';
import '../dao/reparacion_dao.dart';
import '../dao/repuesto_dao.dart';
import '../dao/entrega_dao.dart';

import '../models/cliente.dart';
import '../models/equipo.dart';
import '../models/ingreso.dart';
import '../models/diagnostico.dart';
import '../models/presupuesto.dart';
import '../models/reparacion.dart';
import '../models/repuesto.dart';
import '../models/entrega.dart';

/// 🚀 Cargador de datos de demostración Gontech Flow v3.
class DbLoader {
  final clienteDao = ClienteDao();
  final equipoDao = EquipoDao();
  final ingresoDao = IngresoDAO();
  final diagnosticoDao = DiagnosticoDao();
  final presupuestoDao = PresupuestoDao();
  final reparacionDao = ReparacionDao();
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
        rut: '12.345.678-9',
      ),
      Cliente(
        nombre: 'Michelle De La Fuente',
        telefono: '99887766',
        correo: 'michelle@gontech.cl',
        direccion: 'Antofagasta Sur',
        notas: 'Área comercial y ventas.',
        rut: '12.345.678-9',
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

    // === 3️⃣ INGRESOS ===
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
        qr_code: 'EQUIPO-${idEquipos[0]}-$fecha1',
      ),
      Ingreso(
        id_equipo: idEquipos[1],
        fecha_ingreso: fecha2,
        accesorios: 'Teclado y mouse inalámbrico',
        observaciones: 'Sistema lento al iniciar',
        estado_ingreso: 'pendiente',
        qr_code: 'EQUIPO-${idEquipos[1]}-$fecha2',
      ),
    ];

    final idIngresos = <int>[];
    for (final i in ingresos) {
      final id = await ingresoDao.insertar(i);
      idIngresos.add(id);
    }

    debugPrint('📦 Ingresos cargados OK: $idIngresos');

    // === 4️⃣ DIAGNÓSTICOS ===
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

    // === 5️⃣ PRESUPUESTOS ===
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

    // === 6️⃣ REPARACIONES ===
    final reparaciones = [
      Reparacion(
        idDiagnostico: idDiagnosticos[0],
        idTecnico: 1,
        descripcion: 'Cambio de pantalla LED y limpieza interna completa',
        fechaInicio: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        fechaFin: null,
        estado: 'en_proceso',
        notas: 'Esperando repuesto pantalla LED 15.6"',
      ),
      Reparacion(
        idDiagnostico: idDiagnosticos[1],
        idTecnico: 1,
        descripcion: 'Instalación SSD y migración de datos',
        fechaInicio: DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        fechaFin: DateTime.now().toIso8601String(),
        estado: 'finalizada',
        notas: 'Equipo entregado con respaldo completo en carpeta D:',
      ),
    ];

    final idReparaciones = <int>[];
    for (final r in reparaciones) {
      final id = await reparacionDao.insertar(r);
      idReparaciones.add(id);
    }

    debugPrint('🔧 Reparaciones cargadas OK: $idReparaciones');

    // === 7️⃣ REPUESTOS ===
    final repuestos = [
      Repuesto(
        idPresupuesto: idPresupuestos[0],
        nombre: 'Pantalla LED 15.6"',
        cantidad: 1,
        costoUnitario: 55000,
        proveedor: 'TecnoParts Chile',
        estado: 'sugerido',
        origen: 'diagnostico',
      ),
      Repuesto(
        idPresupuesto: idPresupuestos[1],
        nombre: 'SSD 480GB Kingston',
        cantidad: 1,
        costoUnitario: 30000,
        proveedor: 'SPDigital',
        estado: 'instalado',
        origen: 'reparacion',
      ),
    ];

    for (final r in repuestos) {
      await repuestoDao.insertar(r);
    }

    debugPrint('🧩 Repuestos cargados OK (${repuestos.length})');

    // === 8️⃣ ENTREGAS ===
    final entregas = [
      Entrega(
        id_reparacion: idReparaciones[1],
        fecha_entrega: DateTime.now().toIso8601String(),
        observaciones: 'Cliente satisfecha con el rendimiento del SSD.',
        firmaCliente: '', // base64 o firma en blanco por ahora
        estado: 'entregado',
        nombre_receptor: 'Michelle De La Fuente',
        rut_receptor: '17.777.777-7',
        firma_path: '',
      ),
      Entrega(
        id_reparacion: idReparaciones[0],
        fecha_entrega: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        observaciones: 'Revisión pendiente de pago, cliente aún no retira.',
        firmaCliente: '',
        estado: 'pendiente_pdf',
        nombre_receptor: 'Gonzalo Castillo De La Fuente',
        rut_receptor: '16.666.666-6',
        firma_path: '',
      ),
    ];

    for (final e in entregas) {
      await entregaDao.insertar(e);
    }

    debugPrint('📦 Entregas cargadas OK (${entregas.length})');
    debugPrint('✅ Carga de datos demo completada con éxito.');

    // === 👤 USUARIOS DEMO ===
    final db = await DatabaseHelper().db;
    await db.insert('usuarios', {
      'nombre': 'Administrador Gontech',
      'correo': 'admin@gontech.cl',
      'contrasena': '1234',
      'rol': 'admin',
    });

    await db.insert('usuarios', {
      'nombre': 'Técnico Demo',
      'correo': 'tecnico@gontech.cl',
      'contrasena': '1234',
      'rol': 'tecnico',
    });

    await db.insert('usuarios', {
      'nombre': 'Cliente Demo',
      'correo': 'cliente@gontech.cl',
      'contrasena': '1234',
      'rol': 'cliente',
    });

    debugPrint('👤 Usuarios demo cargados (3 cuentas)');
  }
}
