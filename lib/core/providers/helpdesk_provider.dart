import 'package:flutter/material.dart';
import 'package:gontech_flow_v2/core/models/diagnostico.dart';
import 'package:gontech_flow_v2/core/models/ingreso.dart';
import 'package:gontech_flow_v2/core/models/reparacion.dart';
import 'package:gontech_flow_v2/core/models/entrega.dart';
import '../config/api_config.dart';
import '../dao/cliente_dao.dart';
import '../dao/equipo_dao.dart';
import '../dao/ingreso_dao.dart';
import '../dao/diagnostico_dao.dart';
import '../dao/presupuesto_dao.dart';
import '../dao/reparacion_dao.dart';
import '../dao/repuesto_dao.dart';
import '../dao/entrega_dao.dart';
import '../dao/informe_dao.dart';
import '../services/remote_dashboard_service.dart';
import '../services/remote_cliente_service.dart';
import '../services/remote_equipo_service.dart';
import '../services/remote_ingreso_service.dart';
import '../services/remote_diagnostico_service.dart';
import '../services/remote_presupuesto_service.dart';
import '../services/remote_reparacion_service.dart';
import '../services/remote_repuesto_service.dart';
import '../services/remote_entrega_service.dart';
import '../services/remote_informe_service.dart';
import '../services/remote_ajuste_service.dart'; 
import '../services/remote_documento_service.dart'; // <-- Importación del gestor de archivos
import '../models/cliente.dart';

class HelpdeskProvider extends ChangeNotifier {
  final ClienteDao _clienteDao = ClienteDao();
  final EquipoDao _equipoDao = EquipoDao();
  final IngresoDAO _ingresoDao = IngresoDAO();
  final DiagnosticoDao _diagnosticoDao = DiagnosticoDao();
  final PresupuestoDao _presupuestoDao = PresupuestoDao();
  final ReparacionDao _reparacionDao = ReparacionDao();
  final RepuestoDao _repuestoDao = RepuestoDao();
  final EntregaDao _entregasDao = EntregaDao();
  final InformeDao _informeDao = InformeDao();
  
  final RemoteDashboardService _remoteDashboard = RemoteDashboardService();
  final RemoteClienteService _remoteCliente = RemoteClienteService();
  final RemoteEquipoService _remoteEquipo = RemoteEquipoService();
  final RemoteIngresoService _remoteIngreso = RemoteIngresoService();
  final RemoteDiagnosticoService _remoteDiagnostico = RemoteDiagnosticoService();
  final RemotePresupuestoService _remotePresupuesto = RemotePresupuestoService();
  final RemoteReparacionService _remoteReparacion = RemoteReparacionService();
  final RemoteRepuestoService _remoteRepuesto = RemoteRepuestoService(); 
  final RemoteEntregaService _remoteEntrega = RemoteEntregaService(); 
  final RemoteInformeService _remoteInforme = RemoteInformeService();
  final RemoteAjusteService _remoteAjuste = RemoteAjusteService(); 
  final RemoteDocumentoService _remoteDocumento = RemoteDocumentoService(); // <-- Instancia del servicio

  // Diccionario global de configuraciones (Key-Value)
  Map<String, dynamic> configuracion = {}; 

  Map<String, int> resumen = {
    'Clientes': 0, 'Equipos': 0, 'Ingresos': 0, 'Diagnósticos': 0, 'Presupuestos': 0, 'Reparaciones': 0,
  };

  List<Map<String, dynamic>> ultimosIngresos = [];
  bool _loading = false;
  bool get loading => _loading;

  List<Cliente> _clientes = [];
  List<Cliente> get clientes => _clientes;
  List<Map<String, dynamic>> _equipos = [];
  List<Map<String, dynamic>> get equipos => _equipos;
  List<Map<String, dynamic>> _ingresos = [];
  List<Map<String, dynamic>> get ingresos => _ingresos;
  List<Map<String, dynamic>> _diagnosticos = [];
  List<Map<String, dynamic>> get diagnosticos => _diagnosticos;
  List<Map<String, dynamic>> _presupuestos = [];
  List<Map<String, dynamic>> get presupuestos => _presupuestos;
  List<Map<String, dynamic>> _reparaciones = [];
  List<Map<String, dynamic>> get reparaciones => _reparaciones;
  List<Map<String, dynamic>> _repuestos = []; 
  List<Map<String, dynamic>> get repuestos => _repuestos;
  List<Map<String, dynamic>> _entregas = []; 
  List<Map<String, dynamic>> get entregas => _entregas;
  List<Map<String, dynamic>> _informes = [];
  List<Map<String, dynamic>> get informes => _informes;
  List<Map<String, dynamic>> _documentos = []; // <-- Lista global de documentos
  List<Map<String, dynamic>> get documentos => _documentos;

  // --- Estadísticas requeridas por estadisticas_screen ---
  int get reparacionesEnProceso => _reparaciones.where((r) => r['estado'] == 'en_proceso').length;
  int get reparacionesFinalizadas => _reparaciones.where((r) => r['estado'] == 'finalizada').length;
  int get presupuestosPendientes => _presupuestos.where((p) => p['estado'] == 'pendiente').length;
  int get presupuestosAutorizados => _presupuestos.where((p) => p['estado'] == 'autorizado').length;
  int get entregasPendientes => _entregas.where((e) => e['estado'] == 'pendiente' || e['estado'] == 'pendiente_pdf').length;
  int get entregasCompletadas => _entregas.where((e) => e['estado'] == 'entregado').length;

  // --- Dashboard ---
  Future<void> cargarDashboard() async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final data = await _remoteDashboard.fetchDashboard();
        final res = (data['resumen'] as Map<String, dynamic>? ?? {});
        resumen = {
          'Clientes': (res['clientes'] ?? 0) as int,
          'Equipos': (res['equipos'] ?? 0) as int,
          'Ingresos': (res['ingresos'] ?? 0) as int,
          'Diagnósticos': (res['diagnosticos'] ?? 0) as int,
          'Presupuestos': (res['presupuestos'] ?? 0) as int,
          'Reparaciones': (res['reparaciones'] ?? 0) as int,
        };
        ultimosIngresos = (data['ultimos_ingresos'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        await recargarTodo();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- GESTIÓN DE AJUSTES GLOBALES ---
  Future<bool> guardarAjustesGlobales(List<Map<String, dynamic>> listaAjustes) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final exito = await _remoteAjuste.actualizarAjustesEnMasa(listaAjustes);
        if (exito) {
          await recargarAjustes();
          return true;
        }
        return false;
      }
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarAjustes() async {
    if (await ApiConfig.useApiMode()) {
      try {
        configuracion = await _remoteAjuste.obtenerAjustes();
      } catch (e) {
        print('Error recargando ajustes desde API: $e');
      }
    }
    notifyListeners();
  }

  // --- GESTIÓN DE DOCUMENTOS POLIMÓRFICOS ---
  Future<bool> asociarDocumentoAEntidad({
    required String tipo,
    required int id,
    required String rutaLocal,
    String? nombrePersonalizado,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteDocumento.subirDocumento(
          entidadTipo: tipo,
          entidadId: id,
          filePath: rutaLocal,
          nombreArchivo: nombrePersonalizado,
        );
        if (res != null) {
          await recargarDocumentos();
          return true;
        }
        return false;
      }
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> borrarDocumento(int id) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final exito = await _remoteDocumento.eliminarDocumento(id);
        if (exito) {
          await recargarDocumentos();
        }
        return exito;
      }
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarDocumentos({String? tipo, int? id}) async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteDocumento.obtenerDocumentos(tipo: tipo, id: id);
        _documentos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando documentos desde API: $e');
      }
    }
    notifyListeners();
  }

  // --- CRUD CLIENTES ---
  Future<bool> agregarCliente(Cliente c) async {
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteCliente.crearCliente(c.toMap());
        if (res != null) { await recargarClientes(); return true; }
        return false;
      }
      return await _clienteDao.insertar(c) > 0;
    } finally { recargarClientes(); notifyListeners(); }
  }

  Future<bool> eliminarCliente(int id) async {
    try {
      if (await ApiConfig.useApiMode()) {
        return await _remoteCliente.eliminarCliente(id);
      }
      return await _clienteDao.eliminar(id) > 0;
    } finally { recargarClientes(); notifyListeners(); }
  }

  Future<void> recargarClientes() async {
    if (await ApiConfig.useApiMode()) {
      final data = await _remoteCliente.obtenerClientes();
      _clientes = data.map((json) => Cliente.fromMap(json)).toList();
    } else {
      _clientes = await _clienteDao.listar();
    }
    resumen['Clientes'] = _clientes.length;
    notifyListeners();
  }

  // --- CRUD EQUIPOS ---
  Future<bool> agregarEquipo(Map<String, dynamic> data) async {
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteEquipo.crearEquipo(data);
        if (res != null) { await recargarEquipos(); return true; }
        return false;
      }
      return false;
    } finally { recargarEquipos(); notifyListeners(); }
  }

  Future<bool> actualizarEquipo(int id, Map<String, dynamic> data) async {
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteEquipo.actualizarEquipo(id, data);
        if (res != null) { await recargarEquipos(); return true; }
        return false;
      }
      return false;
    } finally { recargarEquipos(); notifyListeners(); }
  }

  Future<void> recargarEquipos() async {
    if (await ApiConfig.useApiMode()) {
      final data = await _remoteEquipo.obtenerEquipos();
      _equipos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _equipos = await _equipoDao.listarDetallado();
    }
    resumen['Equipos'] = _equipos.length;
    notifyListeners();
  }

// --- CRUD INGRESOS ---
  Future<bool> agregarIngreso(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteIngreso.crearIngreso(data);
        if (res != null) { 
          await recargarIngresos(); 
          return true; 
        }
        return false;
      }
      // Modo Local histórico
      final id = await _ingresoDao.insertar(data as Ingreso);
      if (id > 0) {
        await recargarIngresos();
        return true;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners(); // Sincroniza el estado de carga una sola vez al terminar todo
    }
  }

  Future<void> recargarIngresos() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteIngreso.obtenerIngresos();
        // Mapeo seguro tolerante a estructuras complejas u objetos relacionales de Laravel
        _ingresos = data.map((e) {
          return Map<String, dynamic>.from(e as Map);
        }).toList();
      } catch (e) {
        print('❌ Error recargando ingresos desde API: $e');
      }
    } else {
      _ingresos = await _ingresoDao.listarIngresosDetallados();
    }
    
    // Parametrización de totales para contadores y Dashboard
    resumen['Ingresos'] = _ingresos.length;
    ultimosIngresos = _ingresos.take(5).toList();
    notifyListeners();
  }

  // --- CRUD DIAGNÓSTICOS ---
  Future<bool> agregarDiagnostico(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteDiagnostico.crearDiagnostico(data);
        if (res != null) { await recargarDiagnosticos(); return true; }
        return false;
      }
      final id = await _diagnosticoDao.insertar(data as Diagnostico);
      if (id > 0) { await recargarDiagnosticos(); return true; }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarDiagnosticos() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteDiagnostico.obtenerDiagnosticos();
        _diagnosticos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando diagnósticos desde API: $e');
      }
    } else {
      _diagnosticos = await _diagnosticoDao.listarDetallado();
    }
    resumen['Diagnósticos'] = _diagnosticos.length;
    notifyListeners();
  }

  // --- CRUD PRESUPUESTOS ---
  Future<bool> agregarPresupuesto(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remotePresupuesto.crearPresupuesto(data);
        if (res != null) { 
          await recargarPresupuestos(); 
          return true; 
        }
        return false;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  // --- ACTUALIZAR PRESUPUESTO ---
  Future<bool> actualizarPresupuesto(int id, Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    
    try {
      if (await ApiConfig.useApiMode()) {
        // Modo Laravel API
        final res = await _remotePresupuesto.actualizarPresupuesto(id, data);
        if (res != null) {
          await recargarPresupuestos();
          return true;
        }
        return false;
      } else {
        // Modo SQLite Local (Fallback)
        // El DAO de presupuestos expone actualizarEstado similar a otras entidades
        await _presupuestoDao.actualizarEstado(id, data['estado'] ?? 'pendiente');
        await recargarPresupuestos();
        return true;
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarPresupuestos() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remotePresupuesto.obtenerPresupuestos();
        _presupuestos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando presupuestos desde API: $e');
      }
    } else {
      _presupuestos = await _presupuestoDao.listarDetallado();
    }
    resumen['Presupuestos'] = _presupuestos.length;
    notifyListeners();
  }
  

// --- CRUD REPARACIONES ---
  Future<bool> agregarReparacion(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteReparacion.crearReparacion(data);
        if (res != null) { 
          await recargarReparaciones(); 
          return true; 
        }
        return false;
      }
      // Fallback local SQLite
      final id = await _reparacionDao.insertar(data as Reparacion);
      if (id > 0) { 
        await recargarReparaciones(); 
        return true; 
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarReparacion(int id, Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteReparacion.actualizarReparacion(id, data);
        if (res != null) { 
          await recargarReparaciones(); 
          return true; 
        }
        return false;
      }
      // Fallback local SQLite
      if (data.containsKey('estado')) {
        await _reparacionDao.actualizarEstado(id, data['estado']);
      }
      await recargarReparaciones();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 🚀 NUEVO: Método para eliminar reparaciones
  Future<bool> eliminarReparacion(int id) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final exito = await _remoteReparacion.eliminarReparacion(id);
        if (exito) {
          await recargarReparaciones();
          return true;
        }
        return false;
      }
      // Fallback local SQLite
      await _reparacionDao.eliminar(id);
      await recargarReparaciones();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarReparaciones() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteReparacion.obtenerReparaciones();
        _reparaciones = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando reparaciones desde API: $e');
      }
    } else {
      _reparaciones = await _reparacionDao.listarDetallado();
    }
    
    // Actualizamos las métricas del dashboard si existe el mapa resumen
    resumen['Reparaciones'] = _reparaciones.length;
    notifyListeners();
  }

// --- CRUD REPUESTOS ---
  Future<bool> agregarRepuesto(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteRepuesto.crearRepuesto(data);
        if (res != null) { 
          await recargarRepuestos(); 
          return true; 
        }
        return false;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 🚀 REEMPLAZAMOS cambiarEstadoRepuesto POR actualizarRepuesto
  Future<bool> actualizarRepuesto(int id, Map<String, dynamic> data) async {
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteRepuesto.actualizarRepuesto(id, data);
        if (res != null) { 
          await recargarRepuestos(); 
          return true; 
        }
        return false;
      }
      // Fallback a local si sigues usando SQLite de respaldo
      if (data.containsKey('estado')) {
        await _repuestoDao.actualizarEstado(id, data['estado']);
      }
      await recargarRepuestos();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 🚀 NUEVO: Método para eliminar insumos
  Future<bool> eliminarRepuesto(int id) async {
    try {
      if (await ApiConfig.useApiMode()) {
        // Asegúrate de tener este método en tu _remoteRepuesto (RemoteRepuestoService)
        final exito = await _remoteRepuesto.eliminarRepuesto(id);
        if (exito) {
          await recargarRepuestos();
          return true;
        }
        return false;
      }
      // Fallback a local
      await _repuestoDao.eliminar(id);
      await recargarRepuestos();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> recargarRepuestos() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteRepuesto.obtenerRepuestos();
        _repuestos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando repuestos desde API: $e');
      }
    } else {
      _repuestos = await _repuestoDao.listarDetallado();
    }
    notifyListeners();
  }

// --- CRUD ENTREGAS ---
  
  Future<bool> procesarEntrega(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteEntrega.crearEntrega(data);
        if (res != null) { 
          await recargarEntregas(); 
          return true; 
        }
        return false;
      }
      // Fallback local SQLite (Asegurando que no crashee el casteo)
      // Asume que tienes un factory fromMap en tu clase Entrega si usas SQLite
      final id = await _entregasDao.insertar(data as dynamic); 
      if (id > 0) { 
        await recargarEntregas(); 
        return true; 
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarEntrega(int id, Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteEntrega.actualizarEntrega(id, data);
        if (res != null) { 
          await recargarEntregas(); 
          return true; 
        }
        return false;
      }
      // Fallback local SQLite
      if (data.containsKey('estado')) {
        await _entregasDao.actualizarEstado(id, data['estado']);
      }
      await recargarEntregas();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 🚀 NUEVO: Eliminar entrega
  Future<bool> eliminarEntrega(int id) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final exito = await _remoteEntrega.eliminarEntrega(id);
        if (exito) {
          await recargarEntregas();
          return true;
        }
        return false;
      }
      // Fallback local SQLite
      await _entregasDao.eliminar(id);
      await recargarEntregas();
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarEntregas() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteEntrega.obtenerEntregas();
        _entregas = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando entregas desde API: $e');
      }
    } else {
      _entregas = await _entregasDao.listarDetallado();
    }
    
    // Opcional: Actualizamos las métricas del dashboard si existe el mapa resumen
    resumen['Entregas'] = _entregas.length; 
    notifyListeners();
  }

  // --- CRUD INFORMES ---
  Future<bool> agregarInforme(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteInforme.crearInforme(data);
        if (res != null) { 
          await recargarInformes(); 
          return true; 
        }
        return false;
      }
      return false;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarInforme(int id, Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteInforme.actualizarInforme(id, data);
        if (res != null) { 
          await recargarInformes(); 
          return true; 
        }
        return false;
      }
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recargarInformes() async {
    if (await ApiConfig.useApiMode()) {
      try {
        final data = await _remoteInforme.obtenerInformes();
        _informes = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error recargando informes desde API: $e');
      }
    } else {
      _informes = await _informeDao.listarDetallado();
    }
    notifyListeners();
  }

  // --- RECARGA MAESTRA ---
  Future<void> recargarTodo() async {
    await recargarAjustes();
    await recargarClientes();
    await recargarEquipos();
    await recargarIngresos();
    await recargarDiagnosticos();
    await recargarPresupuestos();
    await recargarReparaciones();
    await recargarRepuestos();
    await recargarEntregas(); 
    await recargarInformes();
    await recargarDocumentos(); // <-- Sincronizado en el arranque
  }
}