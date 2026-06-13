import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../../theme/app_colors.dart';

class BitacoraTecnicaScreen extends StatefulWidget {
  final int idReparacion;
  final String notasActuales;

  const BitacoraTecnicaScreen({super.key, required this.idReparacion, required this.notasActuales});

  @override
  State<BitacoraTecnicaScreen> createState() => _BitacoraTecnicaScreenState();
}

class _BitacoraTecnicaScreenState extends State<BitacoraTecnicaScreen> {
  late TextEditingController _notasCtrl;
  bool _procesando = false;

  final List<Map<String, dynamic>> _accionesRapidas = [
    {'label': 'Limpieza Isopropílica', 'icon': Icons.cleaning_services},
    {'label': 'Cambio Pasta Térmica', 'icon': Icons.thermostat},
    {'label': 'Soldadura Componentes', 'icon': Icons.hardware},
    {'label': 'Reinstalación Sistema', 'icon': Icons.system_update},
    {'label': 'Reemplazo Display', 'icon': Icons.screenshot},
    {'label': 'Limpieza Pin de Carga', 'icon': Icons.usb},
    {'label': 'Armado y Sellado', 'icon': Icons.check_box},
  ];

  @override
  void initState() {
    super.initState();
    final textoInicial = widget.notasActuales == 'Aún no se ha registrado trabajo.' || widget.notasActuales == '-' ? '' : '${widget.notasActuales}\n';
    _notasCtrl = TextEditingController(text: textoInicial);
  }

  void _agregarNota(String accion) {
    setState(() {
      final actual = _notasCtrl.text;
      _notasCtrl.text = actual.isEmpty ? '✓ $accion\n' : '$actual✓ $accion\n';
    });
  }

  Future<void> _guardarYFinalizar() async {
    setState(() => _procesando = true);
    try {
      final provider = context.read<HelpdeskProvider>();
      // Guardamos la bitácora y cerramos la reparación en un solo movimiento
      final exito = await provider.actualizarReparacion(widget.idReparacion, {
        'notas': _notasCtrl.text.trim(),
        'estado': 'finalizada'
      });

      if (exito && mounted) {
        Navigator.pop(context, true); // Regresa a la pantalla anterior informando éxito
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Equipo reparado. Bitácora guardada.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: Colors.black26,
        elevation: 0,
        title: const Text('Mesa de Trabajo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Acciones Rápidas (Toca para autocompletar):', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // ⚡ BOTONERA CERO ESCRITURA
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _accionesRapidas.map((accion) {
                    return ActionChip(
                      elevation: 2,
                      backgroundColor: Colors.amberAccent.withOpacity(0.1),
                      side: BorderSide(color: Colors.amberAccent.withOpacity(0.5)),
                      avatar: Icon(accion['icon'], size: 16, color: Colors.amberAccent),
                      label: Text(accion['label'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () => _agregarNota(accion['label']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
                const Text('Bitácora del Equipo:', style: TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                // 📝 TEXTAREA
                Expanded(
                  child: TextField(
                    controller: _notasCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Usa los botones de arriba para no escribir...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black45,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 🚀 BOTÓN DE CIERRE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.verified, color: Colors.black),
                    label: const Text('Guardar y Finalizar Trabajo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: _guardarYFinalizar,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_procesando)
            Container(color: Colors.black.withOpacity(0.6), child: const Center(child: CircularProgressIndicator(color: Colors.tealAccent))),
        ],
      ),
    );
  }
}