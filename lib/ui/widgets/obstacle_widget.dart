import 'package:flutter/material.dart';

/// Wizualizacja poziomej przeszkody z dziurą
class ObstacleWidget extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final double holeX;
  final double holeWidth;

  const ObstacleWidget({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.holeX,
    required this.holeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // Lewa część przeszkody (przed dziurą)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: holeX - holeWidth / 2,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    // Zewnętrzna strona prosta, zaokrąglona od strony dziury
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
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
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Prawa część przeszkody (po dziurze)
            Positioned(
              left: holeX + holeWidth / 2,
              top: 0,
              child: Container(
                width: width - (holeX + holeWidth / 2),
                height: height,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    // Zewnętrzna strona prosta, zaokrąglona od strony dziury
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
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
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

