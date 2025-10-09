import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final bool esContrasena;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.esContrasena = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: esContrasena,
      decoration: InputDecoration(
        labelText: etiqueta,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
