import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  static const bg = Color(0xFF07070E);
  static const surface = Color(0xFF11121F);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF38BDF8);
  static const pink = Color(0xFFF472B6);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const amber = Color(0xFFFBBF24);
  static const textPrimary = Color(0xFFF4F4F8);
  static const textMuted = Color(0xFF9CA0B8);
  static const neonGradient = LinearGradient(colors: [purple, pink], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

class NeonTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: NeonColors.bg,
      colorScheme: const ColorScheme.dark(primary: NeonColors.purple, secondary: NeonColors.pink, surface: NeonColors.surface, error: NeonColors.red),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(bodyColor: NeonColors.textPrimary, displayColor: NeonColors.textPrimary),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      cardTheme: CardTheme(color: NeonColors.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: NeonColors.pink.withOpacity(.15)))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: NeonColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NeonColors.purple.withOpacity(.25))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NeonColors.purple.withOpacity(.25))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NeonColors.pink, width: 1.6)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: NeonColors.surface, selectedItemColor: NeonColors.pink, unselectedItemColor: NeonColors.textMuted, type: BottomNavigationBarType.fixed),
      snackBarTheme: const SnackBarThemeData(backgroundColor: NeonColors.surface, contentTextStyle: TextStyle(color: NeonColors.textPrimary), behavior: SnackBarBehavior.floating),
    );
  }
}
