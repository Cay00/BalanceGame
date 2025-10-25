import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'game_physics.dart';
import 'ball_widget.dart';
import 'data_panel.dart';
import 'hole_widget.dart';

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
      home: const MyHomePage(title: 'Akcelerometr'),
    );
  }
}

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

  // === SUBSCRIPTIONS I TIMERY ===
  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription; // Pobieranie danych akcelerometru
  Timer? _physicsTimer; // Timer dla pętli fizyki (60 FPS)

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

    // Pobieraj dane z akcelerometru
    _accelerometerSubscription = accelerometerEvents.listen((
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
    _physics.updatePhysics(_x, _y);
    setState(() {}); // Odśwież UI
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
      _physics.initialize(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
        bottomPadding: MediaQuery.of(context).padding.bottom, // Padding dolnej belki
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // === DZIURA - CEL ===
          HoleWidget(
            x: MediaQuery.of(context).size.width * 0.8, // 80% szerokości ekranu
            y: MediaQuery.of(context).size.height * 0.7, // 70% wysokości ekranu
            size: 50.0,
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
                    color: Colors.black.withOpacity(0.3),
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
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _calibrate,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.center_focus_strong, color: Colors.white),
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