import 'package:flutter/material.dart';
import 'package:gontech_flow_v2/core/models/diagnostico.dart';
import 'package:gontech_flow_v2/core/models/ingreso.dart';
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
import '../services/remote_diagnostico_service.dart'; // <-- Importación del nuevo servicio remotos
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
  final RemoteDiagnosticoService _remoteDiagnostico = RemoteDiagnosticoService(); // <-- Instancia del servicio

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
  List<Map<String, dynamic>> _entregas = [];
  List<Map<String, dynamic>> get entregas => _entregas;
  List<Map<String, dynamic>> _informes = [];
  List<Map<String, dynamic>> get informes => _informes;

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
    try {
      if (await ApiConfig.useApiMode()) {
        final res = await _remoteIngreso.crearIngreso(data);
        if (res != null) { await recargarIngresos(); return true; }
        return false;
      }
      return await _ingresoDao.insertar(data as Ingreso) > 0;
    } finally { recargarIngresos(); notifyListeners(); }
  }

  Future<void> recargarIngresos() async {
    if (await ApiConfig.useApiMode()) {
      final data = await _remoteIngreso.obtenerIngresos();
      _ingresos = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _ingresos = await _ingresoDao.listarIngresosDetallados();
    }
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

  // --- MÉTODOS DE RECARGA RESTANTES ---
  Future<void> recargarPresupuestos() async {
    _presupuestos = await _presupuestoDao.listarDetallado();
    resumen['Presupuestos'] = _presupuestos.length;
    notifyListeners();
  }

  Future<void> recargarReparaciones() async {
    _reparaciones = await _reparacionDao.listarDetallado();
    resumen['Reparaciones'] = _reparaciones.length;
    notifyListeners();
  }

  Future<void> recargarEntregas() async {
    _entregas = await _entregasDao.listarDetallado();
    notifyListeners();
  }

  Future<void> recargarInformes() async {
    _informes = await _informeDao.listarDetallado();
    notifyListeners();
  }

  Future<void> recargarTodo() async {
    await recargarClientes();
    await recargarEquipos();
    await recargarIngresos();
    await recargarDiagnosticos();
    await recargarPresupuestos();
    await recargarReparaciones();
    await recargarEntregas();
    await recargarInformes();
  }
}