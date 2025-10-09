import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricButton extends StatefulWidget {
  final Future<void> Function() onAuthenticated;
  const BiometricButton({super.key, required this.onAuthenticated});

  @override
  State<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<BiometricButton> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _soportaBiometria = false;

  @override
  void initState() {
    super.initState();
    _verificarSoporte();
  }

  Future<void> _verificarSoporte() async {
    try {
      final soporta = await _auth.canCheckBiometrics;
      final disponible = await _auth.isDeviceSupported();
      setState(() => _soportaBiometria = soporta && disponible);
    } catch (_) {
      setState(() => _soportaBiometria = false);
    }
  }

  Future<void> _autenticar() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Autenticarse con biometría',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (ok) await widget.onAuthenticated();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_soportaBiometria) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _autenticar,
      icon: const Icon(Icons.fingerprint_rounded),
      label: const Text('Ingresar con biometría'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
