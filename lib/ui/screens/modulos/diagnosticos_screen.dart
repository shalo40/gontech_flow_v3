import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../layout/layout_principal.dart';
import '../../theme/app_colors.dart';
import 'presupuesto_modal.dart';
import 'diagnostico_detalle_screen.dart'; // <-- IMPORTANTE: Añadida la importación
import 'package:intl/intl.dart';

class DiagnosticosScreen extends StatefulWidget {
  const DiagnosticosScreen({super.key});

  @override
  State<DiagnosticosScreen> createState() => _DiagnosticosScreenState();
}

class _DiagnosticosScreenState extends State<DiagnosticosScreen> {
  String filtroEstado = 'todos';
  String query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    await context.read<HelpdeskProvider>().recargarDiagnosticos();
  }

  // --- Helpers de Extracción Segura para el Árbol de Laravel ---
  String _getMarca(Map<String, dynamic> d) {
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      return d['ingreso']['equipo']['marca'] ?? 'Equipo';
    }
    return d['marca'] ?? 'Equipo';
  }

  String _getTipo(Map<String, dynamic> d) {
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      return d['ingreso']['equipo']['tipo_equipo'] ?? 'Dispositivo';
    }
    return d['tipo_equipo'] ?? 'Dispositivo';
  }

  String _getModelo(Map<String, dynamic> d) {
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null) {
      return d['ingreso']['equipo']['modelo'] ?? '';
    }
    return d['modelo'] ?? '';
  }

  String _getClienteNombre(Map<String, dynamic> d) {
    if (d['ingreso'] != null && d['ingreso']['equipo'] != null && d['ingreso']['equipo']['cliente'] != null) {
      return d['ingreso']['equipo']['cliente']['nombre'] ?? 'Sin Cliente';
    }
    return 'Sin Cliente';
  }

  int _getId(Map<String, dynamic> d) {
    return int.tryParse((d['id_diagnostico'] ?? d['id'] ?? '0').toString()) ?? 0;
  }

  // --- Badge Visual de Complejidad / Riesgo ---
  Widget _badgeComplejidad(String? complejidad) {
    final comp = (complejidad ?? 'medio').toLowerCase();
    Color color;
    switch (comp) {
      case 'bajo': color = Colors.greenAccent; break;
      case 'medio': color = Colors.tealAccent; break;
      case 'alto': color = Colors.orangeAccent; break;
      case 'critico': color = Colors.redAccent; break;
      default: color = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        'RIESGO ${comp.toUpperCase()}',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelpdeskProvider>();
    final diagnosticos = provider.diagnosticos;
    final isLoading = provider.loading;

    // Contadores en tiempo real para las métricas superiores
    int paraCotizar = 0;
    int criticos = 0;

    final filtrados = diagnosticos.where((d) {
      final estado = (d['estado'] ?? 'diagnosticado').toString().toLowerCase();
      final complejidad = (d['complejidad'] ?? 'medio').toString().toLowerCase();
      
      // Cálculo de métricas sobre la marcha
      if (estado == 'diagnosticado') paraCotizar++;
      if (complejidad == 'alto' || complejidad == 'critico') criticos++;

      final marca = _getMarca(d).toLowerCase();
      final tipo = _getTipo(d).toLowerCase();
      final cliente = _getClienteNombre(d).toLowerCase();
      final falla = (d['descripcion_falla'] ?? '').toString().toLowerCase();

      final textoCompleto = '$marca $tipo $cliente $falla';

      // Lógica de los chips de filtro
      bool coincideEstado = true;
      if (filtroEstado == 'para_cotizar') coincideEstado = estado == 'diagnosticado';
      if (filtroEstado == 'criticos') coincideEstado = complejidad == 'alto' || complejidad == 'critico';

      final coincideTexto = textoCompleto.contains(query.toLowerCase());

      return coincideEstado && coincideTexto;
    }).toList();

    return LayoutPrincipal(
      titulo: 'Panel de Diagnósticos',
      child: Column(
        children: [
          // 📊 1. METRICAS DE CONTROL SUPERIOR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CardMetricaLaboratorio(
                    titulo: 'Para Cotizar',
                    valor: paraCotizar.toString(),
                    color: Colors.amberAccent,
                    icono: Icons.calculate_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardMetricaLaboratorio(
                    titulo: 'Casos Críticos',
                    valor: criticos.toString(),
                    color: Colors.redAccent,
                    icono: Icons.gavel_rounded,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 2. BUSCADOR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por equipo, cliente o falla...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent, size: 20),
                filled: true,
                fillColor: AppColors.fondo.withOpacity(0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => query = val),
            ),
          ),

          // 🎚️ 3. CHIPS DE FILTRADO AVANZADO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChipFiltro('todos', 'Todos los informes'),
                  _buildChipFiltro('para_cotizar', 'Pendientes de Cotización'),
                  _buildChipFiltro('criticos', '⚠️ Alta Prioridad / Riesgo'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 📋 4. LISTADO ESTILO TICKET TÉCNICO
          Expanded(
            child: isLoading && diagnosticos.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : filtrados.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text('No hay reportes técnicos que coincidan.', style: TextStyle(color: Colors.white54))),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        color: Colors.tealAccent,
                        backgroundColor: AppColors.fondo,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final d = filtrados[index];
                            final idDiagnostico = _getId(d);
                            final marca = _getMarca(d);
                            final tipo = _getTipo(d);
                            final modelo = _getModelo(d);
                            final cliente = _getClienteNombre(d);
                            final estado = (d['estado'] ?? 'diagnosticado').toString().toLowerCase();

                            final fechaRaw = d['created_at'] ?? d['creado_en'];
                            final fechaFormateada = fechaRaw != null
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaRaw.toString()))
                                : 'Reciente';

                            final horasEst = d['tiempo_estimado_hrs']?.toString() ?? '1.0';

                            return Card(
                              color: AppColors.fondo.withOpacity(0.85),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: InkWell( // <--- NAVEGACIÓN AGREGADA AQUÍ
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DiagnosticoDetalleScreen(diagnostico: d),
                                    ),
                                  ).then((_) => _cargar()); // Recarga al volver
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Fila de Encabezado: Info de Equipo y Semáforo
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                                            child: const Icon(Icons.biotech, color: Colors.tealAccent, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('$tipo $marca $modelo'.trim(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                                const SizedBox(height: 2),
                                                Text('Cliente: $cliente', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          _badgeComplejidad(d['complejidad']),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Bloque Central: Hallazgos de Laboratorio estructurados
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.search_rounded, color: Colors.orangeAccent, size: 16),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'DIAGNOSTICO: ${d['descripcion_falla'] ?? 'Sin descripción'}',
                                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.gavel_rounded, color: Colors.greenAccent, size: 16),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'DICTAMEN: ${d['conclusiones'] ?? 'Sin conclusiones'}',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Fila de Pie de Tarjeta: Métricas comerciales y Acciones
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule, color: Colors.white38, size: 14),
                                              const SizedBox(width: 4),
                                              Text('$horasEst hrs est.', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.calendar_today, color: Colors.white38, size: 14),
                                              const SizedBox(width: 4),
                                              Text(fechaFormateada, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                            ],
                                          ),
                                          // 🚀 ACCIONES COMERCIALES INTELIGENTES DIRECTAS
                                          if (estado == 'diagnosticado')
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await mostrarPresupuestoModal(context, idDiagnostico);
                                                _cargar();
                                              },
                                              icon: const Icon(Icons.monetization_on, size: 16),
                                              label: const Text('Cotizar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.tealAccent,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                minimumSize: const Size(0, 32),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                              child: const Text('COTIZADO', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
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

  Widget _buildChipFiltro(String valor, String texto) {
    final activo = filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(texto),
        labelStyle: TextStyle(color: activo ? Colors.black : Colors.white70, fontSize: 13, fontWeight: activo ? FontWeight.bold : FontWeight.normal),
        selected: activo,
        selectedColor: Colors.tealAccent,
        backgroundColor: AppColors.fondo.withOpacity(0.4),
        side: BorderSide(color: activo ? Colors.tealAccent : Colors.white12),
        onSelected: (_) => setState(() => filtroEstado = valor),
      ),
    );
  }
}

// Card Auxiliar para el control de métricas de laboratorio
class _CardMetricaLaboratorio extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _CardMetricaLaboratorio({
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}