import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const titulo = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.texto,
  );

  static const cuerpo = TextStyle(fontSize: 16, color: AppColors.texto);

  static const etiqueta = TextStyle(fontSize: 13, color: AppColors.texto_suave);

  static TextStyle? get tituloCard => null;
}
