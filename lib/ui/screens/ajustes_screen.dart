import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/helpdesk_provider.dart';
import '../layout/layout_principal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../core/database/db_loader.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _cargandoDemo = false;
  String _mensaje = 'Presiona el botón para cargar datos demo';
  double _progreso = 0.0;

  // Controladores para los ajustes
  final _empresaCtrl = TextEditingController();
  final _ivaCtrl = TextEditingController();
  final _monedaCtrl = TextEditingController();
  bool _modoOscuro = true;
  bool _notificaciones = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarConProvider();
    });
  }

  void _sincronizarConProvider() {
    final config = context.read<HelpdeskProvider>().configuracion;
    setState(() {
      _empresaCtrl.text = config['empresa_nombre']?.toString() ?? 'Gontech Solutions';
      _ivaCtrl.text = config['impuesto_iva']?.toString() ?? '19';
      _monedaCtrl.text = config['moneda_default']?.toString() ?? 'CLP';
      
      // Manejo seguro de booleanos que puedan venir como strings desde la BD
      _modoOscuro = (config['modo_oscuro'] == true || config['modo_oscuro'] == 'true' || config['modo_oscuro'] == '1');
      _notificaciones = (config['notificaciones_activas'] == true || config['notificaciones_activas'] == 'true' || config['notificaciones_activas'] == '1');
    });
  }

  Future<void> _guardarAjustes() async {
    final provider = context.read<HelpdeskProvider>();
    
    // Empaquetamos la carga útil para el endpoint /ajustes/bulk
    final listaAjustes = [
      {'clave': 'empresa_nombre', 'valor': _empresaCtrl.text.trim(), 'tipo': 'string'},
      {'clave': 'impuesto_iva', 'valor': _ivaCtrl.text.trim(), 'tipo': 'number'},
      {'clave': 'moneda_default', 'valor': _monedaCtrl.text.trim(), 'tipo': 'string'},
      {'clave': 'modo_oscuro', 'valor': _modoOscuro, 'tipo': 'boolean'},
      {'clave': 'notificaciones_activas', 'valor': _notificaciones, 'tipo': 'boolean'},
    ];

    try {
      final exito = await provider.guardarAjustesGlobales(listaAjustes);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ajustes del sistema guardados correctamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar ajustes: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cargarDatosDemo() async {
    setState(() {
      _cargandoDemo = true;
      _mensaje = 'Iniciando carga de datos...';
      _progreso = 0.1;
    });

    final loader = DbLoader();

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _mensaje = 'Cargando datos relacionales...';
        _progreso = 0.4;
      });

      await loader.cargarDatosDemo();
      
      setState(() {
        _mensaje = 'Sincronizando el estado global...';
        _progreso = 0.8;
      });

      if (mounted) {
        await context.read<HelpdeskProvider>().recargarTodo();
      }

      setState(() {
        _mensaje = '✅ Carga completada correctamente';
        _progreso = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos de demostración cargados con éxito 🚀'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _mensaje = '❌ Error durante la carga: $e';
        _progreso = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _cargandoDemo = false;
          _progreso = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<HelpdeskProvider>().loading;

    return LayoutPrincipal(
      titulo: 'Ajustes del sistema',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _guardarAjustes,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
            : const Icon(Icons.save),
        label: const Text('Guardar cambios'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // --- BLOQUE 1: Empresa ---
            const SizedBox(height: 10),
            Text('Datos de la Empresa', style: AppTextStyles.titulo),
            const SizedBox(height: 20),
            
            _campoAjuste(
              controller: _empresaCtrl, 
              label: 'Nombre comercial', 
              icono: Icons.business,
            ),
            Row(
              children: [
                Expanded(
                  child: _campoAjuste(
                    controller: _ivaCtrl, 
                    label: 'Impuesto (IVA %)', 
                    icono: Icons.receipt_long,
                    tipo: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campoAjuste(
                    controller: _monedaCtrl, 
                    label: 'Moneda (Ej: CLP)', 
                    icono: Icons.monetization_on,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 40),

            // --- BLOQUE 2: UI / UX ---
            Text('Preferencias de la Aplicación', style: AppTextStyles.titulo),
            const SizedBox(height: 10),

            SwitchListTile(
              activeColor: Colors.tealAccent,
              secondary: const Icon(Icons.dark_mode, color: Colors.blueAccent),
              title: const Text('Modo Oscuro', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Esquema visual del sistema', style: TextStyle(color: Colors.white70)),
              value: _modoOscuro,
              onChanged: (val) => setState(() => _modoOscuro = val),
            ),
            SwitchListTile(
              activeColor: Colors.tealAccent,
              secondary: const Icon(Icons.notifications_active, color: Colors.orangeAccent),
              title: const Text('Notificaciones', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Alertas internas y avisos de sistema', style: TextStyle(color: Colors.white70)),
              value: _notificaciones,
              onChanged: (val) => setState(() => _notificaciones = val),
            ),
            const Divider(color: Colors.white24, height: 40),

            // --- BLOQUE 3: Debug ---
            Text(
              'Depuración y diagnóstico',
              style: AppTextStyles.titulo.copyWith(color: Colors.tealAccent),
            ),
            const SizedBox(height: 10),

            // ⚡️ Botón de carga demo
            Card(
              color: AppColors.fondo.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.cloud_download,
                  color: Colors.tealAccent,
                ),
                title: const Text(
                  'Cargar datos de demostración',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _cargandoDemo
                      ? 'Cargando datos de ejemplo en la base local...'
                      : 'Rellena automáticamente las tablas del sistema',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: _cargandoDemo ? null : _confirmarCarga,
                trailing: _cargandoDemo
                    ? const CircularProgressIndicator(color: Colors.tealAccent)
                    : const Icon(Icons.play_arrow, color: Colors.white70),
              ),
            ),

            if (_cargandoDemo) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progreso,
                color: Colors.tealAccent,
                backgroundColor: Colors.white12,
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _mensaje,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 30),

            if (kDebugMode)
              Card(
                color: AppColors.fondo.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.developer_board,
                    color: Colors.tealAccent,
                  ),
                  title: const Text(
                    'Ver base de datos (modo debug)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Visualiza las tablas SQLite locales',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/ver_bd'),
                ),
              ),
              
            const SizedBox(height: 60), // Espacio para que el FAB no tape el contenido
          ],
        ),
      ),
    );
  }

  Widget _campoAjuste({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icono, color: Colors.tealAccent),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: AppColors.fondo.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
        ),
      ),
    );
  }

  void _confirmarCarga() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmar carga de datos demo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esto agregará datos de ejemplo a la base local.\n\n¿Deseas continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cargarDatosDemo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
            ),
            child: const Text('Cargar ahora'),
          ),
        ],
      ),
    );
  }
}