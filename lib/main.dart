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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        '/repuestos': (_) => const RepuestosScreen(),
        '/informes': (_) => const InformesScreen(),
        '/entregas': (_) => const EntregasScreen(),

        // ⚙️ Ajustes (por ahora vuelve al home)
        '/ajustes': (_) => const AjustesScreen(),
        '/ver_bd': (_) => const VerBDScreen(), // ✅ aquí el viewer
      },
    );
  }
}
