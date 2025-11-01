// ---------- lib/main.dart ----------
import 'package:flutter/material.dart';

// 🧩 Tema principal
import 'ui/theme/app_theme.dart';

// 🧠 Pantallas base
import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/ajustes_screen.dart';
import 'ui/screens/ver_bd_screen.dart';

// 📦 Módulos (importar todos los screens)
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

// 🧰 Base de datos
import 'core/database/db_loader.dart';
import 'core/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==============================
  // 🧠 Inicialización de la BD
  // ==============================
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  try {
    // 📊 Verificar si existen datos en clientes
    final conteo = await db.rawQuery('SELECT COUNT(*) as total FROM clientes');
    final total = (conteo.first['total'] as int?) ?? 0;

    if (total == 0) {
      debugPrint('⚙️ Base vacía, iniciando carga de datos demo...');
      await DbLoader().cargarDatosDemo();
      debugPrint('✅ Carga de datos demo completada con éxito (main.dart)');
    } else {
      debugPrint(
        '📂 Base ya contiene datos ($total registros), no se recargará.',
      );
    }
  } catch (e, st) {
    debugPrint('❌ Error al verificar o cargar datos demo: $e');
    debugPrint(st.toString());
  }

  // 🚀 Iniciar app tras asegurar base y datos cargados
  runApp(const GontechApp());
}

class GontechApp extends StatelessWidget {
  const GontechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gontech Flow v3',
      theme: buildAppTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),

        // 🧭 Módulos principales
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

        // ⚙️ Ajustes y herramientas
        '/ajustes': (_) => const AjustesScreen(),
        '/ver_bd': (_) => const VerBDScreen(),
      },
    );
  }
}
