import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';
import 'presupuesto_modal.dart';

class DiagnosticoDetalleScreen extends StatelessWidget {
  final Map<String, dynamic> diagnostico;

  const DiagnosticoDetalleScreen({super.key, required this.diagnostico});

  // --- Helpers de Extracción Laravel ---
  String _getNested(Map<String, dynamic> d, List<String> path, [String fallback = '']) {
    dynamic current = d;
    for (final key in path) {
      if (current == null || current[key] == null) return fallback;
      current = current[key];
    }
    return current.toString().isNotEmpty ? current.toString() : fallback;
  }

  int _getId() => int.tryParse((diagnostico['id_diagnostico'] ?? diagnostico['id'] ?? '0').toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final d = diagnostico;
    final idDiag = _getId();
    final estado = (d['estado'] ?? 'diagnosticado').toString().toLowerCase();
    
    // Extracción de datos del equipo
    final tipo = _getNested(d, ['ingreso', 'equipo', 'tipo_equipo'], 'Equipo');
    final marca = _getNested(d, ['ingreso', 'equipo', 'marca'], '');
    final modelo = _getNested(d, ['ingreso', 'equipo', 'modelo'], '');
    final cliente = _getNested(d, ['ingreso', 'equipo', 'cliente', 'nombre'], 'Sin cliente');

    // Fechas
    final rawFecha = d['creado_en'] ?? d['created_at'] ?? '';
    final fechaStr = rawFecha.isNotEmpty ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(rawFecha)) : 'Fecha desconocida';

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Informe de Laboratorio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Eliminar informe',
            onPressed: () => _confirmarEliminacion(context, idDiag),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ CABECERA: EQUIPO Y ESTADO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.tealAccent.withOpacity(0.15), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.biotech, color: Colors.tealAccent, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Folio #$idDiag', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('$tipo $marca $modelo', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Propietario: $cliente', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 🔬 SECCIÓN 1: HALLAZGOS (Falla y Causas)
            _SeccionTitulo(titulo: '1. Hallazgos Técnicos', icono: Icons.bug_report),
            _TarjetaInfo(
              hijos: [
                _DatoFila(label: 'Falla verificada:', valor: d['descripcion_falla'] ?? 'No especificada', colorValor: Colors.orangeAccent),
                const Divider(color: Colors.white12, height: 24),
                _DatoFila(label: 'Causa raíz (Origen):', valor: d['posibles_causas'] ?? 'No determinadas', colorValor: Colors.white),
              ],
            ),
            const SizedBox(height: 20),

            // 🧪 SECCIÓN 2: BANCO DE PRUEBAS
            _SeccionTitulo(titulo: '2. Banco de Pruebas', icono: Icons.checklist_rtl),
            _TarjetaInfo(
              hijos: _construirListaPruebas(d['pruebas_realizadas']?.toString() ?? ''),
            ),
            const SizedBox(height: 20),

            // ⚖️ SECCIÓN 3: DICTAMEN Y PROYECCIÓN COMERCIAL
            _SeccionTitulo(titulo: '3. Resolución y Esfuerzo', icono: Icons.gavel_rounded),
            _TarjetaInfo(
              hijos: [
                _DatoFila(label: 'Conclusión:', valor: d['conclusiones'] ?? 'Sin dictamen', colorValor: Colors.greenAccent),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniBadge(label: 'Mano de Obra', valor: '${d['tiempo_estimado_hrs'] ?? 1.0} hrs', icono: Icons.schedule),
                    _MiniBadge(label: 'Riesgo', valor: (d['complejidad'] ?? 'Medio').toString().toUpperCase(), icono: Icons.equalizer, esRiesgo: true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // 🚀 BOTÓN FLOTANTE COMERCIAL
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: estado == 'diagnosticado' 
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.monetization_on, size: 22),
                label: const Text('Generar Presupuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                onPressed: () async {
                  await mostrarPresupuestoModal(context, idDiag);
                  if (context.mounted) {
                    await context.read<HelpdeskProvider>().recargarDiagnosticos();
                    Navigator.pop(context); // Vuelve a la lista tras presupuestar
                  }
                },
              ),
            ),
          )
        : null, // Si ya está cotizado, no mostramos el botón
    );
  }

  // --- Widgets Auxiliares Modulares ---

  List<Widget> _construirListaPruebas(String pruebasRaw) {
    if (pruebasRaw.isEmpty || pruebasRaw == 'Inspección visual estándar') {
      return [const Text('Solo se realizó inspección visual básica.', style: TextStyle(color: Colors.white54, fontSize: 13))];
    }

    // Separamos por el delimitador " | " que pusimos en el modal
    final lista = pruebasRaw.split(' | ');
    return lista.map((p) {
      final esExito = p.contains('[PASÓ]');
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(esExito ? Icons.check_circle : Icons.cancel, color: esExito ? Colors.green : Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(p.replaceAll('[PASÓ]', '').replaceAll('[FALLÓ]', '').trim(), style: const TextStyle(color: Colors.white70, fontSize: 13))),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _confirmarEliminacion(BuildContext context, int idDiag) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fondo,
        title: const Text('¿Eliminar informe?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      // Aquí asumo que agregarás 'eliminarDiagnostico' a tu HelpdeskProvider pronto. 
      // Por ahora simulamos el pop.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función de eliminación en construcción...')));
    }
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icono, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text(titulo.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final List<Widget> hijos;
  const _TarjetaInfo({required this.hijos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: hijos),
    );
  }
}

class _DatoFila extends StatelessWidget {
  final String label;
  final String valor;
  final Color colorValor;
  const _DatoFila({required this.label, required this.valor, required this.colorValor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valor, style: TextStyle(color: colorValor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final bool esRiesgo;

  const _MiniBadge({required this.label, required this.valor, required this.icono, this.esRiesgo = false});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.tealAccent;
    if (esRiesgo) {
      if (valor == 'ALTO' || valor == 'CRITICO') color = Colors.redAccent;
      else if (valor == 'MEDIO') color = Colors.orangeAccent;
      else color = Colors.greenAccent;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icono, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text(valor, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}