import 'package:flutter/material.dart';

/// Panel wyświetlający dane z akcelerometru
///
/// Pokazuje w prawym górnym rogu:
/// - Wartości X, Y, Z z akcelerometru
/// - Pozycję i prędkość kulki
/// - Offsety kalibracji
class DataPanel extends StatelessWidget {
  final double x;
  final double y;
  final double z;
  final double ballX;
  final double velocityX;
  final double offsetX;
  final double offsetY;

  const DataPanel({
    super.key,
    required this.x,
    required this.y,
    required this.z,
    required this.ballX,
    required this.velocityX,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Dane z akcelerometru
          Text(
            'X: ${x.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          Text(
            'Y: ${y.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          Text(
            'Z: ${z.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),

          // Stan kulki
          Text(
            'BallX: ${ballX.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          Text(
            'VelX: ${velocityX.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 14, color: Colors.green),
          ),

          // Offsety kalibracji
          Text(
            'OffsetX: ${offsetX.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
          Text(
            'OffsetY: ${offsetY.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}


