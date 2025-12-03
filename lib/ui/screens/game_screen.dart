import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

/// Stan głównej strony gry
///
/// Zarządza wszystkimi danymi gry i fizyką kulki
class _MyHomePageState extends State<MyHomePage> {
  // === DANE Z AKCELEROMETRU ===
  double _x = 0.0; // Wartość X akcelerometru (pochylanie w lewo/prawo)
  double _y = 0.0; // Wartość Y akcelerometru (pochylanie w górę/dół)
  double _z = 0.0; // Wartość Z akcelerometru (obrót telefonu)

  // === FIZYKA GRY ===
  late GamePhysics _physics;

  // === DZIURA (CEL) ===
  double _holeX = 0.0;
  double _holeY = 0.0;
  double _holeRadius = 0.0;
  double _bottomPadding = 0.0;

  // === SUBSCRIPTIONS I TIMERY ===
  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription; // Pobieranie danych akcelerometru
  Timer? _physicsTimer; // Timer dla pętli fizyki (60 FPS)
  Timer? _levelGenerationTimer; // Timer do generowania nowego poziomu
  final Random _random = Random();
  bool _isGeneratingNewLevel = false; // Flaga, czy trwa generowanie nowego poziomu

  /// Inicjalizacja komponentu
  ///
  /// Uruchamia:
  /// - Pętlę fizyki (60 FPS = co 16ms)
  /// - Pobieranie danych z akcelerometru
  @override
  void initState() {
    super.initState();

    // Inicjalizuj fizykę gry
    _physics = GamePhysics();

    // Uruchom pętlę fizyki (60 FPS = co 16ms)
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePhysics();
    });

    // Pobieraj dane z akcelerometru (nowe API sensors_plus)
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
      return; // Nie aktualizuj fizyki podczas generowania nowego poziomu
    }

    _physics.updatePhysics(_x, _y);

    // Aktualizuj wynik tylko jeśli znamy pozycję dziury
    if (_holeRadius > 0) {
      final bool justEnteredHole = _physics.updateScore(_holeX, _holeY, _holeRadius);
      
      // Jeśli kulka właśnie dotknęła dziury
      if (justEnteredHole && !_isGeneratingNewLevel) {
        debugPrint('Kulka dotknęła dziury! Uruchamiam wibrację...');
        _handleHoleReached();
      }
    }

    setState(() {}); // Odśwież UI
  }

  /// Obsługuje dotknięcie dziury - wibracja i generowanie nowego poziomu
  void _handleHoleReached() {
    _isGeneratingNewLevel = true;

    // Uruchom wibrację na 0.5 sekundy
    _vibrateForDuration(const Duration(milliseconds: 500));

    // Po 1 sekundzie wygeneruj nowy poziom
    _levelGenerationTimer?.cancel();
    _levelGenerationTimer = Timer(const Duration(seconds: 1), () {
      _generateNewLevel();
      _isGeneratingNewLevel = false;
    });
  }

  /// Wibruje przez określony czas (wywołuje HapticFeedback wielokrotnie)
  void _vibrateForDuration(Duration duration) {
    debugPrint('Rozpoczynam wibrację na ${duration.inMilliseconds}ms');
    
    // Użyj heavyImpact dla mocniejszej wibracji (natychmiast)
    HapticFeedback.heavyImpact();
    
    // Kontynuuj wibrację przez określony czas używając różnych typów wibracji
    const int intervalMs = 80; // Wibracja co 80ms dla płynniejszego efektu
    final int iterations = (duration.inMilliseconds / intervalMs).ceil();
    
    debugPrint('Wibracja: $iterations iteracji co $intervalMs ms');
    
    for (int i = 1; i < iterations; i++) {
      Timer(Duration(milliseconds: i * intervalMs), () {
        // Przemiennie używaj heavyImpact i mediumImpact dla różnorodności
        if (i % 2 == 0) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      });
    }
  }

  /// Generuje nowy poziom - nowe przeszkody i nową pozycję dziury
  void _generateNewLevel() {
    final screenWidth = _physics.screenWidth;
    final screenHeight = _physics.screenHeight;

    // Wygeneruj nowe przeszkody
    _physics.generateNewLevel();

    // Wylosuj nową pozycję X dziury
    _holeX = 40.0 + _random.nextDouble() * (screenWidth - 80.0);

    // Pozycja Y dziury pozostaje taka sama (na dole)
    final double bottomSafeMargin = 120.0;
    _holeY = screenHeight - _bottomPadding - bottomSafeMargin - 50.0;

    // Zresetuj kulkę na górę
    _physics.resetBall();

    setState(() {});
  }

  /// Resetuje pozycję kulki na środek ekranu i zatrzymuje ją
  void _resetBall() {
    _physics.resetBall();
    setState(() {});
  }

  /// Kalibruje akcelerometr - zapisuje aktualne wartości jako "poziom 0"
  void _calibrate() {
    _physics.calibrate(_x, _y);
    setState(() {});
  }

  /// Czyszczenie zasobów przy zamykaniu komponentu
  @override
  void dispose() {
    _accelerometerSubscription
        ?.cancel(); // Zatrzymaj pobieranie danych akcelerometru
    _physicsTimer?.cancel(); // Zatrzymaj pętlę fizyki
    _levelGenerationTimer?.cancel(); // Zatrzymaj timer generowania poziomu
    super.dispose();
  }

  /// Buduje interfejs użytkownika gry
  ///
  /// Zawiera:
  /// - Kulka
  /// - Przycisk Reset
  /// - Przycisk Kalibracja
  /// - Panel danych z akcelerometru
  @override
  Widget build(BuildContext context) {
    // Inicjalizuj fizykę z wymiarami ekranu (tylko raz)
    if (_physics.screenWidth == 0) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      _bottomPadding = bottomPadding; // Zapisz padding dla późniejszego użycia

      _physics.initialize(
        screenWidth,
        screenHeight,
        bottomPadding: bottomPadding, // Padding dolnej belki
      );

      // Ustal promień dziury
      _holeRadius = 25.0; // Połowa size = 50.0

      // Wylosuj pozycję X dziury (od lewej do prawej, z marginesami)
      _holeX = 40.0 + _random.nextDouble() * (screenWidth - 80.0); // marginesy

      // Ustaw dziurę przy dolnej krawędzi ekranu (nad przyciskami i paddingiem),
      // ale podnieś ją dodatkowo o 50 px w górę
      final double bottomSafeMargin = 120.0; // miejsce na przyciski i panel
      _holeY = screenHeight - bottomPadding - bottomSafeMargin - 50.0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // === WYNIK ===
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

          // === PRZESZKODY ===
          for (final obstacle in _physics.obstacles)
            ObstacleWidget(
              x: obstacle.x,
              y: obstacle.y,
              width: obstacle.width,
              height: obstacle.height,
              holeX: obstacle.holeX,
              holeWidth: obstacle.holeWidth,
            ),

          // === DZIURA - CEL ===
          HoleWidget(
            x: _holeX,
            y: _holeY,
            size: _holeRadius * 2,
            isActive: true,
          ),

          // === KULKA Z FIZYKĄ ===
          BallWidget(
            x: _physics.ballX,
            y: _physics.ballY,
          ),

          // === PRZYCISK RESET ===
          // Metaliczny przycisk w lewym dolnym rogu - resetuje pozycję kulki
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFB8B8B8), // Jasny metaliczny
                    Color(0xFF888888), // Średni metaliczny
                    Color(0xFF555555), // Ciemny metaliczny
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _resetBall,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
            ),
          ),

          // === PRZYCISK KALIBRACJA ===
          // Metaliczny przycisk w prawym dolnym rogu - kalibruje akcelerometr
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFB8B8B8), // Jasny metaliczny
                    Color(0xFF888888), // Średni metaliczny
                    Color(0xFF555555), // Ciemny metaliczny
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _calibrate,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child:
                    const Icon(Icons.center_focus_strong, color: Colors.white),
              ),
            ),
          ),

          // === PANEL DANYCH ===
          // Wyświetla dane z akcelerometru i stan kulki
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


