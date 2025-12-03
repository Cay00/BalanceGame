import 'package:flutter/material.dart';
import 'package:balance_game/ui/screens/start_screen.dart';

/// Aplikacja Balance Game - gra z kulką sterowaną akcelerometrem
///
/// Gra polega na sterowaniu kulką poprzez pochylanie telefonu.
/// Kulka reaguje na dane z akcelerometru i porusza się z fizyką
/// (prędkość, tarcie, grawitacja, odbicia od ścian).
void main() {
  runApp(const MyApp());
}

/// Główny widget aplikacji
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balance Game - Akcelerometr',
      debugShowCheckedModeBanner: false, // Ukrywa "DEBUG" banner w rogu
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF888888), // Szary metaliczny
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF141414), // Ciemne tło
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A2A), // Ciemny metaliczny
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF555555), // Metaliczny szary
          foregroundColor: Colors.white,
        ),
      ),
      home: const StartScreen(),
    );
  }
}
