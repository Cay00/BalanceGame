import 'dart:math';

/// Przeszkoda pozioma z dziurą, przez którą kulka może przejść
class Obstacle {
  final double x; // lewy górny róg przeszkody
  final double y;
  final double width; // szerokość przeszkody (cała szerokość ekranu)
  final double height; // wysokość przeszkody (grubość)
  final double holeX; // pozycja X środka dziury
  final double holeWidth; // szerokość dziury

  const Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.holeX,
    required this.holeWidth,
  });
}

/// Fizyka gry - zarządza ruchem kulki i kolizjami
///
/// Zawiera:
/// - Pozycję i prędkość kulki
/// - Parametry fizyki (grawitacja, tarcie)
/// - Kalibrację akcelerometru
/// - Logikę kolizji ze ścianami i przeszkodami
class GamePhysics {
  // === FIZYKA KULKI ===
  double ballX = 0.0; // Pozycja kulki w osi X (piksele)
  double ballY = 0.0; // Pozycja kulki w osi Y (piksele)
  double velocityX = 0.0; // Prędkość kulki w osi X (piksele/klatka)
  double velocityY = 0.0; // Prędkość kulki w osi Y (piksele/klatka)

  // === PUNKTY ===
  int score = 0; // Aktualny wynik gracza
  bool _isInsideHole = false; // Czy kulka jest aktualnie w dziurze

  // === PARAMETRY FIZYKI ===
  double gravity = 0.1; // Siła grawitacji
  double friction = 0.95; // Tarcie (0.95 = 5% utraty prędkości na klatkę)
  double forceMultiplier = 0.5; // Mnożnik siły z akcelerometru

  // === KALIBRACJA AKCELEROMETRU ===
  double offsetX = 0.0; // Offset X - wartość gdy telefon leży płasko
  double offsetY = 0.0; // Offset Y - wartość gdy telefon leży płasko

  // === WYMIARY EKRANU ===
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  double _bottomPadding = 0.0;

  // === PRZESZKODY ===
  final List<Obstacle> obstacles = [];
  final Random _random = Random();

  /// Inicjalizuje fizykę z wymiarami ekranu
  void initialize(double width, double height, {double bottomPadding = 0}) {
    screenWidth = width;
    screenHeight = height;
    // Ustaw kulkę na środku szerokości i przy górnej krawędzi ekranu
    ballX = width / 2;
    ballY = 30.0; // trochę poniżej ściany, żeby nie była w niej „wtopiona”
    // Zapisz padding dolny dla kolizji
    _bottomPadding = bottomPadding;

    // Wygeneruj przeszkody
    _generateObstacles();
  }

  /// Resetuje pozycję kulki na górę ekranu i zatrzymuje ją
  void resetBall() {
    ballX = screenWidth / 2;
    ballY = 30.0;
    velocityX = 0.0;
    velocityY = 0.0;
  }

  /// Generuje nowy poziom - nowe przeszkody
  void generateNewLevel() {
    _generateObstacles();
  }

  /// Kalibruje akcelerometr - zapisuje aktualne wartości jako "poziom 0"
  void calibrate(double x, double y) {
    offsetX = x;
    offsetY = y;
    velocityX = 0.0;
    velocityY = 0.0;
  }

  /// Aktualizuje fizykę kulki na podstawie danych z akcelerometru
  ///
  /// Wykonuje:
  /// 1. Dodanie siły z akcelerometru do prędkości
  /// 2. Dodanie grawitacji
  /// 3. Zastosowanie tarcia
  /// 4. Aktualizację pozycji kulki
  /// 5. Detekcję kolizji ze ścianami i odbicia
  void updatePhysics(double accelX, double accelY) {
    // === DODAJ SIŁĘ Z AKCELEROMETRU ===
    // Używa offsetów z kalibracji - różnica od "poziomu 0"
    velocityX += -(accelX - offsetX) * forceMultiplier; // X akcelerometru → ruch w lewo/prawo
    velocityY += (accelY - offsetY) * forceMultiplier; // Y akcelerometru → ruch w górę/dół

    // === GRAWITACJA ===
    // Działa tylko gdy telefon jest znacząco pochylony w obu osiach względem skalibrowanej pozycji
    if ((accelX - offsetX).abs() > 0.1 || (accelY - offsetY).abs() > 0.1) {
      // Próg 0.1 dla znaczącego pochylenia
      velocityY += gravity;
    }

    // === TARCIE ===
    // Spowalnia kulkę (0.95 = 5% utraty prędkości na klatkę)
    velocityX *= friction;
    velocityY *= friction;

    // === AKTUALIZACJA POZYCJI ===
    ballX += velocityX;
    ballY += velocityY;

    // === KOLIZJE ZE ŚCIANAMI ===
    _handleCollisions();

    // === KOLIZJE Z PRZESZKODAMI ===
    _handleObstacleCollisions();
  }

  /// Aktualizuje wynik gry na podstawie pozycji dziury
  ///
  /// Wywołuj po `updatePhysics`, przekazując współrzędne środka dziury i jej promień.
  /// Zwraca true, jeśli kulka właśnie dotknęła dziury (moment wejścia).
  /// Kulka musi być głębiej w dziurze (60% promienia) aby zaliczyć punkt.
  /// Gdy kulka jest w dziurze, zatrzymuje się.
  bool updateScore(double holeX, double holeY, double holeRadius) {
    // Odległość pomiędzy środkiem kulki a środkiem dziury
    final dx = ballX - holeX;
    final dy = ballY - holeY;
    final distanceSquared = dx * dx + dy * dy;
    
    // Użyj mniejszego promienia (60% promienia dziury) - kulka musi być głębiej
    final double detectionRadius = holeRadius * 0.6;
    final double detectionRadiusSquared = detectionRadius * detectionRadius;

    final isNowInside = distanceSquared <= detectionRadiusSquared;

    // Jeśli kulka jest w dziurze, zatrzymaj ją
    if (isNowInside) {
      // Ustaw kulkę dokładnie w środku dziury
      ballX = holeX;
      ballY = holeY;
      // Zatrzymaj prędkość
      velocityX = 0.0;
      velocityY = 0.0;
    }

    // Zlicz punkt tylko w momencie wejścia do dziury (zbocze narastające)
    final bool justEntered = isNowInside && !_isInsideHole;
    if (justEntered) {
      score += 1;
    }

    _isInsideHole = isNowInside;
    return justEntered;
  }

  /// Obsługuje kolizje kulki ze ścianami ekranu
  void _handleCollisions() {
    // Lewa ściana
    if (ballX < 15) {
      ballX = 15;
      velocityX = -velocityX * 0.8; // Odbicie z utratą 20% energii
    }
    // Prawa ściana
    if (ballX > screenWidth - 15) {
      ballX = screenWidth - 15;
      velocityX = -velocityX * 0.8;
    }
    // Górna ściana
    if (ballY < 15) {
      ballY = 15;
      velocityY = -velocityY * 0.8;
    }
    // Dolna ściana (zostaw miejsce na AppBar i dolną belkę nawigacyjną)
    final bottomBoundary = screenHeight - 100 - _bottomPadding;
    if (ballY > bottomBoundary) {
      ballY = bottomBoundary;
      velocityY = -velocityY * 0.8;
    }
  }

  /// Generuje 8 poziomych przeszkód z dziurami, z gęstszym (mniejszym) odstępem pionowym
  void _generateObstacles() {
    obstacles.clear();

    if (screenWidth == 0 || screenHeight == 0) {
      return;
    }

    const int obstacleCount = 8;
    const double obstacleHeight = 16.0; // Grubość przeszkody
    const double holeWidth = 80.0; // Szerokość dziury
    final double availableHeight = screenHeight - 100 - _bottomPadding - 60; // Miejsce na górę i dół
    // Spacing jest automatycznie ~2x mniejszy po zwiększeniu obstacleCount do 8
    final double spacing = availableHeight / (obstacleCount + 1); // Równe odstępy

    for (int i = 0; i < obstacleCount; i++) {
      // Podnieś (przesuń w górę) poziom generowania przeszkód o 50 px
      final double y = 60 + spacing * (i + 1) - 50.0; // Pozycja Y przeszkody
      
      // Losowe położenie dziury w przeszkodzie (z marginesami)
      final double minHoleX = holeWidth / 2 + 20; // Minimalna pozycja (lewy margines)
      final double maxHoleX = screenWidth - holeWidth / 2 - 20; // Maksymalna pozycja (prawy margines)
      final double holeX = minHoleX + _random.nextDouble() * (maxHoleX - minHoleX);

      obstacles.add(Obstacle(
        x: 0,
        y: y,
        width: screenWidth,
        height: obstacleHeight,
        holeX: holeX,
        holeWidth: holeWidth,
      ));
    }
  }

  /// Obsługuje kolizje kulki z przeszkodami (uwzględnia dziury)
  void _handleObstacleCollisions() {
    const double ballRadius = 15.0;

    for (final obstacle in obstacles) {
      final double obstacleTop = obstacle.y;
      final double obstacleBottom = obstacle.y + obstacle.height;
      final double holeLeft = obstacle.holeX - obstacle.holeWidth / 2;
      final double holeRight = obstacle.holeX + obstacle.holeWidth / 2;

      // Sprawdź, czy kulka jest na wysokości przeszkody
      final bool isAtObstacleHeight = ballY >= obstacleTop - ballRadius && 
                                      ballY <= obstacleBottom + ballRadius;

      if (isAtObstacleHeight) {
        // Sprawdź, czy kulka jest poza dziurą
        final bool isOutsideHole = ballX < holeLeft || ballX > holeRight;

        if (isOutsideHole) {
          // Odbij kulkę od przeszkody
          if (ballY < obstacleTop + obstacle.height / 2) {
            // Odbicie od góry przeszkody
            ballY = obstacleTop - ballRadius;
            velocityY = -velocityY * 0.8;
          } else {
            // Odbicie od dołu przeszkody
            ballY = obstacleBottom + ballRadius;
            velocityY = -velocityY * 0.8;
          }
        }
      }
    }
  }
}


