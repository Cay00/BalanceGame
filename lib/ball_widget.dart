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
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
  }
}
