import 'package:flutter/material.dart';

/// Widget kulki
///
/// Wyświetla obiekt w określonej pozycji
class BallWidget extends StatelessWidget {
  final double x;
  final double y;
  final double size;

  const BallWidget({
    super.key,
    required this.x,
    required this.y,
    this.size = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - size / 2, // Pozycja kulki - połowa szerokości
      top: y - size / 2, // Pozycja kulki - połowa wysokości
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.3), // Pozycja źródła światła
            radius: 0.8,
            colors: [
              Color(0xFFE8E8E8), // Jasny metaliczny
              Color(0xFFB8B8B8), // Średni metaliczny
              Color(0xFF888888), // Ciemny metaliczny
              Color(0xFF555555), // Najciemniejszy
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
          boxShadow: [
            // Główny cień
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
            // Dodatkowy cień dla głębi
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            // Subtelny refleks
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
      ),
    );
  }
}


