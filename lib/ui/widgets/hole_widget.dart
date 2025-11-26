import 'package:flutter/material.dart';

/// Widget dziury - cel do którego gracz musi skierować kulkę
///
/// Wyświetla okrągłą dziurę z gradientem i cieniem
/// która wygląda jak prawdziwa dziura w powierzchni
class HoleWidget extends StatelessWidget {
  final double x;
  final double y;
  final double size;
  final bool isActive; // Czy dziura jest aktywna (można do niej trafić)

  const HoleWidget({
    super.key,
    required this.x,
    required this.y,
    this.size = 40.0,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - size / 2, // Pozycja dziury - połowa szerokości
      top: y - size / 2, // Pozycja dziury - połowa wysokości
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: isActive
                ? [
                    const Color(0xFF2A2A2A), // Ciemny brzeg
                    const Color(0xFF1A1A1A), // Średni
                    const Color(0xFF0F0F0F), // Ciemny środek
                    const Color(0xFF000000), // Najciemniejszy (dno dziury)
                  ]
                : [
                    const Color(0xFF404040), // Szary brzeg (nieaktywna)
                    const Color(0xFF303030), // Średni szary
                    const Color(0xFF202020), // Ciemny szary
                    const Color(0xFF101010), // Najciemniejszy szary
                  ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
          boxShadow: [
            // Główny cień dziury
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // Dodatkowy cień dla głębi
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            // Subtelny refleks na brzegu
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: isActive
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}


