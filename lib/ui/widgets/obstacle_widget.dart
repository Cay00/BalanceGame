import 'package:flutter/material.dart';

/// Wizualizacja prostokątnej przeszkody
class ObstacleWidget extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final double angle; // radiany

  const ObstacleWidget({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.center,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF707070),
                Color(0xFF3A3A3A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


