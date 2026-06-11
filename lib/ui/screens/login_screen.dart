import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../components/custom_text_field.dart';
import '../components/custom_button.dart';
import '../components/biometric_button.dart';
import '../theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Ajustados para que coincidan con el DatabaseSeeder de Laravel
  final TextEditingController correoCtrl = TextEditingController(
    text: 'admin@gontechsolutions.cl', 
  );
  final TextEditingController passCtrl = TextEditingController(text: '12345678');

  Future<void> _intentarLogin() async {
    final auth = context.read<AuthProvider>();
    
    try {
      // Intentamos el login. Si Laravel tira error (ej. 401 o 422), saltará al catch
      final ok = await auth.login(correoCtrl.text, passCtrl.text);
      if (!mounted) return;
      
      if (ok) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Este fallback queda por si falla en modo local (SQLite)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Aquí atrapamos el error limpio que escupe Laravel y lo mostramos en el SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating, // Le da un mejor look visual
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  Text('Bienvenido a', style: AppTextStyles.etiqueta),
                  Text('Gontech Flow', style: AppTextStyles.titulo),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Column(
                            children: [
                              CustomTextField(
                                controller: correoCtrl,
                                etiqueta: 'Correo',
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: passCtrl,
                                etiqueta: 'Contraseña',
                                esContrasena: true,
                              ),
                              const SizedBox(height: 24),
                              auth.loading
                                  ? const CircularProgressIndicator()
                                  : CustomButton(
                                      texto: 'Ingresar',
                                      onPressed: _intentarLogin,
                                    ),
                              const SizedBox(height: 12),
                              BiometricButton(
                                onAuthenticated: _intentarLogin,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      'v3.0 - UI Renovada',
                      style: AppTextStyles.etiqueta,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}