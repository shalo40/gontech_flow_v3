import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/session/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SessionManager _session = SessionManager();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DatabaseHelper().database;

    final logged = await _session.esta_autenticado();

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, logged ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Samsung style: centered logo
            Image.asset(
              'assets/images/logo.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
