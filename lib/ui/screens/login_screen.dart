import 'package:flutter/material.dart';
import '../../core/session/auth_service.dart';
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
  final TextEditingController correoCtrl = TextEditingController(
    text: 'admin@gontech.cl',
  );
  final TextEditingController passCtrl = TextEditingController(text: '1234');
  final AuthService _auth = AuthService();
  bool cargando = false;

  Future<void> _intentarLogin() async {
    setState(() => cargando = true);
    final ok = await _auth.login(correoCtrl.text, passCtrl.text);
    setState(() => cargando = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credenciales inválidas')));
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
                      child: Column(
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
                          cargando
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  texto: 'Ingresar',
                                  onPressed: _intentarLogin,
                                ),
                          const SizedBox(height: 12),
                          BiometricButton(onAuthenticated: _intentarLogin),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      'v3.0 • UI Renovada',
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
