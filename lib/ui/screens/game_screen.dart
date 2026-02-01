import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:balance_game/mechanics/game_physics.dart';
import 'package:balance_game/ui/widgets/ball_widget.dart';
import 'package:balance_game/ui/widgets/data_panel.dart';
import 'package:balance_game/ui/widgets/hole_widget.dart';
import 'package:balance_game/ui/widgets/obstacle_widget.dart';

/// Główna strona gry z kulką i akcelerometrem
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Zarządza wszystkimi danymi gry i fizyką kulki
class _MyHomePageState extends State<MyHomePage> {
  // DANE Z AKCELEROMETRU
  double _x = 0.0; // Wartość X akcelerometru (pochylanie w lewo/prawo)
  double _y = 0.0; // Wartość Y akcelerometru (pochylanie w górę/dół)
  double _z = 0.0; // Wartość Z akcelerometru (obrót telefonu)

  late GamePhysics _physics;

  double _holeX = 0.0;
  double _holeY = 0.0;
  double _holeRadius = 0.0;
  double _bottomPadding = 0.0;

  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription; // Pobieranie danych akcelerometru
  Timer? _physicsTimer; // Timer dla pętli fizyki (60 FPS)
  Timer? _levelGenerationTimer; // Timer do generowania nowego poziomu
  final Random _random = Random();
  bool _isGeneratingNewLevel = false;

  @override
  void initState() {
    super.initState();

    // Wyłącz wygaszanie ekranu podczas gry
    WakelockPlus.enable();

    // Inicjalizuj fizykę gry
    _physics = GamePhysics();

    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePhysics();
    });

    // dane z API
    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      setState(() {
        _x = event.x; // Pochylanie w lewo/prawo
        _y = event.y; // Pochylanie w górę/dół
        _z = event.z; // Obrót telefonu
      });
    });
  }

  /// Aktualizuje fizykę gry
  void _updatePhysics() {
    if (_isGeneratingNewLevel) {
      return;
    }

    _physics.updatePhysics(_x, _y);

    if (_holeRadius > 0) {
      final bool justEnteredHole = _physics.updateScore(_holeX, _holeY, _holeRadius);
      
      if (justEnteredHole && !_isGeneratingNewLevel) {
        _handleHoleReached();
      }
    }

    setState(() {});
  }

  void _handleHoleReached() {
    _isGeneratingNewLevel = true;

    _levelGenerationTimer?.cancel();
    _levelGenerationTimer = Timer(const Duration(seconds: 1), () {
      _generateNewLevel();
      _isGeneratingNewLevel = false;
    });
  }

  void _generateNewLevel() {
    final screenWidth = _physics.screenWidth;
    final screenHeight = _physics.screenHeight;

    _physics.generateNewLevel();

    _holeX = 40.0 + _random.nextDouble() * (screenWidth - 80.0);

    final double bottomSafeMargin = 120.0;
    _holeY = screenHeight - _bottomPadding - bottomSafeMargin - 50.0;

    // Zresetuj kulkę na górę
    _physics.resetBall();

    setState(() {});
  }

  void _resetBall() {
    _physics.resetBall();
    setState(() {});
  }

  void _calibrate() {
    _physics.calibrate(_x, _y);
    setState(() {});
  }

  @override
  void dispose() {
    WakelockPlus.disable();

    _accelerometerSubscription
        ?.cancel();
    _physicsTimer?.cancel();
    _levelGenerationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    
    if (_physics.screenWidth == 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      _bottomPadding = bottomPadding;

      _physics.initialize(
        screenWidth,
        screenHeight,
        bottomPadding: bottomPadding,
      );

      _holeRadius = 25.0;

      _holeX = 40.0 + _random.nextDouble() * (screenWidth - 80.0);

      final double bottomSafeMargin = 120.0;
      _holeY = screenHeight - bottomPadding - bottomSafeMargin - 50.0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // Przycisk Reset - resetuje pozycję kulki
          IconButton(
            onPressed: _resetBall,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset pozycji kulki',
          ),
          // Przycisk Kalibracja - kalibruje akcelerometr
          IconButton(
            onPressed: _calibrate,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Kalibracja akcelerometru',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WYNIK
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Punkty: ${_physics.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          for (final obstacle in _physics.obstacles)
            ObstacleWidget(
              x: obstacle.x,
              y: obstacle.y,
              width: obstacle.width,
              height: obstacle.height,
              holeX: obstacle.holeX,
              holeWidth: obstacle.holeWidth,
            ),

          HoleWidget(
            x: _holeX,
            y: _holeY,
            size: _holeRadius * 2,
            isActive: true,
          ),

          BallWidget(
            x: _physics.ballX,
            y: _physics.ballY,
          ),

          // PANEL DANYCH
          DataPanel(
            x: _x,
            y: _y,
            z: _z,
            ballX: _physics.ballX,
            velocityX: _physics.velocityX,
            offsetX: _physics.offsetX,
            offsetY: _physics.offsetY,
          ),
        ],
      ),
    );
  }
}


