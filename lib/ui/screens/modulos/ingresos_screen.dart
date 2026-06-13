import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'diagnostico_modal.dart';
import 'package:intl/intl.dart';

class IngresosScreen extends StatefulWidget {
  const IngresosScreen({super.key});

  @override
  State<IngresosScreen> createState() => _IngresosScreenState();
}

class _IngresosScreenState extends State<IngresosScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarIngresos();
  }

  // --- Helpers de Extracción Segura ---
  int _getId(Map<String, dynamic> i) => int.tryParse((i['id_ingreso'] ?? i['id'] ?? '0').toString()) ?? 0;

  String _getCliente(Map<String, dynamic> i) {
    if (i['nombre_cliente'] != null) return i['nombre_cliente'].toString();
    if (i['equipo'] != null && i['equipo']['cliente'] != null) {
      return i['equipo']['cliente']['nombre'] ?? 'Sin cliente';
    }
    return 'Sin cliente';
  }

  String _getEquipoTexto(Map<String, dynamic> i) {
    String tipo = 'Equipo';
    String marca = '';
    String modelo = '';

    if (i['equipo'] != null) {
      tipo = i['equipo']['tipo_equipo'] ?? tipo;
      marca = i['equipo']['marca'] ?? '';
      modelo = i['equipo']['modelo'] ?? '';
    } else {
      tipo = i['tipo_equipo'] ?? tipo;
      marca = i['marca'] ?? '';
      modelo = i['modelo'] ?? '';
    }
    return '$tipo • $marca $modelo'.trim();
  }

  String _getEstado(Map<String, dynamic> i) => i['estado'] ?? i['estado_ingreso'] ?? 'ingresado';
  String _getAccesorios(Map<String, dynamic> i) => i['accesorios_entregados'] ?? i['accesorios'] ?? 'Sin accesorios';
  
  String _getFotoPath(Map<String, dynamic> i) {
    if (i['equipo'] != null && i['equipo']['foto_path'] != null) {
      return i['equipo']['foto_path'].toString();
    }
    return i['foto_path']?.toString() ?? '';
  }

  // --- Helpers UI ---
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente': // <--- CORREGIDO
      case 'ingresado':
      case 'pendiente_diagnostico': return Colors.orangeAccent;
      case 'pendiente_aprobacion': return Colors.amber;
      case 'en_reparacion': return Colors.blueAccent;
      case 'finalizado': return Colors.green;
      case 'archivado': return Colors.grey;
      default: return Colors.white70;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'pendiente': // <--- CORREGIDO
      case 'ingresado':
      case 'pendiente_diagnostico': return 'Sin diagnóstico';
      case 'pendiente_aprobacion': return 'Falta aprobación';
      case 'en_reparacion': return 'En reparación';
      case 'finalizado': return 'Finalizado';
      case 'archivado': return 'Archivado';
      default: return 'Desconocido';
    }
  }

  // ⏱️ Lógica del Semáforo de Estadía
  Widget _badgeEstadia(DateTime fechaIngreso) {
    final dias = DateTime.now().difference(fechaIngreso).inDays;
    Color colorFondo;
    String texto;

    if (dias == 0) {
      colorFondo = Colors.green.withOpacity(0.2);
      texto = 'Entró hoy';
    } else if (dias <= 3) {
      colorFondo = Colors.orangeAccent.withOpacity(0.2);
      texto = 'Hace $dias días';
    } else {
      colorFondo = Colors.redAccent.withOpacity(0.2);
      texto = 'Hace $dias días ⚠️';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorFondo.withOpacity(0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: dias >= 4 ? Colors.redAccent : (dias == 0 ? Colors.green : Colors.orangeAccent),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingresos = context.watch<HelpdeskProvider>().ingresos;
    final isLoading = context.watch<HelpdeskProvider>().loading;

    // Métricas rápidas
    final hoy = DateTime.now();
    int entraronHoy = 0;
    int pendientesGlobales = 0;

    final ingresosFiltrados = ingresos.where((i) {
      // Calculamos métricas en la misma pasada
      if (i['fecha_ingreso'] != null) {
        final f = DateTime.parse(i['fecha_ingreso']);
        if (f.year == hoy.year && f.month == hoy.month && f.day == hoy.day) entraronHoy++;
      }
      final est = _getEstado(i);
      if (est == 'pendiente_diagnostico' || est == 'ingresado' || est == 'pendiente') pendientesGlobales++;

      // Filtro de búsqueda
      final texto = _filtro.toLowerCase();
      return _getCliente(i).toLowerCase().contains(texto) || _getEquipoTexto(i).toLowerCase().contains(texto);
    }).toList();

    return LayoutPrincipal(
      titulo: 'Ingresos Técnicos',
      child: Column(
        children: [
          // 📊 1. DASHBOARD DE CABECERA (Métricas Rápidas)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _MiniCardMetrica(
                    titulo: 'Entraron Hoy',
                    valor: entraronHoy.toString(),
                    color: Colors.greenAccent,
                    icono: Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniCardMetrica(
                    titulo: 'Sin Diagnosticar',
                    valor: pendientesGlobales.toString(),
                    color: Colors.orangeAccent,
                    icono: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 2. BUSCADOR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o equipo...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (valor) => setState(() => _filtro = valor),
            ),
          ),

          // 📋 3. LISTA OPTIMIZADA DE INGRESOS
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: Colors.tealAccent,
              backgroundColor: AppColors.fondo,
              child: isLoading && ingresos.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                  : ingresosFiltrados.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('No hay ingresos registrados', style: TextStyle(color: Colors.white54))),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: ingresosFiltrados.length,
                          itemBuilder: (context, index) {
                            final i = ingresosFiltrados[index];
                            final estado = _getEstado(i);
                            final clienteName = _getCliente(i);
                            final equipoDesc = _getEquipoTexto(i);
                            final pathFoto = _getFotoPath(i);
                            final idIngreso = _getId(i);

                            final fechaRaw = i['fecha_ingreso'] != null ? DateTime.parse(i['fecha_ingreso']) : null;
                            final fechaFormateada = fechaRaw != null ? DateFormat('dd/MM/yyyy HH:mm').format(fechaRaw) : 'Sin fecha';

                            return Card(
                              color: AppColors.fondo.withOpacity(0.8),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _mostrarDetalles(context, i),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // --- Fila Superior: Avatar, Titulo y Tiempo ---
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.tealAccent.withOpacity(0.1),
                                            backgroundImage: (pathFoto.isNotEmpty && File(pathFoto).existsSync())
                                                ? FileImage(File(pathFoto))
                                                : null,
                                            child: pathFoto.isEmpty || !File(pathFoto).existsSync()
                                                ? const Icon(Icons.devices, color: Colors.tealAccent, size: 20)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  equipoDesc,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  clienteName,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (fechaRaw != null) _badgeEstadia(fechaRaw), // ⏱️ Semáforo
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // --- Fila Medio: Motivo resumido ---
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          i['observaciones'] ?? 'Sin motivo registrado',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // --- Fila Inferior: Estado y Acciones Rápidas ---
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Chip(
                                            label: Text(
                                              _textoEstado(estado),
                                              style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: _colorEstado(estado),
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                          ),
                                          // 🚀 Acción Rápida (CORREGIDO EL IF)
                                          if (estado == 'pendiente_diagnostico' || estado == 'ingresado' || estado == 'pendiente')
                                            TextButton.icon(
                                              onPressed: () async {
                                                await mostrarDiagnosticoModal(context, idIngreso);
                                                _cargar();
                                              },
                                              icon: const Icon(Icons.add_task, color: Colors.tealAccent, size: 18),
                                              label: const Text('Diagnosticar', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.tealAccent.withOpacity(0.1),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                minimumSize: const Size(0, 32),
                                              ),
                                            )
                                          else
                                            Text(fechaFormateada, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧭 Modal de detalle interno
  Future<void> _mostrarDetalles(BuildContext context, Map<String, dynamic> ingreso) async {
    final estado = _getEstado(ingreso);
    final clienteName = _getCliente(ingreso);
    final equipoDesc = _getEquipoTexto(ingreso);
    final pathFoto = _getFotoPath(ingreso);
    final accesorios = _getAccesorios(ingreso);
    final idIngreso = _getId(ingreso);

    final fecha = ingreso['fecha_ingreso'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ingreso['fecha_ingreso']))
        : 'Sin fecha';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondo.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Detalle del ingreso', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.tealAccent.withOpacity(0.15),
                backgroundImage: (pathFoto.isNotEmpty && File(pathFoto).existsSync()) ? FileImage(File(pathFoto)) : null,
                child: pathFoto.isEmpty || !File(pathFoto).existsSync() ? const Icon(Icons.devices, color: Colors.tealAccent, size: 40) : null,
              ),
              const SizedBox(height: 10),
              Text(clienteName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(equipoDesc, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Chip(
                label: Text(_textoEstado(estado), style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: _colorEstado(estado),
              ),
              const Divider(color: Colors.white24, height: 24),
              _detalleCampo('Fecha', fecha),
              _detalleCampo('Motivo', ingreso['observaciones'] ?? 'Sin observaciones'),
              _detalleCampo('Accesorios', accesorios),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
          ),
          // CORREGIDO EL IF
          if (estado == 'pendiente_diagnostico' || estado == 'ingresado' || estado == 'pendiente')
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.withOpacity(0.2),
                foregroundColor: Colors.tealAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.medical_services_outlined, size: 18),
              label: const Text('Diagnosticar'),
              onPressed: () async {
                Navigator.pop(context);
                await mostrarDiagnosticoModal(context, idIngreso);
                await _cargar();
              },
            ),
        ],
      ),
    );
  }

  Widget _detalleCampo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Text('$titulo:', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 5, child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }
}

// Widget auxiliar para las métricas superiores
class _MiniCardMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _MiniCardMetrica({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}