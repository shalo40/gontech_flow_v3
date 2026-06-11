import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ui/theme/app_theme.dart';

import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/ajustes_screen.dart';
import 'ui/screens/ver_bd_screen.dart';
import 'ui/screens/estadisticas_screen.dart';

import 'ui/screens/modulos/clientes_screen.dart';
import 'ui/screens/modulos/equipos_screen.dart';
import 'ui/screens/modulos/ingresos_screen.dart';
import 'ui/screens/modulos/diagnosticos_screen.dart';
import 'ui/screens/modulos/presupuestos_screen.dart';
import 'ui/screens/modulos/reparaciones_screen.dart';
import 'ui/screens/modulos/repuestos_screen.dart';
import 'ui/screens/modulos/informes_screen.dart';
import 'ui/screens/modulos/entregas_screen.dart';
import 'ui/screens/modulos/reparacion_detalle_screen.dart';

import 'core/database/db_loader.dart';
import 'core/database/database_helper.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/helpdesk_provider.dart';
import 'core/config/api_config.dart'; // <-- IMPORTANTE: Agregamos la configuración de la API

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);

  // --- 1. CONFIGURACIÓN FORZADA PARA DESARROLLO (Backend Laravel) ---
  await ApiConfig.setUseApiMode(true);
  await ApiConfig.setBaseUrl('http://10.0.2.2:8000/api');
  // ------------------------------------------------------------------

  // --- 2. VERIFICACIÓN DE MODO ---
  final bool useApi = await ApiConfig.useApiMode();

  if (!useApi) {
    // Si NO estamos usando la API, cargamos la base de datos local y los mockups
    debugPrint('📱 Iniciando en MODO LOCAL (SQLite)');
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    try {
      final conteo = await db.rawQuery('SELECT COUNT(*) as total FROM clientes');
      final total = (conteo.first['total'] as int?) ?? 0;

      if (total == 0) {
        debugPrint('Base vacía, iniciando carga de datos demo...');
        await DbLoader().cargarDatosDemo();
        debugPrint('Carga de datos demo completada con éxito');
      }
    } catch (e, st) {
      debugPrint('Error al verificar o cargar datos demo: $e');
      debugPrint(st.toString());
    }
  } else {
    // Si ESTAMOS usando la API, saltamos la carga local
    debugPrint('🚀 Iniciando en MODO API (Backend Laravel) - Omitiendo SQLite demo...');
  }

  runApp(const GontechApp());
}

class GontechApp extends StatelessWidget {
  const GontechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HelpdeskProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gontech Flow v3',
        theme: buildAppTheme(),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/clientes': (_) => const ClientesScreen(),
          '/equipos': (_) => const EquiposScreen(),
          '/ingresos': (_) => const IngresosScreen(),
          '/diagnosticos': (_) => const DiagnosticosScreen(),
          '/presupuestos': (_) => const PresupuestosScreen(),
          '/reparaciones': (_) => const ReparacionesScreen(),
          '/reparacion_detalle': (context) {
            final reparacion =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return ReparacionDetalleScreen(reparacion: reparacion);
          },
          '/repuestos': (_) => const RepuestosScreen(),
          '/informes': (_) => const InformesScreen(),
          '/entregas': (_) => const EntregasScreen(),
          '/estadisticas': (_) => const EstadisticasScreen(),
          '/ajustes': (_) => const AjustesScreen(),
          '/ver_bd': (_) => const VerBDScreen(),
        },
      ),
    );
  }
}