import 'package:flutter/material.dart';
import '../dao/cliente_dao.dart';
import '../dao/equipo_dao.dart';
import '../dao/ingreso_dao.dart';
import '../dao/diagnostico_dao.dart';
import '../dao/presupuesto_dao.dart';
import '../dao/reparacion_dao.dart';
import '../dao/repuesto_dao.dart';
import '../dao/entrega_dao.dart';
import '../dao/informe_dao.dart';
import '../models/cliente.dart';

class HelpdeskProvider extends ChangeNotifier {
  final ClienteDao _clienteDao = ClienteDao();
  final EquipoDao _equipoDao = EquipoDao();
  final IngresoDAO _ingresoDao = IngresoDAO();
  final DiagnosticoDao _diagnosticoDao = DiagnosticoDao();
  final PresupuestoDao _presupuestoDao = PresupuestoDao();
  final ReparacionDao _reparacionDao = ReparacionDao();
  final RepuestoDao _repuestoDao = RepuestoDao();
  final EntregaDao _entregaDao = EntregaDao();
  final InformeDao _informeDao = InformeDao();

  // --- Estado del dashboard ---
  Map<String, int> resumen = {
    'Clientes': 0,
    'Equipos': 0,
    'Ingresos': 0,
    'Diagnósticos': 0,
    'Presupuestos': 0,
    'Reparaciones': 0,
  };

  List<Map<String, dynamic>> ultimosIngresos = [];
  bool _loading = false;
  bool get loading => _loading;

  // --- Datos cacheados por módulo ---
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

  // --- Estadísticas adicionales ---
  int get reparacionesEnProceso =>
      _reparaciones.where((r) => r['estado'] == 'en_proceso').length;
  int get reparacionesFinalizadas =>
      _reparaciones.where((r) => r['estado'] == 'finalizada').length;
  int get presupuestosPendientes =>
      _presupuestos.where((p) => p['estado'] == 'pendiente').length;
  int get presupuestosAutorizados =>
      _presupuestos.where((p) => p['estado'] == 'autorizado').length;
  int get entregasPendientes =>
      _entregas.where((e) => e['estado'] == 'pendiente' || e['estado'] == 'pendiente_pdf').length;
  int get entregasCompletadas =>
      _entregas.where((e) => e['estado'] == 'entregado').length;

  double get ingresosTotalesPresupuestos {
    double total = 0;
    for (final p in _presupuestos) {
      if (p['estado'] == 'autorizado') {
        total += (p['total'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  Future<void> cargarDashboard() async {
    _loading = true;
    notifyListeners();

    try {
      _clientes = await _clienteDao.listar();
      _equipos = await _equipoDao.listarDetallado();
      _ingresos = await _ingresoDao.listarIngresosDetallados();
      _diagnosticos = await _diagnosticoDao.listarDetallado();
      _presupuestos = await _presupuestoDao.listarDetallado();
      _reparaciones = await _reparacionDao.listarDetallado();

      resumen = {
        'Clientes': _clientes.length,
        'Equipos': _equipos.length,
        'Ingresos': _ingresos.length,
        'Diagnósticos': _diagnosticos.length,
        'Presupuestos': _presupuestos.length,
        'Reparaciones': _reparaciones.length,
      };
      ultimosIngresos = _ingresos.take(5).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Recarga individual por módulo ---
  Future<void> recargarClientes() async {
    _clientes = await _clienteDao.listar();
    resumen['Clientes'] = _clientes.length;
    notifyListeners();
  }

  Future<void> recargarEquipos() async {
    _equipos = await _equipoDao.listarDetallado();
    resumen['Equipos'] = _equipos.length;
    notifyListeners();
  }

  Future<void> recargarIngresos() async {
    _ingresos = await _ingresoDao.listarIngresosDetallados();
    resumen['Ingresos'] = _ingresos.length;
    ultimosIngresos = _ingresos.take(5).toList();
    notifyListeners();
  }

  Future<void> recargarDiagnosticos() async {
    _diagnosticos = await _diagnosticoDao.listarDetallado();
    resumen['Diagnósticos'] = _diagnosticos.length;
    notifyListeners();
  }

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

  Future<void> recargarRepuestos() async {
    _repuestos = await _repuestoDao.listarDetallado();
    notifyListeners();
  }

  Future<void> recargarEntregas() async {
    _entregas = await _entregaDao.listarDetallado();
    notifyListeners();
  }

  Future<void> recargarInformes() async {
    _informes = await _informeDao.listarDetallado();
    notifyListeners();
  }

  Future<void> recargarTodo() async {
    await cargarDashboard();
    await recargarRepuestos();
    await recargarEntregas();
    await recargarInformes();
  }
}
