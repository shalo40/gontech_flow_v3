import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primario,
      secondary: AppColors.acento,
      surface: AppColors.fondo,
      onSurface: AppColors.texto,
    ),
    scaffoldBackgroundColor: AppColors.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
