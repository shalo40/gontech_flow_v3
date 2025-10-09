import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _cargando = false;
  String _mensaje = 'Presiona el botón para cargar datos demo';
  double _progreso = 0.0;

  Future<void> _cargarDatosDemo() async {
    setState(() {
      _cargando = true;
      _mensaje = 'Iniciando carga de datos...';
      _progreso = 0.1;
    });

    final loader = DbLoader();

    try {
      // Simulación de carga secuencial visual
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _mensaje = 'Cargando clientes...';
        _progreso = 0.2;
      });

      await loader.cargarDatosDemo();
      setState(() {
        _mensaje = 'Verificando integridad de la base de datos...';
        _progreso = 0.8;
      });

      await Future.delayed(const Duration(seconds: 1));
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
          _cargando = false;
          _progreso = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutPrincipal(
      titulo: 'Ajustes del sistema',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Text('Configuraciones generales', style: AppTextStyles.titulo),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.palette, color: Colors.blueAccent),
              title: const Text('Tema y colores'),
              subtitle: const Text('Cambiar esquema visual del sistema'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aún no implementado')),
                );
              },
            ),
            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.orangeAccent,
              ),
              title: const Text('Notificaciones'),
              subtitle: const Text('Preferencias de alertas internas'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aún no implementado')),
                );
              },
            ),
            const Divider(),

            const SizedBox(height: 40),
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
                  _cargando
                      ? 'Cargando datos de ejemplo en la base local...'
                      : 'Rellena automáticamente las tablas del sistema',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: _cargando ? null : _confirmarCarga,
                trailing: _cargando
                    ? const CircularProgressIndicator(color: Colors.tealAccent)
                    : const Icon(Icons.play_arrow, color: Colors.white70),
              ),
            ),

            if (_cargando) ...[
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
          ],
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
